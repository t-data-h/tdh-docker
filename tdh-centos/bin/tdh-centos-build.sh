#!/bin/bash

tag="tdh"

if [ -n "$1" ]; then
    tag="$1"
fi

cmd="docker build"
cmd+=" --rm --tag $tag ."

echo "cmd: $cmd" 

( $cmd )

exit 0
