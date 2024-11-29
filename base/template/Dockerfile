FROM a_generc_image:a-specific-tag

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["{{COMPONENT}}"]

# Install the bats plugin.
COPY conf/.plugins/bats /tmp/bats
RUN /tmp/bats/install.sh

# Install the runner plugin.
COPY conf/.plugins/runner /tmp/runner
RUN /tmp/runner/install.sh

COPY conf/.docker4gis /.docker4gis
COPY build.sh run.sh /.docker4gis/
