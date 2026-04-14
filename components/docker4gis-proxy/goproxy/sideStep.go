package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
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
	if bytes, err := io.ReadAll(body); err != nil {
		return "", err
	} else {
		return string(bytes), nil
	}
}

func shortCircuit(r *http.Request, action string, statusCode int, err error) error {
	if statusCode == 0 {
		statusCode = http.StatusInternalServerError
	}

	// Set header values that are picked up by the CustomTransport.RoundTrip.
	r.Header.Set("X-Short-Circuit-Status-Code", fmt.Sprintf("%d", statusCode))

	shortCircuitMessage := fmt.Sprintf("%s short circuit -> %d %s - %s",
		action, statusCode, http.StatusText(statusCode), err)
	r.Header.Set("X-Short-Circuit-Message", shortCircuitMessage)

	return err
}

func sideStep(r *http.Request, sideStepName string, sideStepPath string,
	bodyStruct any, callback func(string) (string, int, error)) (err error) {
	short := func(statusCode int, err error) error {
		return shortCircuit(r, sideStepName, statusCode, err)
	}
	dLog("sideStep  %s %s %v", sideStepName, sideStepPath, bodyStruct)
	if jsonBody, errMarshal := json.Marshal(bodyStruct); errMarshal != nil {
		dLog("  ERROR: errMarshal")
		return short(0, errMarshal)
	} else if req, errNewRequest := http.NewRequest("POST", sideStepPath,
		bytes.NewReader(jsonBody)); errNewRequest != nil {
		dLog("  ERROR: errNewRequest")
		return short(0, errNewRequest)
	} else {
		req.Header = r.Header.Clone()
		req.Header.Del("accept-encoding")
		req.Header.Set("content-type", "application/json")
		req.Header.Set("accept", "application/json, application/*, text/*")
		if res, errDo := http.DefaultClient.Do(req); errDo != nil {
			dLog("  ERROR: errDo, req: %v", req)
			return short(0, errDo)
		} else if content, errBody := bodyString(res.Body); errBody != nil {
			dLog("  ERROR: errBody")
			return short(0, errBody)
		} else if res.StatusCode < 200 || res.StatusCode >= 300 {
			dLog("  ERROR: StatusCode")
			return short(res.StatusCode, fmt.Errorf("%s", content))
		} else if transformedContent, transformStatusCode, errTransform :=
			callback(content); errTransform != nil {
			dLog("  ERROR: errTransform")
			return short(transformStatusCode, errTransform)
		} else {
			if debug && false {
				curl := fmt.Sprintf("curl '%s' \\\n", sideStepPath)
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
				log.Printf("%s -> content: %s\n%s", sideStepName,
					transformedContent, curl)
			}
			return nil
		}
	}
}

type authPathBody struct {
	Method string
	Path   string
	Query  url.Values
	Body   string
}

func authorise(r *http.Request, path string, authPath string) (err error) {
	sideStepName := "authorise"
	query := r.URL.Query()
	if body, bodyWasRead, errBodyString := bodyStringFromRequest(r); errBodyString != nil {
		return shortCircuit(r, sideStepName, 0, errBodyString)
	} else {
		callback := func(authorization string) (string, int, error) {
			// authorisation succeeded; we'll pass through what they responded
			// with
			if strings.HasPrefix(authorization, `"`) &&
				strings.HasSuffix(authorization, `"`) {
				// it was a JSON encoded string; unescape `\` and `"`
				authorization = strings.Trim(authorization, `"`)
				authorization = strings.ReplaceAll(authorization, "\\\\", "\\")
				authorization = strings.ReplaceAll(authorization, "\\\"", "\"")
			}
			// Clean the authorization value to ensure it's valid for HTTP headers
			authorization = strings.TrimSpace(authorization)
			authorization = strings.ReplaceAll(authorization, "\n", "")
			authorization = strings.ReplaceAll(authorization, "\r", "")
			if debug {
				log.Printf("Authorization value (length=%d): %q", len(authorization), authorization)
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
				r.Body = io.NopCloser(bytes.NewBufferString(body))
				r.ContentLength = int64(len(body))
			}
			return authorization, 0, nil
		}
		bodyStruct := authPathBody{r.Method, path, query, body}
		return sideStep(r, sideStepName, authPath, bodyStruct, callback)
	}
}

type cachePathBody struct {
	Path   string
	Query  url.Values
	Header http.Header
}

type cachePathResult struct {
	Stale  bool
	Header http.Header
}

func cache(r *http.Request, path string, cachePath string) (header http.Header, err error) {
	sideStepName := "cache"
	result := &cachePathResult{}
	callback := func(content string) (string, int, error) {
		dLog("  cache callback - %s", content)
		// Parse the JSON-encoded result.
		if errUnmarshal := json.Unmarshal([]byte(content), result); errUnmarshal != nil {
			dLog("  ERROR: errUnmarshal - content: %s", content)
			return "", 0, errUnmarshal
		} else if !result.Stale {
			if result.Header == nil {
				dLog("  ERROR: Header - %v", result)
				return "", 0, fmt.Errorf("cachePath response had no header")
			} else if result.Header.Get("Last-Modified") == "" {
				dLog("  ERROR: Last-Modified")
				return "", 0, fmt.Errorf("cachePath response had no Last-Modified header")
			} else {
				dLog("  NO ERROR: !result.Stale")
				return "", http.StatusNotModified, fmt.Errorf("cache hit")
			}
		} else {
			return "", 0, nil
		}
	}
	bodyStruct := cachePathBody{path, r.URL.Query(), r.Header}
	err = sideStep(r, sideStepName, cachePath, bodyStruct, callback)
	return result.Header, err
}
