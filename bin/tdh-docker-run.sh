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

usage()
{
    printf "\n"
    printf "Usage: $PNAME <actions> \n"
    printf "\n"
    printf "  Runs the provided action on all tdh containers as defined by \$TDH_CONTAINERS \n"
    printf "  where action is the docker command to run. eg start|stop|restart|inspect \n"
    printf "\n"
}

if [ -z "$ACTION" ]; then
    usage
    exit 1
fi

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

case "$ACTION" in
'help'|-h|--help)
    usage
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
