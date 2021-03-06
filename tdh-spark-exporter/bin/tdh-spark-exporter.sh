#!/bin/bash
#
#  Initialize the spark-exporter container
#
#  --conf spark.metrics.conf=/etc/spark2/conf/graphite.properties
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

image="prom/graphite-exporter"
imagever="v0.7.0"
docker_image="${image}/${imagever}"

name="tdh-spark-exporter1"
port="9109"
network=
ACTION=

# -----------------------------------

usage="
Initializes a Prometheus Graphite Exporter for Spark as a Docker container.

Synopsis:
  $PNAME [options] run|pull

Options:
  -h|--help            = Show usage and exit.
  -n|--name <name>     = Name of the Docker Container instance.
  -N|--network <name>  = Attach container to Docker bridge network.
                         Default is to use 'host' networking.
  -V|--version         = Show version info and exit.
 
Any action other than 'run' results in a 'dry-run'.
The container will only start with the run or start action.
The 'pull' command fetches the docker image:version
"

version="$PNAME : Docker Image Version: ${docker_image}"

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
        echo " -> Attaching container to existing network '$net'"
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
            exit $rt
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
            echo "$version"
            exit $rt
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


echo "
  TDH Docker Container: '${name}'
  Docker Image: ${docker_image}
  Docker Network: ${network}
  Local port: ${port}
"

if [[ $ACTION == "run" || $ACTION == "start" ]]; then
    echo " -> Starting container '$name'"
    ( $cmd )
elif [ $ACTION == "pull" ]; then
    ( docker pull ${docker_image} )
else
    printf "  <DRYRUN> - Command to execute: \n\n ( %s ) \n\n" $cmd
 fi

rt=$?

if [ $rt -ne 0 ]; then
    echo "$PNAME Error in docker command"
fi

exit $rt
