package main

import (
	"bufio"
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"net/http/cookiejar"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"

	"github.com/gorilla/handlers"
	"golang.org/x/net/publicsuffix"

	"golang.org/x/crypto/acme/autocert"
)

type proxy struct {
	target      *url.URL
	impersonate bool
	insecure    bool
	authorise   bool
}

type config struct {
	secret   string
	homedest string
	authPath string
	proxies  map[string]*proxy
}

var (
	configs           = make(map[string]*config)
	proxyHost         = os.Getenv("PROXY_HOST")
	proxyPort         = os.Getenv("PROXY_PORT")
	useAutocert       = os.Getenv("AUTOCERT")
	dockerEnv         = os.Getenv("DOCKER_ENV")
	dockerUser        = os.Getenv("DOCKER_USER")
	passThroughProxy  *httputil.ReverseProxy
	jar               *cookiejar.Jar
	transportInsecure *http.Transport
)

func init() {
	transportInsecure = http.DefaultTransport.(*http.Transport)
	configInsecure := &tls.Config{InsecureSkipVerify: true}
	transportInsecure.TLSClientConfig = configInsecure
	if j, err := cookiejar.New(&cookiejar.Options{PublicSuffixList: publicsuffix.List}); err != nil {
		log.Fatal(err)
	} else {
		jar = j
	}
	passThroughProxy = &httputil.ReverseProxy{
		ModifyResponse: modifyResponse,
		Director: func(r *http.Request) {
			target, _ := url.Parse(r.FormValue("url"))
			query := r.URL.Query()
			query.Del("url")
			target.RawQuery = query.Encode()
			r.URL = target
			r.Host = target.Host
			filterCookies(r)
			log.Printf("%s %s Passthrough %v", r.RemoteAddr, r.Method, r.URL)
		},
	}
}

func main() {
	fileInfos, err := ioutil.ReadDir("/config")
	if err != nil {
		log.Fatal(err)
	}

	for _, fileInfo := range fileInfos {
		if fileInfo.Mode().IsDir() {
			continue
		}
		app := fileInfo.Name()
		file, err := os.Open("/config/" + app)
		if err != nil {
			log.Fatal(err)
		}
		defer file.Close()

		configs[app] = &config{
			proxies: make(map[string]*proxy),
		}
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			split := strings.SplitN(scanner.Text(), "=", 2)
			if len(split) == 2 {
				key, value := split[0], split[1]
				if key == "secret" {
					configs[app].secret = value
					log.Printf("%s.secret=%s", app, value)
				} else if key == "homedest" {
					configs[app].homedest = value
					log.Printf("%s.homedest=%s", app, value)
				} else if key == "authPath" {
					configs[app].authPath = value
					log.Printf("%s.authPath=%s", app, value)
				} else {
					defineProxy(app, key, value)
				}
			}
		}

		if err := scanner.Err(); err != nil {
			log.Fatal(err)
		}
	}

	go http.ListenAndServe(":80", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if dockerEnv == "DEVELOPMENT" {
			handler(w, r)
		} else {
			// Redirect http to https
			log.Printf("%s %s http->https %s", r.RemoteAddr, r.Method, r.URL.String())
			url := r.URL
			host := strings.Split(r.Host, ":")[0]
			url.Host = host + ":" + proxyPort
			url.Scheme = "https"
			http.Redirect(w, r, url.String(), http.StatusMovedPermanently)
		}
	}))

	go http.ListenAndServe(":8080", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}))

	if strings.HasPrefix(proxyHost, "localhost") || dockerEnv == "DEVELOPMENT" || useAutocert != "true" {
		crt := "/certificates/" + proxyHost + ".crt"
		key := "/certificates/" + proxyHost + ".key"
		log.Fatal(http.ListenAndServeTLS(":443", crt, key, handlers.CompressHandler(http.HandlerFunc(handler))))
	} else {
		m := &autocert.Manager{
			Cache:      autocert.DirCache("/config/autocert"),
			Prompt:     autocert.AcceptTOS,
			HostPolicy: autocert.HostWhitelist(proxyHost),
		}
		s := &http.Server{
			Addr:      ":https",
			TLSConfig: m.TLSConfig(),
			Handler:   handlers.CompressHandler(http.HandlerFunc(handler)),
		}
		log.Fatal(s.ListenAndServeTLS("", ""))
	}

}

