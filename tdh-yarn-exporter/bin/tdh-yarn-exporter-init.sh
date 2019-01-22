#!/bin/bash
#
PNAME=${0##*\/}

name="tdh-yarn-exporter1"
port="9113"
rmhost="localhost"
rmport="8088"
path="ws/v1/cluster/metrics"
network=
res=
ACTION=


usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|start"
    echo "   -h|--help             = Display usage and exit."
    echo "   -N|--network <name>   = Attach container to Docker network"
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -p|--port <port>      = Local bind port for the container."
    echo "   -R|--rmhost <host>    = Hostname of the RM Master."
    echo "   -P|--rmport <port>    = Port number for the ResourceManager"
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
    cmd="$cmd -p ${port}:9113"
else
    network="host"
fi

cmd="$cmd --network ${network}"


cmd="$cmd --env YARN_PROMETHEUS_LISTEN_ADDR=:9113 \
--env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \
--env YARN_PROMETHEUS_ENDPOINT_HOST=$rmhost \
--env YARN_PROMETHEUS_ENDPOINT_PORT=$rmport \
--env YARN_PROMETHEUS_ENDPOINT_PATH=$path \
pbweb/yarn-prometheus-exporter"


echo ""
echo "  TDH Docker Container: '$name'"
echo "  YARN Endpoint: http://${rmhost}:${rmport}/$path"
echo "  Network: $network"
echo "  Local port: $port"
echo ""


ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container $name"

    ( $cmd )
else
    echo "  <DRYRUN> - Command to run: "
    echo ""
    echo " ( $cmd ) " 
    echo ""
fi

res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in run for $PNAME"
fi

exit $res
