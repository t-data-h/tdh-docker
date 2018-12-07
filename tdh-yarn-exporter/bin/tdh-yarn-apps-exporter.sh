#!/bin/bash
#
name="$1"
port="$2"

if [ -z "$name" ]; then
    name="tdh-yarnapps-exporter1"
fi
if [ -z "$port" ]; then
    port="9114"
fi

( docker run --name $name -p ${port}:9114 -d \
  --env YARN_PROMETHEUS_LISTEN_ADDR=:9114 \
  --env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \
  --env YARN_PROMETHEUS_ENDPOINT_HOST=localhost \
  --env YARN_PROMETHEUS_ENDPOINT_PORT=8088 \
  --env YARN_PROMETHEUS_ENDPOINT_PATH="ws/v1/cluster/apps?state=running" \
  pbweb/yarn-prometheus-exporter )

  
