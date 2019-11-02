#!/bin/bash

pg.sh -c "create extension if not exists ogr_fdw"
pg.sh -c "create extension if not exists odbc_fdw"
pg.sh -c "create extension if not exists plsh"
pg.sh -c "create extension if not exists pgcrypto"
pg.sh -c "create extension if not exists pgjwt"

/tmp/subconf.sh /tmp/mail/conf.sh
/tmp/subconf.sh /tmp/web/conf.sh

find /tmp/conf -name "conf.sh" -exec /tmp/subconf.sh {} \;
