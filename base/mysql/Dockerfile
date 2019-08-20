FROM mysql:8.0.17

ADD conf /tmp/conf

RUN /tmp/conf/plugins/mysql/install.sh

RUN	mkdir -p /util; \
	mv /tmp/conf/schema.sh /util/; \
	mv /tmp/conf/entrypoint/* /

ENV PATH=/util:$PATH

ENTRYPOINT ["/entrypoint"]
CMD ["mysqld"]

ONBUILD ADD conf /tmp/conf
