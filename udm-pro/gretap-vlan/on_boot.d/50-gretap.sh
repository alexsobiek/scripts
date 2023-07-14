#!/bin/bash

# Define end points for tunnel
# This was tested using Wireguard, but should work over anything
LOCAL=172.30.0.1
REMOTE=172.30.0.201


# Define VLANs we want to tunnel
# 0 is default LAN
VLANS=(0 2)

conf_names() {
	BR="br$1"
	KEY="9$1"           # Each GRETAP tunnel will have it's key as the VLAN ID prefixed by '9'
	TAP="gretap$KEY"
}


create_tun() {
	conf_names $1
	ip link add $TAP type gretap local $LOCAL remote $REMOTE ttl 255 key $KEY
	brctl addif $BR $TAP
	ip link set dev $TAP up
}

destroy_tun() {
	conf_names $1
	brctl delif $BR $TAP
	ip link del $TAP
}

check_tun() {
        conf_names $1

        if [ ! -d "/sys/class/net/$TAP" ]; then
                echo "Missing $TAP"
                create_tun $1
        else
                brctl show $BR | grep -q $TAP
                if [ ! $? -eq 0 ]; then
                        echo "Missing $TAP interface on $BR"
                        brctl addif $BR $TAP
                fi
        fi
}



foreach() {
        for i in ${VLANS[@]}; do
               $@ $i
        done
}


setup() {
	foreach create_tun
}

destroy() {
	foreach destroy_tun
}

check() {
	foreach check_tun
}

if [[ -n "$1" ]]; then
	if [[ $(type -t $@) == function ]]; then
        	$@
    	else
        	echo "Unknown command"
    	fi
else
	setup
fi