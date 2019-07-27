#!/bin/bash
#  TDH Docker Container entry point for starting/stopping containers
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")
prefix="tdh"
runscript="$tdh_path/tdh-docker-run.sh"
version="v0.2.9"

usage()
{
    echo "Usage: $PNAME [start|stop|status]"
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
        *)
            usage
            ;;
    esac
    shift
done

exit 0
