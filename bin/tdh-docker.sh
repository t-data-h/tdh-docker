#!/bin/bash
#
#
PNAME=${0##*\/}
tdh_path=$(dirname "$(readlink -f "$0")")


usage()
{
    echo "Usage: tdh.sh [start|stop|status]"
}


while [ $# -gt 0 ]; do
    case "$1" in
        start)
            ( $tdh_path/tdh-run.sh start )
            ;;
        stop)
            ( $tdh_path/tdh-run.sh stop )
            ;;
        list|status)
            ( docker container list --all --filter name="tdh" )
            ;;
        *)
            usage
            ;;
    esac
    shift
done

exit 0
