#!/bin/bash
#  TDH Docker Container entry point for starting/stopping a group of containers
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

runscript="$tdh_path/tdh-docker-run.sh"
prefix="tdh"
vers="v21.01"

usage="Usage: $PNAME {--prefix <pfx>} [start|stop|status]"
version="$PNAME: $vers"


if [ $# -eq 0 ]; then
    echo "$usage"
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
        list|--list|status)
            ( docker container list --all --filter name="$prefix" )
            ;;
        'version'|-V|--version)
            echo "$version"
            exit 0
            ;;
        'help'|-h|--help)
            echo "$usage" 
            exit 0
            ;;
        *)
            echo "$usage"
            ;;
    esac
    shift
done

exit 0
