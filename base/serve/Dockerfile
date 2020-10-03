FROM node:12.18.4

RUN npm install -g serve

COPY conf/serve.json /
COPY conf/entrypoint /

EXPOSE 80
VOLUME /fileport

ENTRYPOINT [ "/entrypoint" ]
CMD [ "serve" ]

ENV DYNAMIC=
ENV SINGLE=
ONBUILD COPY . /wwwroot

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
# ONBUILD COPY conf /tmp/conf
# ONBUILD RUN touch /tmp/conf/args; \
#     cp /tmp/conf/args /.docker4gis
RUN touch /.docker4gis/args
