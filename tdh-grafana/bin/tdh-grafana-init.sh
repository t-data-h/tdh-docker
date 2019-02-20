#!/bin/bash
#
#  tdh-grafana-init.sh
#
#   Initialize Grafana Daemon via Docker
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

docker_image="grafana/grafana:5.4.3"

name="tdh-grafana1"
port="3000"
network=
volname=
res=
ACTION=



usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|pull"
    echo "   -h|--help            = Display usage and exit."
    echo "   -N|--network <name>  = Attach container to Docker network"
    echo "   -n|--name <name>     = Name of the Docker Container instance."
    echo "   -p|--port <port>     = Local bind port for the container."
    echo "   -V|--version         = Show version info and exit"
    echo ""
    echo "  Any other action than 'run' results in a dry run."
    echo "  The container will only start with the run action"
    echo "  The 'pull' command fetches the docker image:version"
    echo ""
}

version()
{
    echo ""
    echo "$PNAME "
    echo "  Docker Image Version:  ${docker_image}"
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
    cmd="$cmd -p ${port}:3000"
else
    network="host"
fi

cmd="$cmd --network ${network}"
cmd="$cmd --mount type=volume,source=${volname},target=/var/lib/grafana"
cmd="$cmd --env MYSQL_RANDOM_ROOT_PASSWORD=true"
cmd="$cmd --env GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource"
cmd="$cmd ${docker_image}"


echo ""
echo "  TDH Docker Container: '${name}'"
echo "  Docker Image:  ${docker_image}"
echo "  Container Volume: '${volname}'"
echo "  Docker Network: ${network}"
echo "  Local port: ${port}"
echo ""

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container '$name'"

    ( $cmd )
elif [ "$ACTION" == "pull" ]; then
    ( docker pull ${docker_image} )
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
