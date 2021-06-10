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

func bodyString(body io.ReadCloser) (content string, err error) {
	if body == nil || body == http.NoBody {
		return "", nil
	}
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
	query := r.URL.Query()
	if body, errBodyString := bodyString(r.Body); errBodyString != nil {
		return false, errBodyString
	} else if jsonBody, errMarshal := json.Marshal(authPathBody{r.Method, path, query, body}); errMarshal != nil {
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
			// authorisation succeeded; we'll pass through what they responded
			// with
			if strings.HasPrefix(authorization, `"`) && strings.HasSuffix(authorization, `"`) {
				// it was a JSON encoded string; unescape `\` and `"`
				authorization = strings.Trim(authorization, `"`)
				authorization = strings.ReplaceAll(authorization, "\\\\", "\\")
				authorization = strings.ReplaceAll(authorization, "\\\"", "\"")
			}
			r.Header.Set("Authorization", authorization)
			// Also, substitute any authorization placeholders in the request,
			// to cater for use cases where the Authorization header isn't
			// usable. In the authPath endpoint, do check that the placeholder
			// value is literally "${AUTHORIZATION}", since any other
			// (tampered-with) value won't get replaced by the proper
			// authorization value here.
			substitute := func(value string) string {
				return strings.ReplaceAll(value, "${AUTHORIZATION}", authorization)
			}
			for _, values := range query {
				for i, value := range values {
					values[i] = substitute(value)
				}
			}
			r.URL.RawQuery = query.Encode()
			body = substitute(body)
			// reconstruct an unread io.ReadCloser body
			r.Body = ioutil.NopCloser(bytes.NewBufferString(body))
			r.ContentLength = int64(len(body))
			return true, nil
		}
	}
}
