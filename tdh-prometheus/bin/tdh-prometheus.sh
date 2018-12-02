#!/bin/bash
#
# Prometheus Server
#

name = "$1"

tdh_path=$(dirname "$(readlink -f "$0")")
volname="prometheus-data"

if [ -z "$name" ]; then
    name="tdh-prometheus1"
    echo "Initializing Docker instance as '$name'"
fi

( docker run --name tdh-prometheus1 -p9090:9090 \
  --mount "type=bind,src=${tdh_path}/../etc/prometheus.yml,dst=/etc/prometheus/prometheus.yml" \
  --mount "type=volume,source=$volname,target=/prometheus-data" \
  prom/prometheus )
