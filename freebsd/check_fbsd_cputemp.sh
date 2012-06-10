#!/bin/sh
#####################################################################
# Josh Beard <josh at signalboxes.net>
# http://www.signalboxes.net/
# Check CPU temperature in FreeBSD
# Requires the 'coretemp' kernel module
# Original idea from nickebo http://www.nickebo.net/ (Python)
#####################################################################

## Check if the kernel module is loaded
kldstat -q -m cpu/coretemp
mod=$?
if [ $mod -ne 0 ]; then
	printf "Error: You don't have the 'coretemp' module loaded.\n"
	exit 4
fi

#####################################################################

## Command usage output
show_help() {
	printf "Usage: $0 -C core -w WARNING -c CRITICAL [-h]\n\n"
	printf "  -C    The core number to check\n"
	printf "  -w    The warning value\n"
	printf "  -c    The critical value\n"
	printf "  -f    Show temperature in Farenheit\n"
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

#####################################################################

## Get command arguments/options
while getopts hfC:w:c: o; do
	case "$o" in
		C) CORE=$OPTARG;;
		w) WARNING=$OPTARG;;
		c) CRITICAL=$OPTARG;;
		f) FARENHEIT=1;;
		h) show_help;;
	esac
done

## Check if required arguments were provided
if [ -z $CORE ]; then
	show_help
	exit 3
fi


#####################################################################

## Get the core's temperature via sysctl
TEMP=$(sysctl -hn dev.cpu.${CORE}.temperature)

## Get the non-decimal value of temperature
TEMP=$(echo ${TEMP} |cut -d . -f 1)

## Convert to farenheit if the user wants
[ ${FARENHEIT} -eq 1 ] && TEMP=$(ctof $TEMP)

## Check the thresholds
if [ ! -z $CRITICAL ] && [ $TEMP -ge $CRITICAL ]; then
	RET="CRITICAL"
	EXIT=2
elif [ ! -z $WARNING ] && [ $TEMP -ge $WARNING ]; then
	RET="WARNING"
	EXIT=1
else
	RET="OK"
	EXIT=0
fi

#####################################################################
## Exit with output and perfdata
printf "${RET}: CPU $CORE is ${TEMP}${UNIT}|${TEMP}\n"
exit $EXIT

#EOF
