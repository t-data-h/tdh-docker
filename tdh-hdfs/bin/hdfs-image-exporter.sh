#!/bin/bash
#
# hdfs-image-exporter.sh
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

image="marcelmay/hadoop-hdfs-fsimage-exporter"
imagever="1.3"
docker_image="${image}:${imagever}"

name="tdh-hdfs-exporter1"
port="7772"
network=
res=
imagepath=
ACTION=

# -----------------------------------

usage="
Initializes a Docker container for the Prometheus HDFS Image Exporter.

Synopsis:
  $PNAME [options] run|pull

Options:
  -h|--help               = Show usage and exit.
  -i|--fsimagepath <path> = Local path to fsimage directory.
  -n|--name <name>        = Name of the Docker Container instance.
  -N|--network <name>     = Attach container to Docker bridge network
                            Default uses 'host' networking.
  -p|--port <port>        = Local bind port for the container (default=${port}).
  -V|--version            = Show version info and exit.

Any action other than 'run' results in a 'dry-run'.
The container will only start with the run action.
The 'pull' command fetches the docker image:version
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
        'help'|-h|--help)
            echo "$usage"
            exit 0
            ;;
        -i|--fsimagepath)
            imagepath="$2"
            shift
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
        'version'|-V|--version)
            echo "$version"
            exit 0
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

if [ "$ACTION" == "pull" ]; then
    ( docker pull $docker_image )
    exit $?
fi

if [ -z "$imagepath" ]; then
    echo "Error. --fsimagepath is required"
    exit 2
fi

if ! [ -d "$imagepath" ]; then
    echo "Image path is not a directory '$imagepath'"
    exit 2
fi


cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p ${port}:7772"
else
    network="host"
fi

cmd="$cmd --network ${network}"
cmd="$cmd --mount type=bind,src=${imagepath},dst=/fsimage-location"
cmd="$cmd ${docker_image}"

echo "
  TDH Docker Container: '${name}'
  Docker Image:  ${docker_image}
  Docker Network: ${network}
  Local port: ${port}
"

if [[ "$ACTION" == "run" || "$ACTION" == "start" ]]; then
    echo " - > Starting container '$name'"
    ( $cmd -e "JAVA_OPTS=-server -XX:+UseG1GC -Xmx1024m" )
    rt=$?
else
    printf "  <DRYRUN> - Command to execute: \n\n ( %s -e 'JAVA_OPTS=-server -XX:+UseG1GC -Xmx1024m' \n\n" $cmd
 fi

if [ $rt -ne 0 ]; then
    echo "$PNAME Error in docker command"
fi

exit $rt
