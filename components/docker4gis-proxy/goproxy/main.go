package main

import (
	"bufio"
	"crypto/tls"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/gorilla/handlers"

	"golang.org/x/crypto/acme/autocert"
)

type proxy struct {
	target      *url.URL
	impersonate bool
	insecure    bool
	authorise   bool
	cache       bool
}

type config struct {
	homedest  string
	authPath  string
	cachePath string
	proxies   map[string]*proxy
}

var (
	configs                         = make(map[string]*config)
	proxyHost                       = os.Getenv("PROXY_HOST")
	proxyPort                       = os.Getenv("PROXY_PORT")
	useAutocert                     = os.Getenv("AUTOCERT")
	dockerEnv                       = os.Getenv("DOCKER_ENV")
	dockerUser                      = os.Getenv("DOCKER_USER")
	debug                           = os.Getenv("DEBUG") == "true"
	hstsMaxAge                      = os.Getenv("HSTS_MAX_AGE")
	hstsIncludeSubdomains           = os.Getenv("HSTS_INCLUDE_SUBDOMAINS")
	hstsPreload                     = os.Getenv("HSTS_PRELOAD")
	contentSecurityPolicy           = os.Getenv("CONTENT_SECURITY_POLICY")
	contentSecurityPolicyReportOnly = os.Getenv("CONTENT_SECURITY_POLICY_REPORT_ONLY")
)

func dLog(format string, args ...interface{}) {
	if debug {
		log.Printf(format, args...)
	}
}

func main() {
	fileInfos, err := os.ReadDir("/config")
	if err != nil {
		log.Fatal(err)
	}
	// loop over config files (one per app)
	for _, fileInfo := range fileInfos {
		if fileInfo.Type().IsDir() {
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
				if key == "homedest" {
					configs[app].homedest = value
					log.Printf("%s.homedest=%s", app, value)
				} else if key == "authPath" {
					configs[app].authPath = value
					log.Printf("%s.authPath=%s", app, value)
				} else if key == "cachePath" {
					configs[app].cachePath = value
					log.Printf("%s.cachePath=%s", app, value)
				} else {
					defineProxy(app, key, value)
				}
			}
		}
		if err := scanner.Err(); err != nil {
			log.Fatal(err)
		}
	}

	go http.ListenAndServe(":80", handlers.CompressHandler(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if dockerEnv == "DEVELOPMENT" {
				r.URL.Scheme = "http"
				handler(w, r)
			} else {
				// Redirect http to https
				log.Printf("%s %s http->https %s",
					r.RemoteAddr, r.Method, r.URL.String())
				url := r.URL
				host := strings.Split(r.Host, ":")[0]
				url.Host = host + ":" + proxyPort
				url.Scheme = "https"
				http.Redirect(w, r, url.String(), http.StatusMovedPermanently)
			}
		})))

	go http.ListenAndServe(":8080",
		handlers.CompressHandler(http.HandlerFunc(handler)))

	if strings.HasPrefix(proxyHost, "localhost") ||
		dockerEnv == "DEVELOPMENT" ||
		useAutocert != "true" {
		crt := "/certificates/" + proxyHost + ".crt"
		key := "/certificates/" + proxyHost + ".key"
		log.Fatal(http.ListenAndServeTLS(":443", crt, key,
			handlers.CompressHandler(http.HandlerFunc(secureHandler))))
	} else {
		manager := &autocert.Manager{
			Cache:      autocert.DirCache("/config/autocert"),
			Prompt:     autocert.AcceptTOS,
			HostPolicy: autocert.HostWhitelist(proxyHost),
		}

		// Configure TLSConfig following recommendations from
		// https://www.ssllabs.com/ssltest.
		tlsConfig := manager.TLSConfig()
		tlsConfig.MinVersion = tls.VersionTLS12
		tlsConfig.CipherSuites = []uint16{
			tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
			tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
			tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,
			tls.TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,
		}

		server := &http.Server{
			Addr:      ":https",
			TLSConfig: tlsConfig,
			Handler:   handlers.CompressHandler(http.HandlerFunc(secureHandler)),
		}

		log.Fatal(server.ListenAndServeTLS("", ""))
	}

}

func cors(h http.Header, r *http.Request) {
	h.Set("Vary", "Origin")
	h.Set("Access-Control-Allow-Origin", r.Header.Get("Origin"))
	h.Set("Access-Control-Allow-Methods",
		"GET, PUT, POST, DELETE, OPTIONS, HEAD")
	h.Set("Access-Control-Allow-Credentials", "true")
	h.Set("Access-Control-Allow-Headers", "SOAPAction, X-Requested-With, Origin, Content-Type, Authorization, Accept, access_token")
	h.Set("Access-Control-Expose-Headers", "Content-Type, Content-Disposition")
}

func handler(w http.ResponseWriter, r *http.Request) {
	log.Printf("%s %s %s", r.RemoteAddr, r.Method, r.RequestURI)
	if r.Method == "OPTIONS" || r.Method == "HEAD" {
		cors(w.Header(), r)
	} else {
		reverse(w, r)
	}
}

func secureHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("X-Content-Type-Options", "nosniff")

	if contentSecurityPolicy != "" {
		w.Header().Set("Content-Security-Policy", contentSecurityPolicy)
	}
	if contentSecurityPolicyReportOnly != "" {
		w.Header().Set("Content-Security-Policy-Report-Only",
			contentSecurityPolicyReportOnly)
	}

	hstsValue := "max-age=" + hstsMaxAge
	if hstsIncludeSubdomains == "true" {
		hstsValue += "; includeSubDomains"
		if hstsPreload == "true" {
			hstsValue += "; preload"
		}
	}
	w.Header().Set("Strict-Transport-Security", hstsValue)

	handler(w, r)
}

func defineProxy(app, key, value string) {
	log.Printf("/%s/%s -> %s", app, key, value)
	impersonate, insecure, authorise, cache := false, false, false, false
	for strings.HasPrefix(value, "impersonate,") ||
		strings.HasPrefix(value, "insecure,") ||
		strings.HasPrefix(value, "authorise,") ||
		strings.HasPrefix(value, "cache,") {
		split := strings.SplitN(value, ",", 2)
		value = split[1]
		switch split[0] {
		case "impersonate":
			impersonate = true
		case "insecure":
			insecure = true
		case "authorise":
			authorise = true
		case "cache":
			cache = true
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
		cache:       cache,
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
					reverseProxy(r, path, app, key, config, proxy).ServeHTTP(w, r)
					return
				}
			}
		}
	}
	log.Printf("%s %s Not Found %v %v", r.RemoteAddr, r.Method, r.Host, r.URL)
	http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
}
