#!/bin/bash
#

( docker run \
  --env YARN_PROMETHEUS_ENDPOINT_HOST=localhost \
  --env YARN_PROMETHEUS_LISTEN_ADDR=:9113 \
  -p 9113:9113 pbweb/yarn-prometheus-exporter )
