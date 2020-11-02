#!/bin/bash
#  TDH Docker Container entry point for starting/stopping a group of containers
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")

runscript="$tdh_path/tdh-docker-run.sh"
prefix="tdh"
version="v20.09"



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
        list|--list|status)
            ( docker container list --all --filter name="$prefix" )
            ;;
        'version'|-V|--version)
            version
            exit 0
            ;;
        'help'|-h|--help)
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
