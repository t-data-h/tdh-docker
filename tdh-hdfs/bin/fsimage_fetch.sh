#!/bin/bash
#
# fsimage_fetch.sh - Acquires and converts the HDFS metadata image to csv
#   for import to Prometheus or other reporting
#
PNAME=${0##*\/}

namenode=
path=
port="50070"
today=$(date +%Y-%m-%d)
fsimage="fsimage-${today}"
noremove=
truststore=
cmd=
res=



usage()
{
    echo ""
    echo "Usage: $PNAME [options]  <namenode>  <path>"
    echo "   -h|--help              = Display usage and exit."
    echo "   -p|--port <port>       = Namenode RPC Port (default=50070)"
    echo "   -R|--no-remove         = Do not remove fetched fsimage once converted."
    echo "   -T|--truststore <path> = Path to pem truststore, enables and use https."
    echo ""
}


## MAIN

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
        -R|--no-remove)
            noremove=1
            ;;
        -T|--truststore)
            truststore="$2"
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

res=
cmd=
target="${path}/${namenode}"
image="${target}/${fsimage}"
csv="${target}/fsimage-${namenode}-${today}.csv"


if [ -f $csv ]; then
    echo " => Target file exists, '$csv'.  Please remove first."
    exit 1
fi
if [ -f $image ]; then
    echo " => Target fsimage exists, remove it first."
    exit 1
fi

mkdir -p "$target"


# construct our curl cmd
cmd="curl -X GET"
if [ -n "$truststore" ]; then
    cmd="$cmd --cacert \"${truststore}\" https://"
else
    cmd="$cmd http://"
fi
cmd="${cmd}${namenode}:${port}/imagetransfer?getimage=1&txid=latest"
cmd="$cmd --output $image"


# acquire the image
echo ""
echo " ( $cmd )" 
( $cmd )
res=$?

echo ""
if [ $res -eq 0 ]; then 
    echo " => FSImage acquired: $image"
else
    echo " => Error in fsimage"
    exit $res
fi


# convert image to csv
echo "" 
echo " ( hdfs oiv -p Delimited -delimiter ',' -i $image -o $csv )"
( hdfs oiv -p Delimited -delimiter "," -i $image -o $csv )
res=$?

if [ $res -eq 0 ]; then
    echo ""
    echo " => fsimage converted to csv: '$csv'"
    if [ -f $csv ] && [ -z "$noremove" ]; then
        rm $image
    fi
fi

echo "Finished."
exit 0
