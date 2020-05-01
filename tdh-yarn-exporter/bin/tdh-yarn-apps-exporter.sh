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


usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|start"
    echo "   -h|--help             = Display usage and exit."
    echo "   -N|--network <name>   = Attach container to Docker network."
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -p|--port <port>      = Local bind port for the container (default=${port})."
    echo "   -R|--rmhost <host>    = Hostname of the RM Master."
    echo "   -P|--rmport <port>    = Port number for the ResourceManager."
    echo ""
    echo "Any other action than 'run|start' results in a dry run."
    echo "The container will only start with the run or start action"
    echo ""
}



# MAIN

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
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
    usage
fi

res=$?

if [ $res -ne 0 ]; then
    echo "Error in run for $PNAME"
fi

( $tdh_path/tdh-yarn-exporter-init.sh -n $name -p $port -R $rmhost -P $rmport -m $metricpath $ACTION )

exit $res
