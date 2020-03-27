#!/bin/bash
#
# Prometheus Server
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

docker_image="danielqsj/kafka-exporter:latest"

name="tdh-kafka-exporter1"
port="9108"
brokers=
network=
res=
ACTION=

usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|pull"
    echo "   -h|--help             = Display usage and exit."
    echo "   -b|--brokers          = List of Kafka Brokers 'broker1:9092,broker2:9092'"
    echo "   -N|--network <name>   = Attach container to Docker bridge network"
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -p|--port <port>      = Local bind port for the container (default=${port})."
    echo "   -V|--version          = Show version info and exit"
    echo ""
    echo "  Any other action than 'run' results in a dry run."
    echo "  The container will only start with the run or start action."
    echo "  The 'pull' command fetches the docker image:version"
    echo ""
}


version()
{
    echo ""
    echo "$PNAME"
    echo "  Docker Image Version: ${docker_image}"
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
        echo "Attaching container to bridge network '$net'"
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
        -n|--name)
            name="$2"
            shift
            ;;
        -N|--network)
            network="$2"
            shift
            ;;
        -p|--port)
            port="$2"
            shift
            ;;
        -b|--brokers)
            brokers="$2"
            shift
            ;;
        -V|--version)
            version
            exit 0
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

if [ -z "$brokers" ]; then
    echo "Error, Brokers are not defined!"
    exit 1
fi

brokers=$(echo $brokers | sed 's/\,/ /g')

cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p ${port}:9091"
else
    network="host"
fi

# docker run -ti --rm -p 9308:9308 danielqsj/kafka-exporter --kafka.server=kafka:9092 [--kafka.server=another-server ...]

cmd="$cmd --network ${network} -p $port:$port"

for broker in $brokers; do
    cmd="$cmd --kafka.server=$broker"
done

echo ""
echo "  TDH Docker Container: '${name}'"
echo "  Docker Image: ${docker_image}"
echo "  Container Volume: '${volname}'"
echo "  Docker Network: ${network}"
echo "  Local port: ${port}"
echo ""


if [ $ACTION == "run" ] || [ $ACTION == "start" ]; then
    echo "Starting container '$name'"

    ( $cmd )
elif [ $ACTION == "pull" ]; then
    ( docker pull $docker_image )
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
