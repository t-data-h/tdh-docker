#!/bin/bash
#
# Prometheus Server
#
PNAME=${0##*\/}

tdh_path=$(dirname "$(readlink -f "$0")")
name=
port=
volname=
res=

usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|start"
    echo "   -h|--help             = Display usage and exit."
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -p|--port <port>      = Local bind port for the container."
    echo "   -v|--volume <name>    = Optional volume name. Defaults to \$name-data"
    echo " Any other action than 'run|start' results in a dry run."
    echo " The container will only start with the run or start action"
}


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

if [ -z "$name" ]; then
    name="tdh-prometheus1"
fi
if [ -z "$port" ]; then
    port=9091
fi

volname="${name}-data"

echo ""
echo "  TDH Docker Container: '$name'"
echo "  Container Volume Name: $volname"
echo "  Local port: $port"
echo ""

ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container '$name'"
    ( docker run --name $name -p ${port}:9090 -d \
      --mount "type=bind,src=${tdh_path}/../etc/prometheus.yml,dst=/etc/prometheus/prometheus.yml" \
      --mount "type=volume,source=$volname,target=/prometheus-data" \
      prom/prometheus )
else
    echo "  <DRYRUN> - Command to exec would be: "; echo ""
    echo "( docker run --name ${name} -p ${port}:9090 -d \\ "
    echo "  --mount type=bind,src=${tdh_path}/../etc/prometheus.yml,dst=/etc/prometheus/prometheus.yml \\ " 
    echo "  --mount type=volume,source=$volname,target=/prometheus-data \\ "
    echo "  prom/prometheus )"
    echo ""
 fi

res=$?

if [ $res -ne 0 ]; then
    echo "Error in run for $PNAME"
fi

exit $res
