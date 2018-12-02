#!/bin/bash
#
#  tdh-mysql-init.sh
#
#   Initialize MySQL Daemon via Docker
#
PNAME=${0##*\/}

name="$1"
port="$2"
#network="$3"

tdh_path=$(dirname "$(readlink -f "$0")")
volname=
res=

if [ -z "$name" ]; then
    name="tdh-mysql1"
fi
if [ -z "$port" ]; then
    port=3307
    echo "Default local port set to $port"
fi
volname="${name}-vol1"

echo "Initializing Docker container instance as '$name'"

( docker run --name $name -p${port}:3306 \
  --mount "type=bind,src=${tdh_path}/../etc/tdh-mysql.cnf,dst=/etc/my.cnf" \
  --mount "type=volume,source=${volname},target=/var/lib/mysql" \
  --env MYSQL_RANDOM_ROOT_PASSWORD=true \
  --env MYSQL_LOG_CONSOLE=true \
  -d mysql/mysql-server:5.7 \
  --character-set-server=utf8 --collation-server=utf8_general_ci )

res=$?
if [ $res -ne 0 ]; then
    echo "ERROR in $PNAME, abort..."
    exit $res
fi

#  initialization scripts
# --mount type=bind,src=/path-on-host-machine/scripts/,dst=/docker-entrypoint-initdb.d/ \
# allow mysqld to start and generate password
sleep 3
passwd=$( docker logs tdh-mysql1 2>&1 | grep GENERATED | awk -F': ' '{ print $2 }' )
echo "passwd='$passwd'"

exit $res
