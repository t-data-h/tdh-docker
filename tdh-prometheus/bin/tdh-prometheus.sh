#!/bin/bash
#
# Prometheus Server
#
PNAME=${0##*\/}

name="$1"
port="$2"

tdh_path=$(dirname "$(readlink -f "$0")")

if [ -z "$name" ]; then
    name="tdh-prometheus1"
    echo "Initializing Docker instance as '$name'"
fi
volname="${name}-data"

if [ -z "$port" ]; then
    port=9090
fi

( docker run --name tdh-prometheus1 -p${port}:9090 \
  --mount "type=bind,src=${tdh_path}/../etc/prometheus.yml,dst=/etc/prometheus/prometheus.yml" \
  --mount "type=volume,source=$volname,target=/prometheus-data" \
  prom/prometheus )

res=$?

if [ $res -ne 0 ]; then
    echo "Error in $PNAME, docker run"
fi

exit $res
