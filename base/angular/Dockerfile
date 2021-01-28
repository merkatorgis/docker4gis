FROM node:14.5.0

RUN mkdir /src
WORKDIR /src
ONBUILD COPY . .
ONBUILD RUN npm install
ONBUILD RUN npm run build
# ONBUILD RUN npm run buildlib
# ONBUILD RUN npm run buildapp
