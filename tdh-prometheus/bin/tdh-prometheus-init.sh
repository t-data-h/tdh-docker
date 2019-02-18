#!/bin/bash
#
# Prometheus Server
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

docker_image="prom/prometheus:v2.7.1"

name="tdh-prometheus1"
port="9091"
volname=
network=
res=
ACTION=

usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|pull"
    echo "   -h|--help             = Display usage and exit."
    echo "   -N|--network <name>   = Attach container to Docker bridge network"
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -p|--port <port>      = Local bind port for the container (default=${port})."
    echo "   -v|--volume <name>    = Optional volume name. Defaults to \$name-data"
    echo "   -V|--version          = Show version info and exit"
    echo ""
    echo "Any other action than 'run' results in a dry run."
    echo "The container will only start with the run or start action."
    echo "'pull' fetches the docker image:version from docker repo"
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
        -R|--rmhost)
            rmhost="$2"
            shift
            ;;
        -P|--rmport)
            rmport="$2"
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

volname="${name}-data1"

cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p ${port}:9091"
else
    network="host"
fi


cmd="$cmd --network ${network}"
cmd="$cmd --mount type=bind,src=${tdh_path}/../etc/prometheus.yml,dst=/etc/prometheus/prometheus.yml"
cmd="$cmd --mount type=volume,source=${volname},target=/prometheus-data ${docker_image}"
cmd="$cmd --web.listen-address=:9091 --config.file=/etc/prometheus/prometheus.yml"


echo ""
echo "  TDH Docker Container: '${name}'"
echo "  Docker Image: ${docker_image}"
echo "  Container Volume: '${volname}'"
echo "  Docker Network: ${network}"
echo "  Local port: ${port}"
echo ""


ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container '$name'"

    ( $cmd )
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
