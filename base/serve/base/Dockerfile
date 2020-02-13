FROM node:11.3.0

RUN npm install -g serve

COPY serve.json /build/serve.json
COPY entrypoint /

ENTRYPOINT [ "/entrypoint" ]
CMD [ "serve" ]

ONBUILD ADD . /build
