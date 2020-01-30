FROM camptocamp/mapfish_print:3.22

ADD conf /tmp/conf

RUN mv /tmp/conf/print-apps ${CATALINA_HOME}/webapps/ROOT/print-apps/; \
    mv /tmp/conf/fonts ${CATALINA_HOME}/webapps/ROOT/WEB-INF/classes/fonts/; \
    mv /tmp/conf/mapfish-spring-custom-fonts.xml ${CATALINA_HOME}/webapps/ROOT/WEB-INF/classes/mapfish-spring-custom-fonts.xml

ENV CATALINA_OPTS='-DprintTimeout=1799'

ONBUILD ADD conf /tmp/conf
