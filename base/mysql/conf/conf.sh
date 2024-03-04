#!/bin/bash
set -e

mysql.sh -e "
	create user 'root'@'$GATEWAY' identified by '$MYSQL_ROOT_PASSWORD';
	grant all on *.* to 'root'@'$GATEWAY';
" &

find /tmp/conf -name "conf.sh" -exec /tmp/subconf.sh {} \; &
