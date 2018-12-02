#!/bin/bash
#

name="$1"

if [ -z "$name" ]; then
    name="tdh-yarn-exporter1"
fi

( docker run \
  --env YARN_PROMETHEUS_LISTEN_ADDR=:9113 \
  --env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \
  --env YARN_PROMETHEUS_ENDPOINT_HOST=localhost \
  --env YARN_PROMETHEUS_ENDPOINT_PORT=8088 \
  --env YARN_PROMETHEUS_ENDPOINT_PATH="ws/v1/cluster/metrics" \
  -p 9113:9113 pbweb/yarn-prometheus-exporter )
  
