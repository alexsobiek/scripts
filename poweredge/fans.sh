#!/bin/bash

# ==============================================================================
# Dell PowerEdge fan control script
# Requires ipmitool to be installed, tested on R720
# Author: Alex Sobiek
# ==============================================================================

SCRIPT_NAME=$(basename $0)

INT_REGEX="^-?[0-9]+$"
FLOAT_REGEX="^[0-9]+([.][0-9]+)?$"

raw() {
    ipmitool raw $@ 1> /dev/null
}

auto() {
    raw 0x30 0x30 0x01 0x01                 # Set auto fan control
    echo "Set fans to automatic"
}

manual() {
    raw 0x30 0x30 0x01 0x00                 # Set manual fan control
    echo "Warning: fans are no longer in auto mode, use \"$SCRIPT_NAME auto\" to set it back"
}

set() {
    if [[ -n "$1" && $1 =~ $INT_REGEX && $1 -ge 0 && $1 -le 100 ]]; then
        BYTE=$(printf '0x%x\n' $1)          # Convert to hex
        manual                              # Set manual mode
        raw 0x30 0x30 0x02 0xff $BYTE       # Set fans to given value
        echo "Set fans to $1"
    else
        echo "USAGE: $SCRIPT_NAME set <number>, where number is 0-100"
        echo "Example: $SCRIPT_NAME set 50"
        exit 1
    fi
}

readings() {
    ipmitool sensor | grep -E "Fan|Temp"
}

sensor() {
    OUTPUT=$(ipmitool sensor | grep -E "$1")
    SPLIT=(${OUTPUT//|/})
    echo ${SPLIT[$2]}
}

speed() {
    if [[ -n "$1" ]]; then
        sensor "Fan$1" 1 | grep -Eo $FLOAT_REGEX
    else
        echo "USAGE: $SCRIPT_NAME speed <fan number>"
        echo "Example: $SCRIPT_NAME speed 1"
    fi
}

temp() {
    if [[ -n "$1" ]]; then
        sensor "$1 Temp" 2 | grep -Eo $FLOAT_REGEX
    else
        echo "USAGE: $SCRIPT_NAME temp <sensor>"
        echo "Example: $SCRIPT_NAME temp Inlet"
    fi
}

unknown() {
    echo "Unknown command, see \"$SCRIPT_NAME help\""
    exit 1
}

help() {
    echo "Dell PowerEdge Fan Control Script"
    echo "  USAGE: $SCRIPT_NAME <command>"
    echo "  Command     Parameters      Description"
    echo "    help                      Show this help screen"
    echo "    auto                      Set fans to automatic control"
    echo "    manual                    Set fans to manual control"
    echo "    set       <number>        Set fans to given value, 0-100"
    echo "    speed     <number>        Get current fan speed in RPM for the given fan"
    echo "    temp      <sensor>        Get current temp in celsius for the given sensor"
    echo "    readings                  Shows all temp and fan sensor readings"
    exit 1
}


if [[ -n "$1" ]]; then                          # Check if we have a first parameter
    if [[ $(type -t $@) == function ]]; then    # Check if the first parameter is a function
        $@                                      # Call the function
    else
        unknown
    fi
else
    help
fi
