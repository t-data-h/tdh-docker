#!/bin/bash
#
#  Initialize the spark-exporter container
#
#  --conf spark.metrics.conf=/etc/spark2/conf/graphite.properties
PNAME=${0##*\/}

name="$1"
res=

tdh_path=$(dirname "$(readlink -f "$0")")

if [ -z "$name" ]; then
    name="tdh-spark-exporter1"
fi

echo "Starting container '$name'"

( docker run --name $name \
  --mount "type=bind,src=${tdh_path}/../etc/graphite_mapping.conf,dst=/tmp/graphite_mapping.conf" \
  -d -p 9108:9108 -p 9109:9109 -p 9109:9109/udp \
  prom/graphite-exporter --graphite.mapping-config=/tmp/graphite_mapping.conf )

res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in $PNAME, abort..."
    exit $res
fi

exit $res
