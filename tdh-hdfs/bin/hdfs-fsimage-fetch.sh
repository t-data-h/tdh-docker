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

usage="
Acquires and converts the HDFS metadata image to CSV for 
import to Prometheus (or other) for reporting on HDFS metrics.

Synopsis:
  $PNAME [options]  <nn-host>  <path>

Options:
  -h|--help              = Display usage and exit.
  -p|--port <port>       = Namenode RPC Port (default=50070)
  -F|--fetch-only        = Only fetch the fsimage, do not convert.
  -R|--no-remove         = Do not remove fetched fsimage once converted.
  -T|--truststore <path> = Path to pem truststore, enables and use https.
"


## MAIN
rt=0

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "$usage"
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


if [[ -z "$namenode" || -z "$path" ]]; then
    echo " Error, required parameters missing." 
    echo "$usage"
    exit 1
fi

if ! [ -d $path ]; then 
    echo "Invalid path"
    exit 2
fi

fsimage="fsimage-${namenode}-${today}"
targetimage="${path}/${fsimage}"
csvpath="${path}/${namenode}"
targetcsv="${path}/${namenode}/${fsimage}.csv"

if [ -f "$targetcsv" ]; then
    echo "$PNAME Error, Target file exists, '$csv'.  Please remove first."
    exit 3
fi
if [ -f "$targetimage" ]; then
    echo "$PNAME Error, Target 'fsimage' exists, remove it first."
    exit 3
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
printf "\n ( %s ) \n" $cmd
( $cmd )
rt=$?

if [ $rt -eq 0 ]; then 
    echo " => FSImage acquired: $targetimage"
    if [ -n "$fetch" ]; then
        exit $rt
    fi
else
    echo " => Error in fsimage"
    exit $rt
fi

mkdir -p "$csvpath"

# convert image to csv
echo "" 
echo " ( hdfs oiv -p Delimited -delimiter ',' -i $targetimage -o $targetcsv )"
( hdfs oiv -p Delimited -delimiter "," -i $targetimage -o $targetcsv )
rt=$?

if [ $rt -eq 0 ]; then
    printf " \n => fsimage converted to csv: '$targetcsv' \n"
    if [[ -f $targetcsv && -z "$noremove" ]]; then
        echo " -> Removing fsimage..."
        rm $targetimage
    fi
fi

echo "$PNAME Finished."
exit $rt
