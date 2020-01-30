FROM tomcat:9.0.2-alpine

RUN apk update; apk add --no-cache \
	curl wget unzip grep sed \
	postgresql-client \
	ttf-freefont

ENV PATH=/util:$PATH \
	JAVA_OPTS='-XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParNewGC -XX:NewRatio=2 -XX:+AggressiveOpts'

COPY conf/plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

COPY conf/plugins/pg /tmp/pg
RUN /tmp/pg/install.sh

COPY conf/CATALINA_HOME /tmp/conf/CATALINA_HOME
COPY conf/webapps /tmp/conf/webapps
COPY conf/subconf.sh /tmp/conf/subconf.sh

COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["tomcat"]

ONBUILD COPY conf /tmp/conf
