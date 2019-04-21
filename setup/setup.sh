#!/usr/bin/env bash

# make sure we're always in the correct directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

# compile setup
lazbuild setup.lpi

if [ $? -eq 0 ]; then
    # run setup
   ./setup $@
fi
