#!/bin/sh
#########################################################################
# Josh Beard <josh@signalboxes.net>
# Last Modified: Mon 07 May 2012 10:18:26 AM MDT
# Check outdated ports on FreeBSD
# Simply uses "pkg_version" to determine this.
# It doesn't check the age of the INDEX.
#########################################################################

pkg_version_bin="/usr/sbin/pkg_version"
grep_bin="/usr/bin/grep"
tr_bin="/usr/bin/tr"
wc_bin="/usr/bin/wc"

while getopts :w:c:h opt; do
	case "$opt" in
		w) 
			if echo $OPTARG|egrep -q '^[0-9]+$'; then
				WARNING=$OPTARG
			else
				printf "Error: -w must have an integer as an argument.\n"
				exit 3
			fi
			;;
		c) 
			if echo $OPTARG|egrep -q '^[0-9]+$'; then
				CRITICAL=$OPTARG
			else
				printf "Error: -c must have an integer as an argument.\n"
				exit 3
			fi
			;;
		h)
			printf "Usage: $0 -w INT -c INT\n"
			printf "    -w    Number of outdated ports to cause a warning\n"
			printf "    -c    Number of outdated ports to cause a critical\n\n"
			printf "    Example: $0 -w 3 -c 7\n\n"
			exit 0
			;;
		:)
			printf "Option -$OPTARG requires an argument.\n" >&2
			exit 1
		;;
	esac
done

if [ -z $CRITICAL ] || [ -z $WARNING ]; then
	printf "Error: You need to specify a warning (-w) and critical (-c) value.\n"
	exit 3
fi

if [ $CRITICAL -le $WARNING ]; then
	printf "Error: CRITICAL must be greater than WARNING\n"
	exit 3
fi


new_ports=$($pkg_version_bin -vIL =|$grep_bin "needs updating"|$wc_bin -l|$tr_bin -d " ")

if [ $new_ports -ge $CRITICAL ]; then
	printf "CRITICAL: $new_ports need updating\n"
	exit 2
elif [ $new_ports -ge $WARNING ]; then
	printf "WARNING: $new_ports need updating\n"
	exit 1
else
	printf "OK: $new_ports need updating\n"
	exit 0
fi

# Exit cleanly if we reach this point
exit 0
