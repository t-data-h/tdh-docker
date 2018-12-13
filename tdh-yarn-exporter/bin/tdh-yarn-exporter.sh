#!/bin/bash
#
PNAME=${0##*\/}

name=
port=
rmhost=
rmport=
res=

usage()
{
    echo ""
    echo "Usage: $PNAME [options] <run>"
    echo "   -h|--help             = Display usage and exit."
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -p|--port <port>      = Local bind port for the container."
    echo "   -R|--rmhost <host>    = Hostname of the RM Master."
    echo "   -P|--rmport <port>    = Port number for the ResourceManager"
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
            name="$1"
            shift
            ;;
        -p|--port)
            port="$1"
            shift
            ;;
        -R|--rmhost)
            rmhost="$1"
            shift
            ;;
        -P|--rmport)
            rmport="$1"
            shift 
            ;;
        *)
            ACTION="$1"
            shift
            ;;
    esac
    shift
done


if [ -z "$name" ]; then
    name="tdh-yarn-exporter1"
fi

if [ -z "$port" ]; then
    port=9113
fi

if [ -z "$rmhost" ]; then
    rmhost=localhost
fi

if [ -z "$rmport" ]; then
    rmport=8050
fi

echo ""
echo "Container '$name' "
echo "  YARN Endpoint set to http://${rmhost}:${rmport}"

if [ "$ACTION" == "run" ]; then
    echo "Starting container $name"
    ( docker run --name ${name} -p ${port}:9113 -d \
      --env YARN_PROMETHEUS_LISTEN_ADDR=:9113 \
      --env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \
      --env YARN_PROMETHEUS_ENDPOINT_HOST=$rmhost \
      --env YARN_PROMETHEUS_ENDPOINT_PORT=$rmport \
      --env YARN_PROMETHEUS_ENDPOINT_PATH="ws/v1/cluster/metrics" \
      pbweb/yarn-prometheus-exporter )
else
    echo ""
    echo "Dry Run - Command would be: "
    echo "docker run --name ${name} -p ${port}:9113 -d \\ "
    echo "  --env YARN_PROMETHEUS_LISTEN_ADDR=:9113 \\ "
    echo "  --env YARN_PROMETHEUS_ENDPOINT_SCHEME=http \\ "
    echo "  --env YARN_PROMETHEUS_ENDPOINT_HOST=$rmhost \\ "
    echo "  --env YARN_PROMETHEUS_ENDPOINT_PORT=$rmport \\ "
    echo "  --env YARN_PROMETHEUS_ENDPOINT_PATH=ws/v1/cluster/metrics \\ "
    echo "  pbweb/yarn-prometheus-exporter "
    echo ""
fi

res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in run for $PNAME"
fi

exit $res
