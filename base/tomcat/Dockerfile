FROM tomcat:9.0.2-alpine

RUN apk update; apk add --no-cache \
	curl wget unzip grep sed \
	postgresql-client \
	ttf-freefont

ENV PATH=/util:$PATH \
	JAVA_OPTS='-Xms2g -Xmx2g -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParNewGC -XX:NewRatio=2 -XX:+AggressiveOpts'

ADD conf /tmp/conf

RUN mv /tmp/conf/entrypoint/* /; \
	/tmp/conf/plugins/pg/install.sh

ENTRYPOINT ["/entrypoint"]
CMD ["tomcat"]

ONBUILD ADD conf /tmp/conf
