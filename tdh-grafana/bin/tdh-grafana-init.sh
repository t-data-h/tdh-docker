#!/bin/bash
#
#  tdh-grafana-init.sh
#
#   Initialize Grafana Daemon via Docker
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

docker_image="grafana/grafana:6.7.2"

name="tdh-grafana1"
port="3000"
network=
volname=
ACTION=


# -----------------------------------

usage="
Initializes a Grafana Server as a Docker container.

Synopsis:
  $PNAME [options] run|pull

Options:
  -h|--help            = Display usage and exit.
  -N|--network <name>  = Attach container to Docker network.
  -n|--name <name>     = Name of the Docker Container instance.
  -p|--port <port>     = Local bind port for the container.
  -V|--version         = Show version info and exit.

Any other action than 'run' results in a dry run.
The container will only start with the run action.
The 'pull' command fetches the docker image:version.
"

version="$PNAME : Docker Image Version:  ${docker_image}"

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
    cmd="$cmd -p ${port}:3000"
else
    network="host"
fi

cmd="$cmd --network ${network}"
cmd="$cmd --mount type=volume,source=${volname},target=/var/lib/grafana"
cmd="$cmd --env MYSQL_RANDOM_ROOT_PASSWORD=true"
cmd="$cmd --env GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource"
cmd="$cmd ${docker_image}"

echo "
  TDH Docker Container: '${name}'
  Docker Image:  ${docker_image}
  Container Volume: '${volname}'
  Docker Network: ${network}
  Local port: ${port}
"

if [[ $ACTION == "run" || $ACTION == "start" ]]; then
    echo " -> Starting container '$name'"
    ( $cmd )
elif [ $ACTION == "pull" ]; then
    ( docker pull ${docker_image} )
else
    echo "  <DRYRUN> - Command to run: "; echo ""
    echo "( $cmd )"
    echo ""
fi

rt=$?

if [ $rt -ne 0 ]; then
    echo "$PNAME ERROR in docker command"
    exit $rt
fi

exit $rt
