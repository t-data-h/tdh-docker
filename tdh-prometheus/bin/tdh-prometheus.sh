#!/bin/bash
#
# Prometheus Server
#

tdh_path=$(dirname "$(readlink -f "$0")")

( docker run -p 9090:9090 \
  --mount "type=bind;src=${tdh_path}/../etc/prometheus.yml:/etc/prometheus/prometheus.yml" \
  --mount "type=volume;source=prometheus-data,target=/prometheus-data" \
  prom/prometheus )