func handler(w http.ResponseWriter, r *http.Request) {
	log.Printf("%s %s %s", r.RemoteAddr, r.Method, r.RequestURI)
	if r.Method == "OPTIONS" {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "SOAPAction, X-Requested-With, Origin, Content-Type, Authorization, Accept, access_token")
	} else if r.URL.Path == "/" && r.URL.Query().Get("url") != "" {
		if target, err := url.Parse(r.FormValue("url")); err != nil {
			log.Printf("%+v", err)
			http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadGateway)
		} else if !strings.Contains(target.Host, ".") {
			log.Printf("Not passing through to internal host")
			http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
		} else {
			passThroughProxy.ServeHTTP(w, r)
		}
	} else {
		reverse(w, r)
	}
}

func defineProxy(app, key, value string) {
	log.Printf("/%s/%s -> %s", app, key, value)
	impersonate, insecure, authorise := false, false, false
	for strings.HasPrefix(value, "impersonate,") || strings.HasPrefix(value, "insecure,") || strings.HasPrefix(value, "authorise,") {
		split := strings.SplitN(value, ",", 2)
		value = split[1]
		switch split[0] {
		case "impersonate":
			impersonate = true
		case "insecure":
			insecure = true
		case "authorise":
			authorise = true
		}
	}
	target, _ := url.Parse(value)
	if target.Path == "" {
		target.Path = "/"
	}
	key = "/" + key + "/"
	configs[app].proxies[key] = &proxy{
		target:      target,
		impersonate: impersonate,
		insecure:    insecure,
		authorise:   authorise,
	}
}

func reverse(w http.ResponseWriter, r *http.Request) {
	referer, _ := url.Parse(r.Referer())
	refererParts := strings.Split(referer.Path+"//", "/") //  + "//" to cater for empty Referer
	path := "/"
	requestParts := strings.Split(r.URL.Path, "/")
	app := requestParts[1]
	if _, ok := configs[app]; ok {
		// Normal case: path starts with app directory
		if len(requestParts) > 2 {
			path += strings.SplitN(r.URL.Path, "/", 3)[2] // alles na de tweede slash
		}
		// log.Printf("app=%s path=%s", app, path)
	} else {
		// Naughty components case: assuming they're the root; try referer
		app = refererParts[1]
		path = r.URL.Path
		log.Printf("Trying referer: app=%s path=%s", app, path)
	}
	if _, ok := configs[app]; !ok {
		// Last resort (also helping old single-proxy clients): try DOCKER_USER
		app = dockerUser
		path = r.URL.Path
		log.Printf("Trying DOCKER_USER: app=%s path=%s", app, path)
	}
	if config, ok := configs[app]; ok {
		if path == "/" || path == "//" {
			log.Printf("%s %s Redirect %v %v", r.RemoteAddr, r.Method, r.Host, r.URL)
			http.Redirect(w, r, config.homedest, http.StatusFound)
			return
		}
		paths := []string{path, "/" + refererParts[2] + path}
		for _, path := range paths {
			for key, proxy := range config.proxies {
				if path+"/" == key {
					path = path + "/"
				}
				if strings.HasPrefix(path, key) {
					reverseProxy(w, r, path, app, key, config, proxy).ServeHTTP(w, r)
					return
				}
			}
		}
	}
	log.Printf("%s %s Not Found %v %v", r.RemoteAddr, r.Method, r.Host, r.URL)
	http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
}

