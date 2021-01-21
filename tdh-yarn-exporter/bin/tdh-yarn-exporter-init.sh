#!/bin/bash
#
PNAME=${0##*\/}

image="pbweb/yarn-prometheus-exporter"
imagever="latest"
docker_image="${image}:${imagever}"

name="tdh-yarn-exporter1"
port="9113"
rmhost="localhost"
rmport="8088"
httpscheme="http"
metricpath="ws/v1/cluster/metrics"
network=
ACTION=

# -----------------------------------

usage="
Initializes a new YARN Prometheus Exporter container in docker.

Synopsis:
  $PNAME [options] run|pull

Options:
  -h|--help             = Display usage and exit.
  -n|--name <name>      = Name of the Docker Container instance.
  -N|--network <name>   = Attach container to Docker bridge network.
                          Default uses 'host' networking.
  -m|--metrics <path>   = Yarn URI path to metrics api.
                          Default is ''$metricpath'
  -p|--port <port>      = Local bind port for the container (default=${port}).
  -R|--rmhost <host>    = Hostname of the RM Master.
  -P|--rmport <port>    = Port number for the ResourceManager.
  -V|--version          = Show version info and exit.
  
Any other action than 'run' results in a dry run.
The container will only start with the run or start action.
The 'pull' command fetches the docker image:version
"

version="$PNAME :  Docker Image Version: ${docker_image}"

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
        -m|--metrics)
            metricpath="$2"
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

cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p ${port}:${port}"
else
    network="host"
fi

cmd="$cmd --network ${network}"
cmd="$cmd --env YARN_PROMETHEUS_LISTEN_ADDR=:${port} \
  --env YARN_PROMETHEUS_ENDPOINT_SCHEME=${httpscheme} \
  --env YARN_PROMETHEUS_ENDPOINT_HOST=${rmhost} \
  --env YARN_PROMETHEUS_ENDPOINT_PORT=${rmport} \
  --env YARN_PROMETHEUS_ENDPOINT_PATH=${path} \
  ${docker_image}"

echo "
  TDH Docker Container: '${name}'
  Docker Image: ${docker_image}
  YARN Endpoint: http://${rmhost}:${rmport}/$path
  Docker Network: ${network}
  Local port: ${port}
"

if [[ "$ACTION" == "run" || "$ACTION" == "start" ]]; then
    echo " -> Starting container $name"
    ( $cmd )
elif [ "$ACTION" == "pull" ]; then
    ( docker pull ${docker_image} )
else
    printf " <DRYRUN> - Command to execute: \n\n ( %s ) \n\n" $cmd
fi

rt=$?

if [ $rt -ne 0 ]; then
    echo "$PNAME ERROR in docker command."
fi

exit $rt
