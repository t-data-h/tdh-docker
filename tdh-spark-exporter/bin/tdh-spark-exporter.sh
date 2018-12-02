#!/bin/bash
#
#  Initialize the spark-exporter container
#
#  --conf spark.metrics.conf=/etc/spark2/conf/graphite.properties

name="$1"
tdh_path=$(dirname "$(readlink -f "$0")")

if [ -z "$name" ]; then
    name="tdh-spark-exporter1"
fi

( docker run -d -p 9108:9108 -p 9109:9109 -p 9109:9109/udp \
  --mount "type=bind,src=${tdh_path}/../etc/graphite_mapping.conf,dst=/tmp/graphite_mapping.conf" \
  prom/graphite-exporter --graphite.mapping-config=/tmp/graphite_mapping.conf )

