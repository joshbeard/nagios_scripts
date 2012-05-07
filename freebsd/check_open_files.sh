#!/bin/sh

max=$(sysctl -n kern.maxfiles)
open=$(sysctl -n kern.openfiles)

warn_percent="40"
crit_percent="60"

percent=$(echo "scale=0; $open*100/$max"|bc)

if [ $percent -ge $crit_percent ]; then
	echo "CRITICAL - ${percent}% used; ${open}/${max}"
	exit 2
elif [ $percent -ge $warn_percent ]; then
	echo "WARNING - ${percent}% used; ${open}/${max}"
	exit 1
else
	echo "OK - ${percent}% used; ${open}/${max}"
	exit 0
fi

