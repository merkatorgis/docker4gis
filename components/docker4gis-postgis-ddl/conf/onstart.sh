#!/bin/bash
set -e

# Wait until the database is ready.
until [ "$(pg.sh -Atc "select current_setting('db.ready', true)")" = "true" ]; do
    sleep 1
done

# Clear and reuse the deferred execution file for schema scripts.
echo '' >/last

/subconf.sh /tmp/mail/conf.sh
/subconf.sh /tmp/web/conf.sh
/subconf.sh /tmp/admin/conf.sh
/subconf.sh /tmp/wms/conf.sh

# Extension images may add extra schemas in /ddl.
[ -x /ddl/conf.sh ] && /subconf.sh /ddl/conf.sh

# shellcheck disable=SC1091
source /last
