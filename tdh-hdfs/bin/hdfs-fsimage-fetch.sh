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
fsimage=
noremove=
fetch=
truststore=
cmd=
res=



usage()
{
    echo ""
    echo "Usage: $PNAME [options]  <nn-host>  <path>"
    echo "   -h|--help              = Display usage and exit."
    echo "   -p|--port <port>       = Namenode RPC Port (default=50070)"
    echo "   -F|--fetch-only        = Only fetch the fsimage, do not convert."
    echo "   -R|--no-remove         = Do not remove fetched fsimage once converted."
    echo "   -T|--truststore <path> = Path to pem truststore, enables and use https."
    echo ""
}


## OPTIONS

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
        -F|--fetch-only)
            fetch="true"
            ;;
        -R|--no-remove)
            noremove="true"
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


## MAIN
# 

res=
cmd=
fsimage="fsimage-${namenode}-${today}"
targetimage="${path}/${fsimage}"
csvpath="${path}/${namenode}"
targetcsv="${path}/${namenode}/${fsimage}.csv"


if [ -f "$targetcsv" ]; then
    echo " => Target file exists, '$csv'.  Please remove first."
    exit 1
fi
if [ -f "$targetimage" ]; then
    echo " => Target fsimage exists, remove it first."
    exit 1
fi


# construct our curl cmd
cmd="curl -X GET"
if [ -n "$truststore" ]; then
    cmd="$cmd --cacert \"${truststore}\" https://"
else
    cmd="$cmd http://"
fi
cmd="${cmd}${namenode}:${port}/imagetransfer?getimage=1&txid=latest"
cmd="$cmd --output $targetimage"


# acquire the image
echo ""
echo " ( $cmd )" 
( $cmd )
res=$?

echo ""
if [ $res -eq 0 ]; then 
    echo " => FSImage acquired: $targetimage"
    if [ -n "$fetch" ]; then
        exit $res
    fi
else
    echo " => Error in fsimage"
    exit $res
fi

mkdir -p "$csvpath"

# convert image to csv
echo "" 
echo " ( hdfs oiv -p Delimited -delimiter ',' -i $targetimage -o $targetcsv )"
( hdfs oiv -p Delimited -delimiter "," -i $targetimage -o $targetcsv )
res=$?

if [ $res -eq 0 ]; then
    echo ""
    echo " => fsimage converted to csv: '$targetcsv'"
    if [ -f $targetcsv ] && [ -z "$noremove" ]; then
        echo "Removing fsimage..."
        rm $targetimage
    fi
fi

echo "Finished."
exit 0
