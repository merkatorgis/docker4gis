package main

import (
	"crypto/tls"
	"encoding/base64"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"

	"golang.org/x/crypto/acme/autocert"
)

var proxyHost = os.Getenv("REGISTRY_HOST")
var useAutocert = os.Getenv("AUTOCERT")
var dockerEnv = os.Getenv("DOCKER_ENV")
var registry *httputil.ReverseProxy

func init() {
	theregistry, _ := url.Parse("https://theregistry")
	registry = httputil.NewSingleHostReverseProxy(theregistry)
	transport := http.DefaultTransport.(*http.Transport)
	transport.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
	registry.Transport = transport
}

func main() {
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
	log.Printf("%+v", r)
	if owner := strings.SplitN(r.RequestURI, "/", 4)[2]; owner == "" { // "/v2/"
		registry.ServeHTTP(w, r)
	} else { // "/v2/owner/repo/image..."
		auth := strings.SplitN(r.Header.Get("Authorization"), " ", 2) // "Basic =458g7y8734hg438hjvkvogdh"
		if len(auth) == 2 && auth[0] == "Basic" {
			payload, _ := base64.StdEncoding.DecodeString(auth[1])
			user := strings.SplitN(string(payload), ":", 2)[0] // "user:password"
			if user == owner || strings.HasPrefix(user, "merkator/") {
				registry.ServeHTTP(w, r)
			} else {
				http.Error(w, "{\"errors\":[{\"code\":\"DENIED\",\"message\":\"requested access to the resource is denied\",\"detail\":\"The access controller denied access for the operation on a resource.\"}]}", http.StatusForbidden)
			}
		} else {
			http.Error(w, "{\"errors\":[{\"code\":\"UNAUTHORIZED\",\"message\":\"authentication required\",\"detail\":\"The access controller was unable to authenticate the client. Often this will be accompanied by a Www-Authenticate HTTP response header indicating how to authenticate.\"}]}", http.StatusUnauthorized)
		}
	}
}
