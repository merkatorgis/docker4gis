FROM node:24.1.0-bookworm

RUN mkdir /src
WORKDIR /src
ONBUILD COPY . .
ONBUILD RUN npm ci
ONBUILD RUN npm run build
