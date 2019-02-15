#!/bin/bash
#
PNAME=${0##*\/}
ACTION="$1"
rt=0

TDHLIST="tdh-mysql1 tdh-prometheus1 tdh-grafana1 tdh-hdfs-exporter1 tdh-yarn-exporter1 tdh-spark-exporter1 tdh-mysql-exporter1"

if [ -n "$TDH_CONTAINERS" ]; then
    TDHLIST="$TDH_CONTAINERS"
fi

if [ -z "$ACTION" ]; then
    echo "Usage: $PNAME <action>"
    echo "  action = docker command to run. eg start|stop|inspect"
fi

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

for container in $TDHLIST; do 

    ( docker $ACTION $container )
    
    rt=$?
    if [ $rt -ne 0 ]; then
        echo "Error in docker start for $container"
        break
    fi
done

exit $rt