#!/bin/bash
#


( docker run \
  --env YARN_PROMETHEUS_LISTEN_ADDR=:9114 \
  --env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \
  --env YARN_PROMETHEUS_ENDPOINT_HOST=localhost \
  --env YARN_PROMETHEUS_ENDPOINT_PORT=8088 \
  --env YARN_PROMETHEUS_ENDPOINT_PATH="ws/v1/cluster/apps?state=running" \
  -p 9114:9114 pbweb/yarn-prometheus-exporter )

  
