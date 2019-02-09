PNAME=${0##*\/}

tdh_path=$(dirname "$(readlink -f "$0")")
name="tdh-hdfs-exporter1"
port="9010"
network=
res=
imagepath=
ACTION=

usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|start"
    echo "   -h|--help             = Display usage and exit."
    echo "   -N|--network <name>   = Attach container to Docker bridge network"
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -i|--imagepath <path> = Local path to fsimage directory."
    echo "   -p|--port <port>      = Local bind port for the container (default=${port})."
    echo "   -v|--volume <name>    = Optional volume name. Defaults to \$name-data"
    echo ""
    echo "Any other action than 'run|start' results in a dry run."
    echo "The container will only start with the run or start action."
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
        -i|--imagepath)
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

if [ -z "$imagepath" ]; then
    echo "Error. --imagepath is required"
    exit 1
fi

if ! [ -d "$imagepath" ]; then
    echo "Image path is not a directory '$imagepath'"
    exit 1
fi


cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p ${port}:9010"
else
    network="host"
fi


#-e "JAVA_OPTS=-server -XX:+UseG1GC -Xmx1024m"

cmd="$cmd --network ${network}"
cmd="$cmd --mount type=bind,src=${imagepath},dst=/fsimage-location"
cmd="$cmd --env \"JAVA_OPTS=-server -XX:+UseG1GC -Xmx1024m\""
cmd="$cmd marcelmay/hadoop-hdfs-fsimage-exporter"


echo ""
echo "  TDH Docker Container: '$name'"
echo "  Container Volume Name: '$volname'"
echo "  Network: $network"
echo "  Local port: $port"
echo ""


ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container '$name'"

    ( $cmd )
else
    echo "  <DRYRUN> - Command to run: "
    echo ""
    echo "$cmd"
    echo ""
 fi

res=$?

if [ $res -ne 0 ]; then
    echo "Error in run for $PNAME"
fi

exit $res
