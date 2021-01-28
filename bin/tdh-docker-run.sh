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

usage="
Provides a wrapper to running the provided docker 'action' across containers.
as defined by the environment variable \$TDH_CONTAINERS

Synopsis:
  $PNAME <action> 
 
Where action is the docker command to run. 
  eg.  start|stop|restart|inspect
"


if [ -z "$ACTION" ]; then
    echo "$usage"
    exit 1
fi

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

case "$ACTION" in
'help'|-h|--help)
    echo "$usage"
    exit 0
    ;;
*)
    ;;
esac


for container in $TDHLIST; do
    ( docker $ACTION $container )

    rt=$?
    if [ $rt -ne 0 ]; then
        echo "Error in docker action for $container"
        break
    fi
done

exit $rt
