FROM node:11.3.0

RUN npm install -g serve

COPY serve.json /build/serve.json

CMD [ "serve", "--listen", "80", "--single", "/build" ]

ONBUILD ADD . /build
