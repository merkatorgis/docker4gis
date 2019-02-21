FROM node:11.3.0

RUN npm install -g serve

CMD [ "serve", "--listen", "80", "--single", "/build" ]

ONBUILD ADD . /build
