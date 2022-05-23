FROM node:18.2.0

RUN mkdir /src
WORKDIR /src
ONBUILD COPY . .
ONBUILD RUN npm install
ONBUILD RUN npm run build
