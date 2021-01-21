#!/bin/bash
#
PNAME=${0##*\/}

tdh_path=$(dirname "$(readlink -f "$0")")
name="tdh-yarnapps-exporter1"
port="9114"
rmhost="localhost"
rmport="8088"
metricpath="ws/v1/cluster/apps?state=running"
network=
res=
ACTION=


usage="
Synopsis:
  $PNAME [options] run|start

Options:
   -h|--help             = Display usage and exit.
   -N|--network <name>   = Attach container to Docker network.
   -n|--name <name>      = Name of the Docker Container instance.
   -p|--port <port>      = Local bind port for the container (default=${port}).
   -R|--rmhost <host>    = Hostname of the RM Master.
   -P|--rmport <port>    = Port number for the ResourceManager.
 
Any action other than 'run|start' results in a dry run.
"


# MAIN

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "$usage"
            exit 0
            ;;
        -N|--network)
            network="$2"
            shift
            ;;
        -n|--name)
            name="$2"
            shift
            ;;
        -p|--port)
            port="$2"
            shift
            ;;
        -R|--rmhost)
            rmhost="$2"
            shift
            ;;
        -P|--rmport)
            rmport="$2"
            shift
            ;;
        *)
            ACTION="${1,,}"
            shift
            ;;
    esac
    shift
done

if [ -z "$ACTION" ]; then
    echo "$usage"
    exit 0
fi

res=$?

if [ $res -ne 0 ]; then
    echo "Error in run for $PNAME"
fi

( $tdh_path/tdh-yarn-exporter-init.sh -n $name -p $port -R $rmhost -P $rmport -m $metricpath $ACTION )

exit $res
