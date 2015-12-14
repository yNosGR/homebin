#!/bin/bash

####
# Functions
####
reverseIP() {
  OLD_IFS="$IFS"
  IFS="."
  ARRAY=($1)
  IFS="$OLD_IFS"
  r=0
  for (( i=${#ARRAY[@]}; i>=0; i-- ));
  do
    f[$r]=${ARRAY[$i]}
    ((r++))
  done
  echo ${f[@]} | tr " " "."
}

function valid_ip() {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function usage() {
	echo "	Please supply at least 3 options 
	If you do not supply a name server, we will default to zaphod
		$0 [add|delete] IP HOSTNAME [DNS_Server]
		$0 add 10.30.2.1 natms-crux1-grr.leanlogistics.com zaphod.leanlogistics.com
	"
}

####
# Variable definitions
####
ipaddr=$2
revipaddr=`reverseIP $ipaddr`
# set the nameserver, if one isnt defined, use zaphod
nameserver=${4:-zaphod.leanlogistics.com}
FQDN=$3
# time to live for the entry - (minutes in a day * days in a year * years) 3600*365*4 
AGE=5256000


valid_ip $ipaddr
ip_valid=$?



####
# The meat'n pertaters.
####
#make sure we have a valid nameserver
nslookup google.com $nameserver > /dev/null
valid_nameserver=$?
if [ $valid_nameserver -eq 0 ] && [ $# -eq 3 -o $# -eq 4 ] ; then
	if [ $ip_valid -eq 0 ] ; then
		####
		# check to see if you have a kerberos ticket. if not, get one. 
		####
			klist >/dev/null || kinit `whoami`@LEANLOGISTICS.COM || krb_ticket=NO
			if [ ${krb_ticket:-EMPTY} == "NO" ] ; then 
				echo "Fix your kerberos!"
				usage
				exit 2
			fi
		####
		# nsupdate does not like leading spaces, so this looks a bit ugly. 
		####
		if [ $1 == add ] ; then
		#build the ptr
			ptr_update_rr="update add ${revipaddr}.in-addr.arpa $AGE PTR $FQDN."

		#update your A off
		cat <<EOF | nsupdate -g
server $nameserver
prereq nxrrset $FQDN. CNAME
update delete $FQDN. A
update add $FQDN. $AGE A $ipaddr
send
EOF
		RC=$((${RC:-0}+$?))

		#update your PTR
		cat <<EOF | nsupdate -g
server $nameserver
$ptr_update_rr
send 
EOF
		RC=$((${RC:-0}+$?))

		elif [ $1 == delete ]; then

		#build the ptr
		ptr_update_rr="update delete ${revipaddr}.in-addr.arpa PTR"
		# delete your A off 
		cat <<EOF | nsupdate -g
server $nameserver
prereq nxrrset $FQDN. CNAME
update delete $FQDN. A
send
EOF
		RC=$((${RC:-0}+$?))


		#update your ptr off (but dont let your mom catch you)
		cat <<EOF | nsupdate -g
server $nameserver
$ptr_update_rr
send 
EOF
		RC=$((${RC:-0}+$?))
			if [ $RC -ne 0 ]; then 
				echo failed to update record for $ipaddr $FQDN 
			fi	


		else
			echo Please tell me if you want to delete or add.
			usage
			exit 3
		fi
	else
		echo "Please supply a valid IP"
		usage
		exit 4
	fi
else
	if [ $valid_nameserver -ne 0 ] ; then
		echo "	Please supply a valid nameserver"	
	fi
	usage
	exit 5
fi

exit $RC
