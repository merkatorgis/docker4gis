FROM tomcat:9.0.86-jre17-temurin-jammy

ENV PATH=/util:$PATH \
	JAVA_OPTS='-XX:SoftRefLRUPolicyMSPerMB=36000 -XX:NewRatio=2'

COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

COPY conf/.plugins/pg /tmp/pg
RUN /tmp/pg/install.sh

COPY conf/CATALINA_HOME /tmp/conf/CATALINA_HOME
COPY conf/webapps /tmp/conf/webapps
COPY conf/subconf.sh /tmp/conf/subconf.sh

COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["tomcat"]

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
