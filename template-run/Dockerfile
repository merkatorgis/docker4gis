FROM alpine:3.7

COPY conf /tmp/conf

RUN mv /tmp/conf/entrypoint/* /

ENTRYPOINT ["/entrypoint"]
CMD ["run"]