func reverseProxy(w http.ResponseWriter, r *http.Request, path, app, key string, config *config, proxy *proxy) *httputil.ReverseProxy {
	transport := http.DefaultTransport
	if proxy.insecure {
		transport = transportInsecure
	}
	hasApp := strings.HasPrefix(r.URL.Path, "/"+app)
	return &httputil.ReverseProxy{
		Transport: transport,
		Director: func(r *http.Request) {
			basicAuthAccessToken(r, key)
			if err := validateSecret(r, key, config.secret); err != nil {
				http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
				return
			}
			if proxy.authorise {
				if authorised, err := authorise(r, path, config.authPath); err != nil {
					log.Printf("authorise -> error: %v", err)
					http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
					return
				} else if !authorised {
					http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
					return
				}
			}
			target := proxy.target
			r.URL.Scheme = target.Scheme
			r.URL.Host = target.Host
			r.URL.Path = target.Path + strings.SplitN(path, "/", 3)[2] // alles na de tweede slash
			forwardedFor := r.Header.Get("X-Real-Ip")
			if forwardedFor == "" {
				forwardedFor = r.Header.Get("X-Forwarded-For")
			}
			if forwardedFor == "" {
				forwardedFor, _, _ = net.SplitHostPort(r.RemoteAddr)
			}
			forwardedHost := r.Host
			forwardedProto := "https"
			forwardedPath := "/" + app + key
			forwarded := "for=" + forwardedFor + ";host=" + forwardedHost + ";proto=" + forwardedProto + ";path=" + forwardedPath
			r.Header.Set("Forwarded", forwarded)
			r.Header.Set("X-Forwarded-For", forwardedFor)
			r.Header.Set("X-Forwarded-Host", forwardedHost)
			r.Header.Set("X-Forwarded-Proto", forwardedProto)
			r.Header.Set("X-Forwarded-Path", forwardedPath)
			r.Header.Set("X-Script-Name", forwardedPath)
			if proxy.impersonate {
				r.Host = proxyHost
				if target.Port() != "" {
					r.Host += ":" + target.Port()
				}
			} else {
				r.Host = target.Host
			}
			if _, ok := r.Header["User-Agent"]; !ok {
				// explicitly disable User-Agent so it's not set to default value
				r.Header.Set("User-Agent", "")
			}
			filterCookies(r)
			log.Printf("%s %s Reverse %v %v", r.RemoteAddr, r.Method, r.Host, r.URL)
		},
		ModifyResponse: func(r *http.Response) error {
			if err := modifyResponse(r); err != nil {
				return err
			}
			// collect the response's cookies, with  Domain and Path rewritten
			// for the proxy client's perspective
			var cookies []*http.Cookie
			for _, cookie := range r.Cookies() {
				cookie.Domain = ""
				if (key == "/app/" || key == "/api/") && (cookie.Path == "" || cookie.Path == "/") {
					cookie.Path = "/"
				} else {
					cookie.Path = strings.TrimSuffix(key, "/") + cookie.Path
				}
				if hasApp {
					cookie.Path = "/" + app + cookie.Path
				}
				cookies = append(cookies, cookie)
			}
			// replace all cookies with the rewritten ones
			r.Header.Del("Set-Cookie")
			for _, cookie := range cookies {
				r.Header.Add("Set-Cookie", cookie.String())
			}
			return nil
		},
	}
}

func filterCookies(r *http.Request) {
	// Prevent forwarding other destinations' cookies:
	clone := r.Clone(r.Context())
	r.Header.Del("Cookie")
	for _, jarred := range jar.Cookies(r.URL) {
		// repopulate with just those cookies from the request that were
		// previously jarred for this URL
		if cloned, err := clone.Cookie(jarred.Name); err == nil {
			r.AddCookie(cloned)
		}
	}
}

func modifyResponse(r *http.Response) error {
	// save this destination's cookies in the jar
	jar.SetCookies(r.Request.URL, r.Cookies())
	// CORS
	r.Header.Set("Access-Control-Allow-Origin", "*")
	// Deze twee hieronder zouden eigenlijk niet nodig moeten zijn, maar het
	// blijkt er wel beter van te worden..
	r.Header.Set("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS")
	r.Header.Set("Access-Control-Allow-Headers", "SOAPAction, X-Requested-With, Origin, Content-Type, Authorization, Accept, access_token")
	return nil
}

