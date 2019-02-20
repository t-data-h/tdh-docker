#!/bin/bash
#
# hdfs-image-exporter.sh
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

docker_image="marcelmay/hadoop-hdfs-fsimage-exporter:1.2"

name="tdh-hdfs-exporter1"
port="9010"
network=
res=
imagepath=
ACTION=

usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|pull"
    echo "   -h|--help               = Display usage and exit."
    echo "   -i|--fsimagepath <path> = Local path to fsimage directory."
    echo "   -n|--name <name>        = Name of the Docker Container instance."
    echo "   -N|--network <name>     = Attach container to Docker bridge network"
    echo "                             Default uses 'host' networking."
    echo "   -p|--port <port>        = Local bind port for the container (default=${port})."
    echo "   -V|--version            = Show version info and exit"
    echo ""
    echo "  Any other action than 'run' results in a dry run."
    echo "  The container will only start with the run action."
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

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "pull" ]; then
    ( docker pull $docker_image )
    exit 0
fi

if [ -z "$fsimagepath" ]; then
    echo "Error. --fsimagepath is required"
    exit 1
fi

if ! [ -d "$fsimagepath" ]; then
    echo "Image path is not a directory '$fsimagepath'"
    exit 1
fi


cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p ${port}:9010"
else
    network="host"
fi


cmd="$cmd --network ${network}"
cmd="$cmd --mount type=bind,src=${fsimagepath},dst=/fsimage-location"
cmd="$cmd ${docker_image}"


echo ""
echo "  TDH Docker Container: '${name}'"
echo "  Docker Image:  ${docker_image}"
echo "  Docker Network: ${network}"
echo "  Local port: ${port}"
echo ""


if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container '$name'"

    ( $cmd -e "JAVA_OPTS=-server -XX:+UseG1GC -Xmx1024m" )
else
    echo "  <DRYRUN> - Command to execute: "
    echo ""
    echo "$cmd -e \"JAVA_OPTS=-server -XX:+UseG1GC -Xmx1024m\" "
    echo ""
 fi

res=$?

if [ $res -ne 0 ]; then
    echo "Error in run for $PNAME"
fi

exit $res
