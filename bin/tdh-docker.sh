#!/bin/bash
#
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")
prefix="tdh"
runscript="$tdh_path/tdh-docker-run.sh"

usage()
{
    echo "Usage: $PNAME [start|stop|status]"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)
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
        *)
            usage
            ;;
    esac
    shift
done

exit 0
