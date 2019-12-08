	#!/usr/bin/env bash

# make sure we're always in the correct directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

# check if we have lazbuild present
lbpath=$(which lazbuild)

if [[ -x "$lbpath" ]]; then
	echo "lazbuild present"
else
	echo "Could not find lazbuild. Make sure it is in your PATH."
	exit
fi

# compile setup
lazbuild setup.lpi

if [ $? -eq 0 ]; then
    # run setup
   ./setup $@
fi
