FROM camptocamp/mapfish_print:3.28

ADD conf /tmp/conf

RUN mv /tmp/conf/print-apps "$CATALINA_HOME"/webapps/ROOT/print-apps/; \
    mv /tmp/conf/fonts "$CATALINA_HOME"/webapps/ROOT/WEB-INF/classes/fonts/; \
    mv /tmp/conf/mapfish-spring-custom-fonts.xml \
    "$CATALINA_HOME"/webapps/ROOT/WEB-INF/classes/mapfish-spring-custom-fonts.xml

ENV CATALINA_OPTS=-DprintTimeout=1799

RUN mv /tmp/conf/certificates /certificates/; \
    echo changeit | keytool \
    -import \
    -keystore "$JAVA_HOME"/lib/security/cacerts \
    -alias letsencrypt \
    -file /certificates/letsencrypt.cer

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
    cp /tmp/conf/args /.docker4gis
