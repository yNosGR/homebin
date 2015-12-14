#!/bin/bash

PMP_SERVERS="vm-pmp.leanlogistics.com vm-pmp02.leanlogistics.com"
PMP_PORT=5522

DNS_LOOKUP=true
QUIET=false
HELP=false

function msg() {
    if ! $QUIET ; then
        echo "$@"
    fi
}

while getopts 'nq' OPT ; do
    case $OPT in
        n) DNS_LOOKUP=false ;;
        q) QUIET=true ;;
    esac
done
shift $(( OPTIND - 1 ));

if [ $# -ne 1 -a $# -ne 2 ] ; then
    echo "Usage:"
    echo "    get-pmp [-n] [-q] RESOURCE [USERNAME]"
    echo "Where:"
    echo "    RESOURCE = resource to look up, usually a hostname"
    echo "    USERNAME = username on resource (optional)"
    echo "Options:"
    echo "    -n  don't canonicalize RESOURCE"
    echo "    -q  don't return anything other than the password"
    exit 1
fi

RESOURCE=$1
USERNAME=$2

if $DNS_LOOKUP ; then
    HOST=$(host "$RESOURCE" | grep "has" | cut -d " " -f 1 | egrep -o ".*\.leanlogistics.com")
    if [ -n "$HOST" ] ; then
        msg "...resolved $RESOURCE to $HOST"
        RESOURCE=$HOST
    else
        msg "...failed to resolve $RESOURCE"
    fi
fi

for SERVER in $PMP_SERVERS ; do
    if nc -z -w5 $SERVER $PMP_PORT > /dev/null 2>&1 ; then
        PMP_SERVER=$SERVER
        break
    fi
done

if [ -z "$PMP_SERVER" ] ; then
    echo "Error: unable to find PMP server ($PMP_SERVERS)"
    exit 1
fi

PASSWORD=$(ssh -q -p $PMP_PORT $(hostname)@$PMP_SERVER -i ~/.ssh/id_rsa RETRIEVE --resource=$RESOURCE --account=$USERNAME --reason="Password lookup via ssh")

if $QUIET ; then
    echo $PASSWORD
else
    echo "Password = $PASSWORD"
fi
