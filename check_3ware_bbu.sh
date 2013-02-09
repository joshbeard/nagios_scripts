#!/bin/sh
####################################################################
# Simple check of 3Ware RAID BBU using tw_cli
# Last Modified: Sat 09 Feb 2013 03:53:06 PM MST
# Josh Beard - http://signalboxes.net/
# Reference http://www.cyberciti.biz/files/tw_cli.8.html#bbu_object_messages
####################################################################

tw_cli="/usr/local/sbin/tw_cli"

if [ ! -z $1 ]; then
	controller=$1
else
	controller="c0"
fi


####################################################################
## Main BBU status check
####################################################################
bbu_check() {
	bbu_status="/$controller/bbu show status"
	bbu_status=$($tw_cli $bbu_status | awk -F "=" '{print $2}' | sed 's/\ //g')

	case "$bbu_status" in
		"OK")
			status="BBU is OK"
			return 0
		;;
		"WeakBat")
			status="BBU status is $status - replace soon"
			return 1
		;;
		"Testing")
			status="BBU is testing"
			return 0
		;;
		"Charging")
			status="BBU is charging"
			return 0
		;;
		*)
			status="BBU status is $status"
			return 2
		;;
	esac
}
####################################################################
## Temperature/Voltage check
####################################################################
tv_check() {
	case "$1" in
		'temp')
			stat="Temperature"
		;;
		'volt')
			stat="Voltage"
		;;
	esac
	bbu_status="/$controller/bbu show $1"
	bbu_status=$($tw_cli $bbu_status | awk -F "=" '{print $2}' | sed 's/\ //g')

	case "$bbu_status" in
		"OK")
			status="${status}; ${stat} is OK"
			return 0
		;;
		"HIGH")
			status="${status}; ${stat} is HIGH"
			return 1
		;;
		"LOW")
			status="${status}; ${stat} is LOW"
			return 1
		;;
		"TOO-HIGH")
			status="${status}; ${stat} is TOO-HIGH"
			return 2
		;;
		"TOO-LOW")
			status="${status}; ${stat} is TOO-LOW"
			return 2
		;;
		*)
			status="${status}; ${stat} is UNKNOWN"
			return 3
		;;
	esac
}

####################################################################
## Check each item and grab the return value
####################################################################
bbu_check ; bbu=$?
tv_check temp ; temp=$?
tv_check volt ; volt=$?
	
## Print the status line
printf "$status\n"


####################################################################
## Exit with the highest return value
####################################################################
ret=0
for retval in $bbu $temp $volt ; do
	if [ "$retval" -gt "$ret" ]; then
		ret=$retval
	fi
done

exit $ret
