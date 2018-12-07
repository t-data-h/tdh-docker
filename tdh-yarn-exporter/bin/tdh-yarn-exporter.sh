#!/bin/bash
#
PNAME=${0##*\/}

name="$1"
rmhost="$2"
rmport="$3"
res=

if [ -z "$name" ]; then
    name="tdh-yarn-exporter1"
fi

if [ -z "$rmhost" ]; then
    rmhost=localhost
fi

if [ -z "$rmport" ]; then
    rmport=8088
fi

echo "Starting container '$name'"

( docker run --name $name -p 9113:9113 -d \
  --env YARN_PROMETHEUS_LISTEN_ADDR=:9113 \
  --env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \
  --env YARN_PROMETHEUS_ENDPOINT_HOST=$rmhost \
  --env YARN_PROMETHEUS_ENDPOINT_PORT=$rmport \
  --env YARN_PROMETHEUS_ENDPOINT_PATH="ws/v1/cluster/metrics" \
  pbweb/yarn-prometheus-exporter )

res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in $PNAME, abort..."
    exit $res
fi

exit $res
