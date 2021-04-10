package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
)

// copy of https://golang.org/pkg/net/http/httputil/?m=all#drainBody
func drainBody(b io.ReadCloser) (r1, r2 io.ReadCloser, err error) {
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

func bodyString(body io.ReadCloser) (content string, err error) {
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

func authorise(r *http.Request, path string, authPath string) (authorised bool, err error) {
	if body, originalBody, errDrainBody := drainBody(r.Body); errDrainBody != nil {
		return false, errDrainBody
	} else if stringBody, errBodyString := bodyString(body); errBodyString != nil {
		return false, errBodyString
	} else if jsonBody, errMarshal := json.Marshal(authPathBody{r.Method, path, r.URL.Query(), stringBody}); errMarshal != nil {
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
