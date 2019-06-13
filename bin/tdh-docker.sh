#!/bin/bash
#
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")
prefix="tdh"

usage()
{
    echo "Usage: tdh.sh [start|stop|status]"
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
            ( $tdh_path/tdh-run.sh start )
            ;;
        stop)
            ( $tdh_path/tdh-run.sh stop )
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
