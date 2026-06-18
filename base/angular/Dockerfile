FROM node:24.16.0-trixie

RUN mkdir /src
WORKDIR /src
ONBUILD COPY . .
ONBUILD RUN npm ci
ONBUILD RUN npm run build
