package main

import (
	"bufio"
	"crypto/tls"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"

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
	proxies  map[string]*proxy
}

var configs = make(map[string]*config)
var proxyHost = os.Getenv("PROXY_HOST")
var proxyPort = os.Getenv("PROXY_PORT")
var useAutocert = os.Getenv("AUTOCERT")
var dockerEnv = os.Getenv("DOCKER_ENV")
var dockerUser = os.Getenv("DOCKER_USER")
var authPath = os.Getenv("AUTH_PATH")
var passThroughProxy *httputil.ReverseProxy
var reverseProxy *httputil.ReverseProxy
var reverseProxyInsecure *httputil.ReverseProxy

func init() {
	passThroughProxy = &httputil.ReverseProxy{
		Director:       passThroughDirector,
		ModifyResponse: modifyResponse,
	}
	reverseProxy = &httputil.ReverseProxy{
		Director:       reverseDirector,
		ModifyResponse: modifyResponse,
	}
	transportInsecure := http.DefaultTransport.(*http.Transport)
	configInsecure := &tls.Config{InsecureSkipVerify: true}
	transportInsecure.TLSClientConfig = configInsecure
	reverseProxyInsecure = &httputil.ReverseProxy{
		Director:       reverseDirector,
		ModifyResponse: modifyResponse,
		Transport:      transportInsecure,
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
		// Redirect http to https
		log.Printf("%s %s http->https %s", r.RemoteAddr, r.Method, r.URL.String())
		url := r.URL
		url.Host = proxyHost + ":" + proxyPort
		url.Scheme = "https"
		http.Redirect(w, r, url.String(), http.StatusMovedPermanently)
	}))

	if strings.HasPrefix(proxyHost, "localhost") || dockerEnv == "DEVELOPMENT" || useAutocert != "true" {
		crt := "/certificates/" + proxyHost + ".crt"
		key := "/certificates/" + proxyHost + ".key"
		log.Fatal(http.ListenAndServeTLS(":443", crt, key, http.HandlerFunc(handler)))
	} else {
		m := &autocert.Manager{
			Cache:      autocert.DirCache("/config/autocert"),
			Prompt:     autocert.AcceptTOS,
			HostPolicy: autocert.HostWhitelist(proxyHost),
		}
		s := &http.Server{
			Addr:      ":https",
			TLSConfig: m.TLSConfig(),
			Handler:   http.HandlerFunc(handler),
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
					if (key == "/geoserver/" || key == "/mapserver/" || key == "/mapproxy/" || key == "/mapfish/") && r.FormValue("secret") != config.secret {
						log.Printf("StatusUnauthorized, FormValue=%s", r.FormValue("secret"))
						http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
					} else {
						if proxy.authorise {
							if req, err := http.NewRequest("GET", authPath+"?method="+r.Method+"&path="+path, http.NoBody); err != nil {
								http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
								return
							} else {
								req.Header = r.Header
								if res, e := http.DefaultClient.Do(req); e != nil {
									http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
									return
								} else if res.StatusCode/100 != 2 {
									http.Error(w, http.StatusText(res.StatusCode), res.StatusCode)
									return
								}
							}
						}
						target := proxy.target
						r.URL.Scheme = target.Scheme
						r.URL.Host = target.Host
						r.URL.Path = target.Path + strings.SplitN(path, "/", 3)[2] // alles na de tweede slash
						if proxy.impersonate {
							r.Host = proxyHost
							if target.Port() != "" {
								r.Host += ":" + target.Port()
							}
						} else {
							r.Host = target.Host
						}
						if proxy.insecure {
							reverseProxyInsecure.ServeHTTP(w, r)
						} else {
							reverseProxy.ServeHTTP(w, r)
						}
					}
					return
				}
			}
		}
	}
	log.Printf("%s %s Not Found %v %v", r.RemoteAddr, r.Method, r.Host, r.URL)
	http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
}

func reverseDirector(r *http.Request) {
	log.Printf("%s %s Reverse %v %v", r.RemoteAddr, r.Method, r.Host, r.URL)
	if _, ok := r.Header["User-Agent"]; !ok {
		// explicitly disable User-Agent so it's not set to default value
		r.Header.Set("User-Agent", "")
	}
}

func passThroughDirector(r *http.Request) {
	target, _ := url.Parse(r.FormValue("url"))
	query := r.URL.Query()
	query.Del("url")
	target.RawQuery = query.Encode()
	r.URL = target
	r.Host = target.Host
	log.Printf("%s %s Passthrough %v", r.RemoteAddr, r.Method, r.URL)
}

func modifyResponse(r *http.Response) error {
	r.Header.Set("Access-Control-Allow-Origin", "*")
	// Deze twee hieronder zouden eigenlijk niet nodig moeten zijn, maar het blijkt er wel beter van te worden..
	r.Header.Set("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS")
	r.Header.Set("Access-Control-Allow-Headers", "SOAPAction, X-Requested-With, Origin, Content-Type, Authorization, Accept, access_token")
	return nil
}
