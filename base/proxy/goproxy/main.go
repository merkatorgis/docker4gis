package main

import (
	"bufio"
	"io/ioutil"
	"log"
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
	configs          = make(map[string]*config)
	proxyHost        = os.Getenv("PROXY_HOST")
	proxyPort        = os.Getenv("PROXY_PORT")
	useAutocert      = os.Getenv("AUTOCERT")
	dockerEnv        = os.Getenv("DOCKER_ENV")
	dockerUser       = os.Getenv("DOCKER_USER")
	debug            = os.Getenv("DEBUG") == "true"
	passThroughProxy *httputil.ReverseProxy
	jar              *cookiejar.Jar
)

func init() {
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
	if newJar, err := cookiejar.New(&cookiejar.Options{PublicSuffixList: publicsuffix.List}); err != nil {
		log.Fatal(err)
	} else {
		jar = newJar
	}
}

func main() {
	fileInfos, err := ioutil.ReadDir("/config")
	if err != nil {
		log.Fatal(err)
	}
	// loop over config files (one per app)
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
		// parse each line into a config for this app
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

	go http.ListenAndServe(":80", handlers.CompressHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
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
	})))

	go http.ListenAndServe(":8080", handlers.CompressHandler(http.HandlerFunc(handler)))

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

func cors(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Vary", "Origin")
	w.Header().Set("Access-Control-Allow-Origin", r.Header.Get("Origin"))
	w.Header().Set("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS, HEAD")
	w.Header().Set("Access-Control-Allow-Headers", "SOAPAction, X-Requested-With, Origin, Content-Type, Authorization, Accept, access_token")
	w.Header().Set("Access-Control-Allow-Credentials", "true")
}

func handler(w http.ResponseWriter, r *http.Request) {
	log.Printf("%s %s %s", r.RemoteAddr, r.Method, r.RequestURI)
	if r.Method == "OPTIONS" || r.Method == "HEAD" {
		cors(w, r)
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
	return nil
}
