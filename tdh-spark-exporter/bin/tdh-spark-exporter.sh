#!/bin/bash
#
#  Initialize the spark-exporter container
#
#  --conf spark.metrics.conf=/etc/spark2/conf/graphite.properties
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

docker_image="prom/graphite-exporter:v0.4.2"

name="tdh-spark-exporter1"
port="9109"
network=
res=
ACTION=



usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|start"
    echo "   -h|--help             = Display usage and exit."
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -N|--network <name>   = Attach container to Docker bridge network."
    echo "                           Default is to use 'host' networking."
    echo "   -V|--version          = Show version info and exit."
    echo ""
    echo "Any other action than 'run|start' results in a dry run."
    echo "The container will only start with the run or start action"
    echo ""
}

version()
{
    echo ""
    echo "$PNAME - Docker Image Version:"
    echo "  ${docker_image}"
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


while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--name)
            name="$2"
            shift
            ;;
        -N|--network)
            network="$2"
            shift
            ;;
        -V|--version)
            version
            exit 0
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

cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p 9108:9108 -p $port:9109 -p $port:9109/udp"
else 
    network="host"
fi

cmd="$cmd --network ${network}"
cmd="$cmd --mount type=bind,src=${tdh_path}/../etc/graphite_mapping.conf,dst=/tmp/graphite_mapping.conf"
cmd="$cmd ${docker_image} --graphite.mapping-config=/tmp/graphite_mapping.conf" 


echo ""
echo "  TDH Docker Container: '$name'"
echo "  Network: $network"
echo "  Local port: $port"
echo ""


ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container '$name'"

    ( $cmd )
elif [ "$ACTION" == "pull" ]; then
    ( docker pull ${docker_image} )
else
    echo "  <DRYRUN> - Command to execute: "
    echo ""
    echo "$cmd"
    echo ""
 fi

res=$?

if [ $res -ne 0 ]; then
    echo "Error in run for $PNAME"
fi

exit $res