func basicAuthAccessToken(r *http.Request, key string) {
	if username, password, ok := r.BasicAuth(); ok && username == "access_token" {
		r.Header.Del("Authorization")
		if key == "/geoserver/" {
			// for geoserver, read any "access_token" from basic auth, and pass
			// it on as a viewparam
			query := r.URL.Query()
			viewparams := query.Get("viewparams")
			if viewparams == "" {
				viewparams = query.Get("VIEWPARAMS")
			}
			if strings.Contains(viewparams, username) {
				log.Printf("access_token provided in viewparams as well as in basic auth; using the viewparams value")
			} else {
				param := username + ":" + password
				if viewparams == "" {
					viewparams = param
				} else {
					viewparams = viewparams + ";" + param
				}
				query.Set("VIEWPARAMS", viewparams)
				r.URL.RawQuery = query.Encode()
				log.Printf("Basic Auth access_token passed in VIEWPARAMS")
			}
		}
	}
}

func validateSecret(r *http.Request, key string, secret string) error {
	if (key == "/geoserver/" || key == "/mapserver/" || key == "/mapproxy/" || key == "/mapfish/") && r.FormValue("secret") != secret {
		return fmt.Errorf("invalid secret: %s", r.FormValue("secret"))
	} else {
		return nil
	}
}

func authorise(r *http.Request, path string, authPath string) (authorised bool, err error) {
	// copy of https://golang.org/pkg/net/http/httputil/?m=all#drainBody
	drainBody := func(b io.ReadCloser) (r1, r2 io.ReadCloser, err error) {
		if b == nil || b == http.NoBody {
			// No copying needed. Preserve the magic sentinel meaning of NoBody.
			return http.NoBody, http.NoBody, nil
		}
		var buf bytes.Buffer
		if _, err = buf.ReadFrom(b); err != nil {
			return nil, b, err
		}
		if err = b.Close(); err != nil {
			return nil, b, err
		}
		return ioutil.NopCloser(&buf), ioutil.NopCloser(bytes.NewReader(buf.Bytes())), nil
	}
	bodyString := func(body io.ReadCloser) (content string, err error) {
		defer body.Close()
		if bytes, err := ioutil.ReadAll(body); err != nil {
			return "", err
		} else {
			return string(bytes), nil
		}
	}
	type authPathBody struct {
		Method string
		Path   string
		Query  url.Values
		Body   string
	}
	// Have the request authorised before putting it through.
	if body, originalBody, errDrainBody := drainBody(r.Body); errDrainBody != nil {
		return false, errDrainBody
	} else if bodyContent, errBodyString := bodyString(body); errBodyString != nil {
		return false, errBodyString
	} else if jsonBody, errMarshal := json.Marshal(authPathBody{r.Method, path, r.URL.Query(), bodyContent}); errMarshal != nil {
		return false, errMarshal
	} else if req, errNewRequest := http.NewRequest("POST", authPath, bytes.NewReader(jsonBody)); errNewRequest != nil {
		return false, errNewRequest
	} else {
		req.Header = r.Header.Clone()
		req.Header.Del("accept-encoding")
		req.Header.Set("content-type", "application/json")
		req.Header.Set("accept", "application/json, application/*, text/*")
		filterCookies(req)
		if res, errDo := http.DefaultClient.Do(req); errDo != nil {
			return false, errDo
		} else if res.StatusCode == http.StatusUnauthorized {
			return false, nil
		} else if res.StatusCode/100 != 2 {
			return false, fmt.Errorf("the authPath response has status: %d", res.StatusCode)
		} else if authorization, errAuthorization := bodyString(res.Body); errAuthorization != nil {
			return false, errAuthorization
		} else {
			// authorisation succeeded; pass through what they responded with
			r.Header.Set("Authorization", strings.Trim(authorization, `"`))
			// restore the original request body
			r.Body = originalBody
			return true, nil
		}
	}
}
