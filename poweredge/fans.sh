#!/bin/bash

# ==============================================================================
# Dell PowerEdge fan control script
# Requires ipmitool to be installed, tested on R720
# Author: Alex Sobiek
# ==============================================================================

SCRIPT_NAME=$(basename $0)

set() {
    # ipmitool has a raw command built in, but it complains about the command being invalid
    # this is a dirty work around to pipe the command to the shell silently. 
    echo "raw $@" | ipmitool shell 1> /dev/null
}

auto() {
    set 0x30 0x30 0x01 0x01             # Set auto fan control
    echo "Set fans to automatic"
}

manual() {
    set 0x30 0x30 0x01 0x00             # Set manual fan control
    echo "Warning: fans are no longer in auto mode, use \"$SCRIPT_NAME auto\" to set it back"
}

value() {
    manual
    set 0x30 0x30 0x02 0xFF $1         # Set fans to value
    echo "Set fans to $1"
}

help() {
    echo "Usage: $SCRIPT_NAME <auto|manual|0-100>"
    exit 1
}


if [[ -n "$1" ]]; then                          # Check if we have a first parameter
    if [[ $(type -t $@) == function ]]; then    # Check if the first parameter is a function
        $@                                      # Call the function
    elif (( $1 >= 0 && $1 <= 100)); then        # Check if the first parameter is a number between 2 and 100
        value '0x'$(printf "%x" $1)             # Convert to hex and set the fans to the given percentage
    else
        help
    fi
else
    help
fi