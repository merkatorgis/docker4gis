FROM swaggerapi/swagger-ui

COPY conf/interceptors.js /usr/share/nginx/configurator/interceptors.js

RUN configurator=/usr/share/nginx/configurator; \
    index="${configurator}/index.js"; \
    interceptors="${configurator}/interceptors.js"; \
    search='const ui = SwaggerUIBundle({'; \
    app='const APP=location.pathname.split("/", 2).pop();'; \
    authorization='const AUTHORIZATION=APP + ".Authorization";'; \
    access_token='const ACCESS_TOKEN=APP + ".access_token";'; \
    replace="${app} ${authorization} ${access_token} ${search} $(cat ${interceptors} | tr -d '\n')"; \
    sed -i "s|${search}|${replace}|g" "${index}"
