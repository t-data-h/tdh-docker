#!/bin/bash
#
#  tdh-grafana-init.sh
#
#   Initialize Grafana Daemon via Docker
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")
name="tdh-grafana1"
port="3000"
network=
volname=
res=
ACTION=

grafana_version="5.4.2"


usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|start"
    echo "   -h|--help            = Display usage and exit."
    echo "   -N|--network <name>  = Attach container to Docker network"
    echo "   -n|--name <name>     = Name of the Docker Container instance."
    echo "   -p|--port <port>     = Local bind port for the container."
    echo ""
    echo "Any other action than 'run|start' results in a dry run."
    echo "The container will only start with the run or start action"
    echo ""
}


validate_network()
{
    local net="$1"
    local res=

    res=$( docker network ls | awk '{print $2 }' | grep "$net" )

    if [ -z "$res" ]; then
        echo "Creating bridge network: $net"
        ( docker network create --driver bridge $net )
    else
        echo "Attaching container to existing network '$net'"
    fi

    return 0
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
        *)
            ACTION="$1"
            shift
            ;;
    esac
    shift
done

if [ -z "$ACTION" ]; then 
    usage
fi

volname="${name}-data1"

cmd="docker run --name $name -p $port:3000 -d"

if [ -n "$network" ]; then 
    validate_network "$network"
    cmd="$cmd --network $network"
fi


cmd="$cmd \
--mount \"type=volume,source=${volname},target=/var/lib/grafana\" \
--env MYSQL_RANDOM_ROOT_PASSWORD=true \
--env "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" \
grafana/grafana:${grafana_version}"


echo ""
echo "  TDH Docker Container: '$name'"
echo "  Container Volume Name: $volname"
echo "  Local port: $port"
echo "" 

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container '$name'"

    ( $cmd )

else
    echo "  <DRYRUN> - Command to run: "; echo ""
    echo "( $cmd )"
    echo ""
fi

res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in run for $PNAME"
    exit $res
fi

exit $res