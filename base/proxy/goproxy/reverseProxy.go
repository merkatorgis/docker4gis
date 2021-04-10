package main

import (
	"crypto/tls"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"strings"
)

var (
	transportInsecure *http.Transport = http.DefaultTransport.(*http.Transport)
)

func init() {
	transportInsecure.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
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
				log.Printf("secret -> unauthorized  %s", path)
				http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
				return
			}
			if proxy.authorise {
				if authorised, err := authorise(r, path, config.authPath); err != nil {
					log.Printf("authorise -> error: %v", err)
					http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
					return
				} else if !authorised {
					log.Printf("authorise -> unauthorized  %s", path)
					http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
					return
				}
			}
			forwardedFor := r.Header.Get("X-Real-Ip")
			if forwardedFor == "" {
				forwardedFor = r.Header.Get("X-Forwarded-For")
			}
			if forwardedFor == "" {
				forwardedFor, _, _ = net.SplitHostPort(r.RemoteAddr)
			}
			r.Header.Set("X-Forwarded-For", forwardedFor)
			forwardedHost := r.Host
			r.Header.Set("X-Forwarded-Host", forwardedHost)
			forwardedProto := r.URL.Scheme
			r.Header.Set("X-Forwarded-Proto", forwardedProto)
			forwardedPath := "/" + app + key
			r.Header.Set("X-Forwarded-Path", forwardedPath)
			r.Header.Set("X-Script-Name", forwardedPath)
			forwarded := fmt.Sprintf("for=%s;host=%s;proto=%s;path=%s", forwardedFor, forwardedHost, forwardedProto, forwardedPath)
			r.Header.Set("Forwarded", forwarded)
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
