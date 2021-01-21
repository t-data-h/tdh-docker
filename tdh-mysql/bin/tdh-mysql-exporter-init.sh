#!/bin/bash
#
#  Initialize a docker container for the Prometheus Mysql exporter
#
PNAME=${0##*\/}

docker_image="prom/mysqld-exporter:v0.11.0"

name="tdh-mysql-exporter1"
port="9104"
myhost="localhost"
myport="3306"
myuser="exporter"
mypass=
network=
res=
ACTION=


usage="
Initializes a Prometheus 'MySQL' Exporter as a docker container.

Synopsis:
  $PNAME [options] run|pull

Options:
  -h|--help              = Display usage and exit.
  -n|--name <name>       = Name of the Docker Container instance.
  -N|--network <name>    = Attach container to Docker bridge network
                           Default uses 'host' networking.
  -p|--port <port>       = Local bind port for the container (default=${port}).
  -H|--mysql-host <host> = Hostname of the mysql server.
  -P|--mysql-port <port> = Port number for the mysql server
  -u|--mysql-user <user> = MySQL user (default = exporter)
  -w|--mysql-pass <pw>   = MySQL password
  -V|--version           = Show version info and exit.

Any other action than 'run' results in a dry run.
The container will only start with the run or start action
The 'pull' command fetches the docker image:version
"
version="$PNAME : Docker Image Version: ${docker_image}"


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

if [ $ACTION == "pull" ]; then
    ( docker pull ${docker_image} )
    exit 0
fi

if [ -z "$mypass" ]; then
    echo "MySQL password required"
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
cmd="$cmd -e DATA_SOURCE_NAME='${myuser}:${mypass}@(${myhost}:${myport})/' ${docker_image}"


echo "
  TDH Docker Container: '${name}'
  Docker Image: ${docker_image}
  MySQL Endpoint: ${myuser}@${myhost}:${myport}/$path
  Docker Network: ${network}
  Local port: ${port}
"

if [[ $ACTION == "run" || $ACTION == "start" ]]; then
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
