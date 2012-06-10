#!/bin/sh
#####################################################################
# Josh Beard <josh at signalboxes.net>
# http://www.signalboxes.net/
# Last Modified: Sun 10 Jun 2012 03:25:12 AM MDT
# Check CPU temperature in FreeBSD
# Requires the 'coretemp' kernel module
# Original idea from nickebo http://www.nickebo.net/ (Python)
#####################################################################

## Check if the kernel module is loaded
kldstat -q -m cpu/coretemp
mod=$?
if [ $mod -ne 0 ]; then
	printf "Error: You don't have the 'coretemp' module loaded.\n"
	exit 3
fi

#####################################################################

## Command usage output
show_help() {
	printf "Usage: $0 -C core -w WARNING -c CRITICAL [-h]\n\n"
	printf "  -C    The core number to check\n"
	printf "  -w    The warning value\n"
	printf "  -c    The critical value\n"
	printf "  -f    Show temperature in Farenheit\n\n"
	printf "  -a    Show all cores in a single average\n"
	printf "  -d    Show each CPU in average details\n"
	printf "  -e    Warn/Critical for each core\n\n"
	printf "  -h    Show this help\n\n"
	printf "  see 'sysctl -a | grep temperature'\n"
}

## Convert Celcius to Farenheit
ctof() {
	a=$(expr $1 \* 9)
	b=$(expr $a + 160)
	f=$(expr $b / 5)
	printf "$f"
}

get_core_temp() {
	CORE=$1
	CORETEMP=$(sysctl -n dev.cpu.${CORE}.temperature|cut -d . -f 1)
	printf "${CORETEMP}"
}

exit_condition() {
	if [ $1 -ge $CRITICAL ]; then
		RET="CRITICAL"
		EXIT=2
	elif [ $1 -ge $WARNING ]; then
		RET="WARNING"
		EXIT=1
	else
		RET="OK"
		EXIT=0
	fi
}

#####################################################################

## Get command arguments/options
while getopts hadfeC:w:c: o; do
	case "$o" in
		C) CORE=$OPTARG;;
		w) WARNING=$OPTARG;;
		c) CRITICAL=$OPTARG;;
		f) FARENHEIT=1;;
		a) AVERAGE=1;;
		d) SHOWDETAILS=1;;
		e) EACHCORE=1;;
		h) show_help;exit 0;;
	esac
done

## Check if required arguments were provided
if [ ! -z $AVERAGE ] && [ $AVERAGE -ne 1 ] && [ -z $CORE ] || [ -z $WARNING ] || [ -z $CRITICAL ]; then
	show_help
	exit 3
fi

if [ $WARNING -ge $CRITICAL ]; then
	printf "Your WARNING threshold must be less than the critical threshold.\n"
	exit 3
fi


#####################################################################

if [ ! -z $AVERAGE ] && [ ${AVERAGE} -eq 1 ]; then
	CPUS=$(sysctl -n hw.ncpu)
	i=0
	TEMP=0
	DETAILS=""
	PERFDATA=""
	while [ ${i} -lt ${CPUS} ]; do
		CORETEMP=$(get_core_temp $i)

		## Convert to Farenheit if needed (do this now for perfdata)
		[ ! -z ${FARENHEIT} ] && [ ${FARENHEIT} -eq 1 ] && CORETEMP=$(ctof $CORETEMP)

		TEMP=$(( ${CORETEMP}+${TEMP}))
		DETAILS="${DETAILS}CPU${i}_Temp=${CORETEMP}"

		i=$(( ${i} + 1 ))

		if [ $i -le $CPUS ]; then
			DETAILS="${DETAILS} "
			PERFDATA="${PERFDATA}CPU${i}_Temp=${CORETEMP};${WARNING};${CRITICAL} "
		fi

		exit_condition $CORETEMP

	done

	CORE="average"
	TEMP=$(($TEMP/$CPUS))
	[ ! -z ${FARENHEIT} ] && [ ${FARENHEIT} -eq 1 ] && UNIT="F" || UNIT="C"

	[ ! -z $SHOWDETAILS ] && [ $SHOWDETAILS -eq 1 ] &&
		PERFDATA="Average=${TEMP};$WARNING;$CRITICAL ${PERFDATA}" || PERFDATA="Average=${TEMP};$WARNING;$CRITICAL"

else
	TEMP=$(get_core_temp ${CORE})
	[ ! -z ${FARENHEIT} ] && [ ${FARENHEIT} -eq 1 ] && TEMP=$(ctof $TEMP)
	PERFDATA="CPU${CORE}_Temp=$TEMP;$WARNING;$CRITICAL"

	exit_condition $TEMP
fi

[ ! -z ${FARENHEIT} ] && [ ${FARENHEIT} -eq 1 ] && UNIT="F" || UNIT="C"

#####################################################################
## Exit with output and perfdata
[ ! -z $SHOWDETAILS ] && [ $SHOWDETAILS -eq 1 ] && [ ! -z "$DETAILS" ] && DETAILS=" (${DETAILS})" || DETAILS=""
printf "${RET}: CPU $CORE is ${TEMP}${UNIT}${DETAILS}|${PERFDATA}\n"
exit $EXIT

#EOF
