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

func bodyStringFromRequest(r *http.Request) (content string, wasRead bool, err error) {
	if r.Body == nil || r.Body == http.NoBody {
		return "", false, nil
	}
	if strings.HasPrefix(r.Header.Get("content-type"), "multipart/form-data") {
		return `"Bodies with content-type multipart/form-data (file uploads) are not forwarded to the authorisation endpoint."`, false, nil
	}
	content, err = bodyString(r.Body)
	return content, true, err
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

func authorise(r *http.Request, path string, authPath string) (statusCode int, err error) {
	query := r.URL.Query()
	if body, bodyWasRead, errBodyString := bodyStringFromRequest(r); errBodyString != nil {
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
		if res, errDo := http.DefaultClient.Do(req); errDo != nil {
			return http.StatusInternalServerError, errDo
		} else if authorization, errBody := bodyString(res.Body); errBody != nil {
			return http.StatusInternalServerError, errBody
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
			if len(authorization) > 0 {
				r.Header.Set("Authorization", authorization)
			} else {
				r.Header.Del("Authorization")
			}
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
			if bodyWasRead {
				body = substitute(body)
				// Reconstruct an unread io.ReadCloser body.
				r.Body = ioutil.NopCloser(bytes.NewBufferString(body))
				r.ContentLength = int64(len(body))
			}
			if debug && false {
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
