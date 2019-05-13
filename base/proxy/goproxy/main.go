package main

import (
	"crypto/tls"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
)

var host = os.Getenv("PROXY_HOST")
var api = os.Getenv("API")
var app = os.Getenv("APP")
var homedest = os.Getenv("HOMEDEST")
var resources = os.Getenv("RESOURCES")
var ngr = os.Getenv("NGR")
var geoserver = os.Getenv("GEOSERVER")
var mapfish = os.Getenv("MAPFISH")
var secret = os.Getenv("SECRET")
var passThroughProxy *httputil.ReverseProxy
var reverseProxy *httputil.ReverseProxy
var reverseProxyInsecure *httputil.ReverseProxy
var proxies = make(map[string]*url.URL)

func defineProxy(key, target string) {
	u, _ := url.Parse(target)
	if u.Path == "" {
		u.Path = "/"
	}
	key = "/" + key + "/"
	proxies[key] = u
	log.Printf("reversing: %s -> %v", key, u)
}

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
	// goproxy thfghhj=http://www.dhghdsfgh.com jlkvflk=http://www.vsoiihffvh.com
	for _, proxy := range os.Args[1:] {
		split := strings.Split(proxy, "=")
		defineProxy(split[0], split[1])
	}
	defineProxy("ngr", ngr)

	defineProxy("geoserver", geoserver)

	defineProxy("mapfish", mapfish)
	defineProxy("print", mapfish+"print/")

	defineProxy("api", api)

	defineProxy("app", app)
	defineProxy("static", app+"static/")
	defineProxy("favicon.ico", app+"favicon.ico")
	defineProxy("manifest.json", app+"manifest.json")
	defineProxy("service-worker.js", app+"service-worker.js")
	defineProxy("index.html", app+"index.html")
	defineProxy("index", app+"index")
	defineProxy("html", app+"html/")

	defineProxy("resources", resources)

	log.Printf("homedest: %s", homedest)
}

func main() {

	// Redirect http to https
	go http.ListenAndServe(":80", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		url := r.URL
		url.Host = r.Host
		url.Scheme = "https"
		http.Redirect(w, r, url.String(), http.StatusMovedPermanently)
	}))

	crt := "/certificates/" + host + ".crt"
	key := "/certificates/" + host + ".key"
	log.Fatal(http.ListenAndServeTLS(":443", crt, key, http.HandlerFunc(handler)))
}

func handler(w http.ResponseWriter, r *http.Request) {
	log.Printf("%s %s %s", r.RemoteAddr, r.Method, r.RequestURI)
	if r.Method == "OPTIONS" {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "SOAPAction, X-Requested-With, Origin, Content-Type, Authorization, Accept")
	} else if r.URL.Path == "/" {
		if r.URL.Query().Get("url") == "" && homedest != "" {
			http.Redirect(w, r, homedest, http.StatusFound)
		} else {
			passThroughProxy.ServeHTTP(w, r)
		}
	} else {
		reverse(w, r)
	}
}

func reverse(w http.ResponseWriter, r *http.Request) {
	for key, target := range proxies {
		if r.URL.Path+"/" == key {
			r.URL.Path = r.URL.Path + "/"
		}
		if strings.HasPrefix(r.URL.Path, key) {
			r.URL.Scheme = target.Scheme
			r.URL.Host = target.Host
			r.URL.Path = target.Path + strings.SplitN(r.URL.Path, "/", 3)[2] // alles na de tweede slash
			referer, _ := url.Parse(r.Referer())
			if key == "/api/" {
				r.Host = host
				if target.Port() != "" {
					r.Host += ":" + target.Port()
				}
				reverseProxyInsecure.ServeHTTP(w, r)
			} else if (r.FormValue("secret") != secret) && (key == "/print/" ||
				key == "/mapfish/" ||
				(key == "/geoserver/" && r.FormValue("service") != "" && !strings.HasPrefix(referer.Path, key))) {
				http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
			} else {
				r.Host = target.Host
				if strings.Contains(target.Hostname(), ".") {
					reverseProxy.ServeHTTP(w, r)
				} else {
					reverseProxyInsecure.ServeHTTP(w, r)
				}
			}
			return
		}
	}
	http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
}

func reverseDirector(r *http.Request) {
	log.Printf("%s %s reverse %v", r.RemoteAddr, r.Method, r.URL)
	if _, ok := r.Header["User-Agent"]; !ok {
		// explicitly disable User-Agent so it's not set to default value
		r.Header.Set("User-Agent", "")
	}
}

func passThroughDirector(r *http.Request) {
	if target, err := url.Parse(r.FormValue("url")); err != nil {
		log.Printf("%+v", err)
	} else {
		query := r.URL.Query()
		query.Del("url")
		target.RawQuery = query.Encode()
		r.URL = target
		r.Host = target.Host
		log.Printf("%s %s passthrough %v", r.RemoteAddr, r.Method, r.URL)
	}
}

func modifyResponse(r *http.Response) error {
	r.Header.Set("Access-Control-Allow-Origin", "*")
	// Deze twee hieronder zouden eigenlijk niet nodig moeten zijn, maar het blijkt er wel beter van te worden..
	r.Header.Set("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS")
	r.Header.Set("Access-Control-Allow-Headers", "SOAPAction, X-Requested-With, Origin, Content-Type, Authorization, Accept")
	return nil
}
