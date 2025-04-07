FROM node:22.14.0-bookworm

RUN mkdir /src
WORKDIR /src
ONBUILD COPY . .
ONBUILD RUN npm install
ONBUILD RUN npm run build
