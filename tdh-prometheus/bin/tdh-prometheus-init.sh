#!/bin/bash
#
# Prometheus Server
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

image="prom/prometheus"
imagever="v2.17.1"
docker_image="${image}:${imagever}"

name="tdh-prometheus1"
port="9091"
volname=
network=
ACTION=

# -----------------------------------

usage="
Initializes a Prometheus Server as a docker container.

Synopsis:
  $PNAME [options] run|pull

Options:
  -h|--help            = Display usage and exit.
  -N|--network <name>  = Attach container to Docker bridge network
  -n|--name <name>     = Name of the Docker Container instance.
  -p|--port <port>     = Local bind port for the container (default=${port}).
  -v|--volume <name>   = Optional volume name. Defaults to $name-data1
  -V|--version         = Show version info and exit

Any action other than 'run' results in a 'dry-run'.
The container will only start with the run or start action.
The 'pull' command fetches the docker image:version
"

version="$PNAME : Docker Image: ${docker_image}"

# -----------------------------------

validate_network()
{
    local net="$1"
    local res=

    res=$( docker network ls | awk '{print $2 }' | grep "$net" )

    if [ -z "$res" ]; then
        echo " -> Creating bridge network: $net"
        ( docker network create --driver bridge $net )
    else
        echo " -> Attaching container to bridge network '$net'"
    fi

    return 0
}


# -----------------------------------
# MAIN
rt=0

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "$usage"
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
            echo "$version"
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
    echo "$usage"
    exit 1
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

echo "
  TDH Docker Container: '${name}'
  Docker Image: ${docker_image}
  Container Volume: '${volname}'
  Docker Network: ${network}
  Local port: ${port}
"

if [[ $ACTION == "run" || $ACTION == "start" ]]; then
    echo " -> Starting container '$name'"
    ( $cmd )
elif [ $ACTION == "pull" ]; then
    ( docker pull $docker_image )
else
    printf "  <DRYRUN> - Command to execute: \n]n ( %s ) \n\n" $cmd
 fi

rt=$?

if [ $rt -ne 0 ]; then
    echo "$PNAME Error in docker command"
fi

exit $rt
