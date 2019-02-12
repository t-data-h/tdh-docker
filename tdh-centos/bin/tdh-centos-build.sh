#!/bin/bash
#
# build script

tag="tdh-centos7"
res=

if [ -n "$1" ]; then
    tag="$1"
fi

cmd="docker build"
cmd+=" --rm --tag $tag ."

echo "( $cmd )" 

( $cmd )

res=$?

exit $res

