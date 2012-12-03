#!/bin/sh
###############################################################################
# Last Modified: Mon 03 Dec 2012 02:46:43 PM MST
# check open files (GNU/Linux and FreeBSD)
#
# Uses /proc/sys/fs/file-nr on Linux to determine  values
# Uses sysctl on FreeBSD to determine values
# Takes values in percentage or absolute
# Also spits out performance data
###############################################################################

PERCENT=0
WARN=50
CRIT=75
#WARN=12000
#CRIT=19000


PROCFILE="/proc/sys/fs/file-nr"

# Check operating system
_os=$(uname)
if [ "$_os" = "Linux" ]; then
	OPEN_FILES=$(awk '{print $1}' "$PROCFILE")
	MAX_FILES=$(awk '{print $3}' "$PROCFILE")
	_use="${PROCFILE}"
elif [ "$_os" = "FreeBSD" ]; then
	MAX_FILES=$(sysctl -n kern.maxfiles)
	OPEN_FILES=$(sysctl -n kern.openfiles)
	_use="sysctl"
else
	printf "Sorry, $(uname) is unknown.  You can modify this script to make it work, though.\n"
	exit 3
fi

while getopts hpw:c: OPT; do
	case $OPT in
		p) PERCENT=1;;
		w) WARN=$OPTARG;;
		c) CRIT=$OPTARG;;
		\?|h) printf "Usage: $0 [ -p -w # -c # ]\n"
			printf "   -p    Numbers are a percentage\n"
			printf "   -w    Warning value (absolute or percent)\n"
			printf "   -c    Critical value (absolute or percent)\n\n"
			printf "Example:\n"
			printf "   $0 -p -w 50 -c 75\n"
			printf "   50%% of our system's maxfiles triggers a warning; 75%% usage is critical.\n\n"
			printf "   $0 -w 15000 -c 20000\n"
			printf "   15000 open files causes a warning; 20000 is critical.\n\n"
			printf "Values are taken from ${_use}\n"
			exit 0
			;;
	esac
done

# Check if 'bc' can be found
command -v bc >/dev/null 2>&1 || { printf "bc(1) is required, but could not be found in PATH\n"; exit 3; }

if [ "$PERCENT" = "1" ]; then
        VAL=$(echo "scale=0; $OPEN_FILES*100/$MAX_FILES"|bc)
        realwarn=$(echo "scale=0; $MAX_FILES*.$WARN"|bc)
        realcrit=$(echo "scale=0; $MAX_FILES*.$CRIT"|bc)
        msg="(${VAL}%%) "
else
        VAL=$OPEN_FILES
        realwarn=$WARN
        realcrit=$CRIT
        msg=""
fi

perfdata="fhalloc=${OPEN_FILES};${realwarn};${realcrit};${MAX_FILES}"

if [ $VAL -ge $CRIT ]; then
        printf "CRITICAL: $OPEN_FILES / $MAX_FILES ${msg}allocated|${perfdata}\n"
        exit 2
elif [ $VAL -ge $WARN ]; then
        printf "WARNING: $OPEN_FILES / $MAX_FILES ${msg}allocated|${perfdata}\n"
        exit 1
else
        printf "OK: $OPEN_FILES / $MAX_FILES ${msg}allocated|${perfdata}\n"
        exit 0
fi

