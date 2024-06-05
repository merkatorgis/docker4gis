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

	director := func(r *http.Request) {
		basicAuthAccessToken(r, key)
		if err := validateSecret(r, key, config.secret); err != nil {
			log.Printf("secret -> unauthorized  %s", path)
			http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
			return
		}
		if proxy.authorise {
			if statusCode, err := authorise(r, path, config.authPath); err != nil {
				log.Printf("authorise -> %s", http.StatusText(statusCode))
				http.Error(w, err.Error(), statusCode)
				return
			}
		}

		realIp := r.Header.Get("X-Real-Ip")
		if realIp == "" {
			realIp, _, _ = net.SplitHostPort(r.RemoteAddr)
			r.Header.Set("X-Real-Ip", realIp)
		}

		forwardedHost := r.Host
		r.Header.Set("X-Forwarded-Host", forwardedHost)

		forwardedProto := "https" // r.URL.Scheme == ""
		r.Header.Set("X-Forwarded-Proto", forwardedProto)

		forwardedPath := "/" + app + key
		r.Header.Set("X-Forwarded-Path", forwardedPath)
		r.Header.Set("X-Script-Name", forwardedPath)

		forwarded := fmt.Sprintf("for=%s;host=%s;proto=%s;path=%s", realIp, forwardedHost, forwardedProto, forwardedPath)
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

		log.Printf("%s %s Reverse %v %v", r.RemoteAddr, r.Method, r.Host, r.URL)

		if debug {
			curl := fmt.Sprintf("curl '%s' \\\n", r.URL)
			curl += fmt.Sprintf("  --request %s \\\n", r.Method)
			for header, values := range r.Header {
				curl += fmt.Sprintf("  -H '%s: ", header)
				for i, value := range values {
					if i > 0 {
						curl += "; "
					}
					curl += value
				}
				curl += "' \\\n"
			}
			if r.Method == "PUT" || r.Method == "POST" {
				curl += "  --data-raw '__TODO__paste_the_request_body_here' \\\n"
			}
			curl += "  --insecure \\\n"
			curl += "  --include"
			log.Printf("%s", curl)
		}

	}

	modifyResponse := func(resp *http.Response) error {

		cors(resp.Header, r)

		// collect the response's cookies, with  Domain and Path rewritten
		// for the proxy client's perspective
		var cookies []*http.Cookie
		for _, cookie := range resp.Cookies() {
			cookie.Domain = ""
			oldCookiePath := cookie.Path
			// If cookie.Path starts with /{app}/{"key"} (e.g. /geowep/api),
			// then it should be good.
			if !strings.HasPrefix(cookie.Path, "/"+app+strings.TrimSuffix(key, "/")) {
				if cookie.Path == "" {
					cookie.Path = "/"
				}
				// Map the remote site's root to our proxy key.
				cookie.Path = strings.TrimSuffix(key, "/") + cookie.Path
				// Prepend with the app name, if it was included in the client's
				// request.
				if strings.HasPrefix(r.URL.Path, "/"+app) {
					cookie.Path = "/" + app + cookie.Path
				}
			}
			cookies = append(cookies, cookie)
			if debug {
				log.Printf("-- %s cookie %s: path %s -> %s", r.URL, cookie.Name, oldCookiePath, cookie.Path)
			}
		}

		// replace all cookies with the rewritten ones
		resp.Header.Del("Set-Cookie")
		for _, cookie := range cookies {
			resp.Header.Add("Set-Cookie", cookie.String())
		}

		return nil
	}

	transport := http.DefaultTransport
	if proxy.insecure {
		transport = transportInsecure
	}

	return &httputil.ReverseProxy{
		Director:       director,
		ModifyResponse: modifyResponse,
		Transport:      transport,
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
