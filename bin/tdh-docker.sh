#!/bin/bash
#  TDH Docker Container entry point for starting/stopping a group of containers
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

runscript="$tdh_path/tdh-docker-run.sh"
prefix="tdh"
version="v0.3.1"



usage()
{
    echo "Usage: $PNAME {--prefix <pfx>} [start|stop|status]"
}


version()
{
    echo "$PNAME: $version"
}


if [ $# -eq 0 ]; then
    usage
    exit 1
fi


while [ $# -gt 0 ]; do
    case "$1" in
        -p|--prefix)
            prefix="$2"
            shift
            ;;
        start)
            ( $runscript start )
            ;;
        stop)
            ( $runscript stop )
            ;;
        list|status)
            ( docker container list --all --filter name="$prefix" )
            ;;
        -V|--version)
            version
            exit 0
            ;;
        -h|--help)
            usage 
            exit 0
            ;;
        *)
            usage
            ;;
    esac
    shift
done

exit 0
