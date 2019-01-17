FROM node:11.3.0

RUN npm install -g serve

CMD [ "serve", "-s", "/build" ]

ONBUILD ADD . /build
