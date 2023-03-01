FROM wscherphof/mapproxy:bullseye

# Install gettext-base for envsubst in mapproxy-seed-args.
RUN apt update
RUN apt install -y gettext-base

COPY conf /srv/mapproxy/config
RUN mv /srv/mapproxy/config/entrypoint /usr/local/bin/
RUN mv /srv/mapproxy/config/mapproxy-seed-args /usr/local/bin/

ONBUILD COPY conf /srv/mapproxy/config

# Since file locking doesn’t work well on most network filesystems you are
# likely to get errors when MapProxy writes these files on network filesystems.
# You should configure MapProxy to write all lock files on a local filesystem to
# prevent this. See globals.cache.lock_dir and globals.cache.tile_lock_dir.
RUN mkdir -p /srv/mapproxy/locks
RUN chmod a+rwx /srv/mapproxy/locks
#
RUN mkdir -p /srv/mapproxy/tile_locks
RUN chmod a+rwx /srv/mapproxy/tile_locks

ENTRYPOINT [ "entrypoint" ]
CMD [ "mapproxy" ]

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
# ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /srv/mapproxy/config/args
ONBUILD RUN cp /srv/mapproxy/config/args /.docker4gis
