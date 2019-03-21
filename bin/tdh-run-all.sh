#!/bin/bash
#
#  tdh-run-all.sh  provides a wrapper to running docker start/stop commands
#  across all tdh containers
#
PNAME=${0##*\/}
ACTION="$1"
rt=0

TDHLIST="tdh-prometheus1 tdh-grafana1 tdh-hdfs-exporter1 tdh-yarn-exporter1 tdh-spark-exporter1 tdh-mysql-exporter1"

if [ -n "$TDH_CONTAINERS" ]; then
    TDHLIST="$TDH_CONTAINERS"
fi

if [ -z "$ACTION" ]; then
    echo ""
    echo "Usage: $PNAME <action>"
    echo "  Runs the provided action on all tdh containers as defined by \$TDHLIST"
    echo "  action = docker command to run. eg start|stop|restart|inspect|etc."
    echo ""
    exit 1
fi

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

for container in $TDHLIST; do

    ( docker $@ $container )

    rt=$?
    if [ $rt -ne 0 ]; then
        echo "Error in docker start for $container"
        break
    fi
done

exit $rt
