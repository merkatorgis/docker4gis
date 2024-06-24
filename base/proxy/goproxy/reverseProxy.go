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
	cookieMap                         = make(map[string]*Set)
)

func init() {
	transportInsecure.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
}

func logRequest(r *http.Request) {
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

func reverseProxy(w http.ResponseWriter, r *http.Request, path, app, key string,
	config *config, proxy *proxy) *httputil.ReverseProxy {

	keyWithoutTrailingSlash := strings.TrimSuffix(key, "/")

	// Prepend the app name to a path (either "" or starting with "/"), if the
	// app name was included in the client's request.
	appPath := func(path string) string {
		if r.URL.Path == "/"+app || strings.HasPrefix(r.URL.Path, "/"+app+"/") {
			path = "/" + app + path
		}
		return path
	}

	director := func(r *http.Request) {

		basicAuthAccessToken(r, key)

		if proxy.authorise {
			// Have this request authorised at AUTH_PATH.
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

		forwardedPath := appPath(keyWithoutTrailingSlash)
		r.Header.Set("X-Forwarded-Path", forwardedPath)
		r.Header.Set("X-Forwarded-Prefix", forwardedPath)
		r.Header.Set("X-Script-Name", forwardedPath)

		forwarded := fmt.Sprintf("for=%s;host=%s;proto=%s;path=%s",
			realIp, forwardedHost, forwardedProto, forwardedPath)
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

		// Prevent forwarding other destinations' cookies (specifically: don't
		// forward internal authentication cookies, that are set with a Path of
		// "/" or "/{app}", to support the AUTH_PATH functionality). Using the
		// cookieMap to match a cookie with the proxy path that set it (note
		// that cookies from a Request do not carry a Path value, like cookies
		// from a Response do).
		clonedRequest := r.Clone(r.Context())
		r.Header.Del("Cookie")
		// Repopulate with just those cookies from the request that were
		// previously jarred for this key.
		if names, ok := cookieMap[key]; ok {
			for _, name := range names.List() {
				if cookie, err := clonedRequest.Cookie(name); err == nil {
					r.AddCookie(cookie)
				}
			}
		}

		if debug && false {
			logRequest(r)
		}

		cookieNames := make([]string, 0)
		for _, cookie := range r.Cookies() {
			cookieNames = append(cookieNames, cookie.Name)
		}
		log.Printf("%s %s Reverse %v %v %s",
			r.RemoteAddr, r.Method, r.Host, r.URL, cookieNames)
	}

	modifyResponse := func(resp *http.Response) error {

		cors(resp.Header, r)

		// Rewrite all cookies' Domain and Path to match the proxy client's
		// perspective.
		cookieSet := NewSet()
		if set, ok := cookieMap[key]; ok {
			cookieSet = set
		} else {
			cookieMap[key] = cookieSet
		}
		cookies := resp.Cookies()
		resp.Header.Del("Set-Cookie")
		for _, cookie := range cookies {

			// Put this cookie in the cookieMap (it's used in the Director to
			// filter cookies on the request's URL).
			cookieSet.Add(cookie.Name)

			// https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value
			cookie.Domain = ""

			oldCookiePath := cookie.Path

			if strings.HasPrefix(config.authPath, proxy.target.String()) &&
				(cookie.Path == "" ||
					cookie.Path == "/" ||
					cookie.Path == appPath(keyWithoutTrailingSlash) ||
					cookie.Path == appPath(key)) {
				// This cookie is probably an authentication token; map it to
				// the root of the application, so that it will be sent with
				// requests for other keys (i.e. proxied paths), to render these
				// requests authenticated when put through AUTH_PATH.
				cookie.Path = appPath("/")
			} else if !(cookie.Path == appPath(keyWithoutTrailingSlash) ||
				strings.HasPrefix(cookie.Path, appPath(key))) {
				// Map the remote site's root to our proxy key.
				if !(cookie.Path == keyWithoutTrailingSlash ||
					strings.HasPrefix(cookie.Path, key)) {
					cookie.Path = keyWithoutTrailingSlash + cookie.Path
				}
				cookie.Path = appPath(cookie.Path)
			}

			if debug {
				log.Printf("-- %s cookie %s: path %s -> %s",
					r.URL, cookie.Name, oldCookiePath, cookie.Path)
			}

			// Put the rewritten cookie back in the response's header.
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
				log.Printf(
					"access_token provided in viewparams as well as in basic auth; using the viewparams value")
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
