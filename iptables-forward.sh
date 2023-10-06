#!/bin/bash
SCRIPT_NAME=$(basename $0)

usage() {
    echo "Usage: $SCRIPT_NAME <add/del> <udp/tcp> <host>:<port>"
    exit 1
}

create_rule() {
    action=$1

    if [ $action = "-A" ]; then action="-I"; fi

    echo "Processing iptables ${proto} rule for target ${target} and port ${port} with action ${action}"

    iptables -t nat $action PREROUTING -m $proto -p $proto --dport $port -j DNAT --to-destination $target:$port
    iptables $action FORWARD -d $target -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -t nat $action POSTROUTING -m $proto -p $proto --dport $port -j MASQUERADE
}

setup_vars() {
    if [[ -z $1 || -z $2 ]]; then usage;
    else 
        proto=$1
        address=(${2//:/ })
        target=${address[0]}
        port=${address[1]}
        if [[ -z $target || -z $port ]]; then usage; fi
    fi
}

add() {
    setup_vars $@
    create_rule -A 
}

del() {
    setup_vars $@
    create_rule -D
}

if [[ -n "$1" ]]; then
	if [[ $(type -t $@) == function ]]; then
		$@
	else usage; fi
else usage; fi
