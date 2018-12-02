#!/bin/bash
#
PNAME=${0##*\/}

name="$1"
res=

if [ -z "$name" ]; then
    name="tdh-yarn-exporter1"
fi

echo "Starting container '$name'"

( docker run --name $name \
  --env YARN_PROMETHEUS_LISTEN_ADDR=:9113 \
  --env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \
  --env YARN_PROMETHEUS_ENDPOINT_HOST=localhost \
  --env YARN_PROMETHEUS_ENDPOINT_PORT=8088 \
  --env YARN_PROMETHEUS_ENDPOINT_PATH="ws/v1/cluster/metrics" \
  -p 9113:9113 pbweb/yarn-prometheus-exporter )

 res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in $PNAME, abort..."
    exit $res
fi

exit $res
