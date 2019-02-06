#!/bin/bash
#
PNAME=${0##*\/}

namenode=
path=
port="50070"
fsimage="fsimage-$(date +%Y-%m-%d)"


usage()
{
    echo ""
    echo "Usage: $PNAME [options] <namenode>  <path>"
    echo "   -h|--help             = Display usage and exit."
    echo "   -p|--port <port>      = Namenode RPC Port (default=50070)"
    echo ""
}



while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -p|--port)
            port="$2"
            shift
            ;;
        *)
            namenode="$1"
            path="$2"
            shift
            ;;
    esac
    shift
done


if [ -z "$namenode" ] || [ -z "$path" ]; then
    echo " Error in usage." 
    usage
    exit 0
fi

if ! [ -d $path ]; then 
    echo "Invalid path"
    exit 1
fi


target="${path}/${namenode}"
image="${target}/${fsimage}"
csv="fsimage-${namenode}"

mkdir -p "$target"

# acquire the image
( curl -X GET "http://$namenode:${port}/imagetransfer?getimage1&txid=latest" --output $image )

# convert to csv
( hdfs oiv -p Delimited -delimiter "," -i $image -o $csv )

if [ -f $csv ]; then
    rm $image
fi

exit 0
