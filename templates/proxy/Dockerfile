FROM docker4gis/proxy:592

# These default values are overwritten by run time environment values, if set:
ENV API="http://$DOCKER_USER-api:8080/"
# Where to ask for authorisation
ENV AUTH_PATH="${API}rpc/auth_path"
ENV APP="http://$DOCKER_USER-app/"
ENV HOMEDEST="/$DOCKER_USER/app/"

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security
# https://hstspreload.org/
ENV HSTS_MAX_AGE=63072000
ENV HSTS_INCLUDE_SUBDOMAINS=true
ENV HSTS_PRELOAD=true

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/frame-ancestors
# https://csp.withgoogle.com/docs/strict-csp.html
# Set to "" to disable.
ENV CONTENT_SECURITY_POLICY=" \
    frame-ancestors 'none'; \
    object-src 'none'; \
    script-src 'unsafe-inline' 'unsafe-eval' 'self' https:; \
    base-uri 'none';"
ENV CONTENT_SECURITY_POLICY_REPORT_ONLY=""
