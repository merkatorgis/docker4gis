package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
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

func authorise(r *http.Request, path string, authPath string) (statusCode int, err error) {
	query := r.URL.Query()
	if body, errBodyString := bodyString(r.Body); errBodyString != nil {
		return http.StatusInternalServerError, errBodyString
	} else if jsonBody, errMarshal := json.Marshal(authPathBody{r.Method, path, query, body}); errMarshal != nil {
		return http.StatusInternalServerError, errMarshal
	} else if req, errNewRequest := http.NewRequest("POST", authPath, bytes.NewReader(jsonBody)); errNewRequest != nil {
		return http.StatusInternalServerError, errNewRequest
	} else {
		req.Header = r.Header.Clone()
		req.Header.Del("accept-encoding")
		req.Header.Set("content-type", "application/json")
		req.Header.Set("accept", "application/json, application/*, text/*")
		filterCookies(req)
		if res, errDo := http.DefaultClient.Do(req); errDo != nil {
			return http.StatusInternalServerError, errDo
		} else if authorization, errAuthorization := bodyString(res.Body); errAuthorization != nil {
			return http.StatusInternalServerError, errAuthorization
		} else if res.StatusCode != 200 {
			return res.StatusCode, fmt.Errorf(authorization)
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
			if debug {
				curl := fmt.Sprintf("curl '%s' \\\n", authPath)
				curl += "  --request POST \\\n"
				curl += fmt.Sprintf("  --data '%s' \\\n", string(jsonBody))
				for header, values := range req.Header {
					curl += fmt.Sprintf("  --header '%s: ", header)
					for i, value := range values {
						if i > 0 {
							curl += "; "
						}
						curl += value
					}
					curl += "' \\\n"
				}
				curl += "  --insecure \\\n"
				curl += "  --include"
				log.Printf("authorise -> authorization: %s\n%s", authorization, curl)
			}
			return res.StatusCode, nil
		}
	}
}
