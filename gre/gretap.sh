#!/bin/bash
LOCAL=10.5.104.1        # Local address
REMOTES=(10.5.104.155)  # Remote hosts we want to tunnel to
VLANS=(2 3 28 32)       # VLANs we want to tag

LAN_BR=br0      # What bridge should we use for default LAN traffic (NO tagged VLAN)
BRIDGE=true     # Should we add our VLANs to their respective bridges? As in br2 for VLAN 2?

TAP=gretap1000  # Interface name
KEY=1000        # Key for GRE tunnel (must be same on both ends)

foreach_remotes() {
  for i in ${REMOTES[@]}; do
    $@ $i
  done
}

foreach_vlan() {
  for i in ${VLANS[@]}; do
    $@ $i
  done
}

conf_tunnel() {
  REMOTE=$1
  TAP="tap$(echo $1 | sed 's/\.//g')"
}

conf_vlan() {
  BR="br$1"
  VTAP="$TAP.$1"
}

setup() {
  foreach_remotes setup_tunnel
}

setup_tunnel() {
  conf_tunnel $1
  echo "Creating tunnel from $LOCAL to $REMOTE using $TAP"
  ip link add $TAP type gretap local $LOCAL remote $REMOTE ttl 255 key $KEY
  brctl addif $LAN_BR $TAP # Give LAN access
  ip link set dev $TAP up
  foreach_vlan setup_vlan
}

setup_vlan() {
	conf_vlan $1
	echo "Tagging VLAN $1 on $VTAP"
	ip link add link $TAP name $VTAP type vlan id $1
	if $BRIDGE; then
	  echo "Adding $VTAP to $BR"
	  brctl addif $BR $VTAP
	fi
	ip link set dev $VTAP up
}

destroy() {
  foreach_remotes destroy_tunnel
}

destroy_tunnel() {
  conf_tunnel $1
  echo "Destroying tunnel from $LOCAL to $REMOTE on interface $TAP"
  echo "Bringing down $TAP"
  ip link set dev $TAP down
  brctl delif $LAN_BR $TAP
  foreach_vlan destroy_vlan
  ip link del $TAP
}

destroy_vlan() {
	conf_vlan $1
	echo "Bringing down $VTAP"
	ip link set dev $VTAP down
  if $BRIDGE; then
    echo "Removing $VTAP from $BR"
    brctl delif $BR $VTAP
  fi
  ip link del $VTAP
}

check() {
  foreach_remotes check_tunnel
}

check_br() {
  SEARCH_BR=$1
  SEARCH_TAP=$2
  echo "Checking if $SEARCH_TAP exists on $SEARCH_BR"
  brctl show $SEARCH_BR | grep -q $SEARCH_TAP
  if [ ! $? -eq 0 ]; then
    echo "Missing $SEARCH_TAP on bridge $SEARCH_BR"
    brctl addif $SEARCH_BR $SEARCH_TAP
  else
    echo "$SEARCH_TAP found on bridge $SEARCH_BR"
  fi
}

check_tunnel() {
  conf_tunnel $1
  echo "Checking if $TAP exists"
  if [ ! -d "/sys/class/net/$TAP" ]; then
    echo "Missing $TAP"
    setup
  else
    echo "$TAP exists"

    check_br $LAN_BR $TAP

    foreach_vlan check_vlan
  fi
}

check_vlan() {
	conf_vlan $1
	echo "Checking if $VTAP exists"
	if [ ! -d "/sys/class/net/$VTAP" ]; then
    echo "Missing $VTAP"
    setup_vlan $1
  else
    echo "$VTAP exists"
    check_br $BR $VTAP
  fi
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