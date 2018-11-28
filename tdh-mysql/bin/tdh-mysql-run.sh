#!/bin/bash

network="$1"
tdh_path=$(dirname "$(readlink -f "$0")")

( docker run --name tdh-mysql1 \
  --mount type=bind,src=${tdh_path}/../etc/tdh-mysql.cnf,dst=/etc/my.cnf \
  --mount 'type=volume,source=tdh-mysql1-vol1,target=/var/lib/mysql' \
  --env MYSQL_RANDOM_ROOT_PASSWORD=true \
  --env MYSQL_LOG_CONSOLE=true \
  -d mysql/mysql-server:5.7 \
  --character-set-server=utf8 --collation-server=utf8_general_ci )

#  initialization scripts
# --mount type=bind,src=/path-on-host-machine/scripts/,dst=/docker-entrypoint-initdb.d/ \

sleep 3
passwd=$( docker logs tdh-mysql1 2>&1 | grep GENERATED | awk -F: '{ print $2 }' )

echo "passwd='$passwd'"

# docker exec -it tdh-mysql1 mysql -uroot_-p
