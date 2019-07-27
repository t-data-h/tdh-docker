#!/bin/bash
#
#  tdh-docker-run.sh  provides a wrapper to running docker start/stop (or other) 
#  commands across many tdh containers.
#
PNAME=${0##*\/}
ACTION="$@"
rt=0

TDHLIST="tdh-prometheus1 tdh-grafana1 tdh-hdfs-exporter1 tdh-yarn-exporter1 tdh-spark-exporter1 tdh-mysql-exporter1"

if [ -n "$TDH_CONTAINERS" ]; then
    TDHLIST="$TDH_CONTAINERS"
fi

if [ -z "$ACTION" ]; then
    echo ""
    echo "Usage: $PNAME <actions>"
    echo "  Runs the provided action on all tdh containers as defined by \$TDHLIST"
    echo "  action = docker command to run. eg start|stop|restart|inspect"
    echo ""
    exit 1
fi

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

for container in $TDHLIST; do

    ( docker $ACTION $container )

    rt=$?
    if [ $rt -ne 0 ]; then
        echo "Error in docker action for $container"
        break
    fi
done

exit $rt
