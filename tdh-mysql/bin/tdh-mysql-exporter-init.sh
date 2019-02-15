#!/bin/bash
#
PNAME=${0##*\/}

name="tdh-mysql-exporter1"
port="9104"
myhost="localhost"
myport="3306"
myuser="exporter"
mypass=
network=
res=
ACTION=


usage()
{
    echo ""
    echo "Usage: $PNAME [options] run|start"
    echo "   -h|--help              = Display usage and exit."
    echo "   -N|--network <name>    = Attach container to Docker bridge network"
    echo "                            Default uses 'host' networking."
    echo "   -n|--name <name>       = Name of the Docker Container instance."
    echo "   -p|--port <port>       = Local bind port for the container (default=${port})."
    echo "   -H|--mysql-host <host> = Hostname of the mysql server."
    echo "   -P|--mysql-port <port> = Port number for the mysql server"
    echo "   -u|--mysql-user <user> = Mysql user"
    echo "   -w|--mysql-pass <pw>   = Mysql password"
    echo ""
    echo "Any other action than 'run|start' results in a dry run."
    echo "The container will only start with the run or start action"
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
        echo "Attaching container to existing network '$net'"
    fi

    return 0
}


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
        -H|--mysql-host)
            myhost="$2"
            shift
            ;;
        -P|--mysql-port)
            myport="$2"
            shift 
            ;;
        -u|--mysql-user)
            myuser="$2"
            shift
            ;;
        -w|--mysql-pass)
            mypass="$2"
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

if [ -z "$mypass" ]; then
    echo "Mysql password required"
    exit 1
fi

cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p ${port}:9113"
else
    network="host"
fi

cmd="$cmd --network ${network}"


cmd="$cmd -e DATA_SOURCE_NAME='${myuser}:${mypass}@(${myhost}:${myport})/' \
prom/mysqld-exporter"


echo ""
echo "  TDH Docker Container: '$name'"
echo "  MySQL Endpoint: ${myuser}@${myhost}:${myport}/$path"
echo "  Network: $network"
echo "  Local port: $port"
echo ""


ACTION=$(echo $ACTION | tr [:upper:] [:lower:])

if [ "$ACTION" == "run" ] || [ "$ACTION" == "start" ]; then
    echo "Starting container $name"

    ( $cmd )
else
    echo "  <DRYRUN> - Command to execute: "
    echo ""
    echo " ( $cmd ) " 
    echo ""
fi

res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in run for $PNAME"
fi

exit $res
