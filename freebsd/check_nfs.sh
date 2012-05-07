#!/bin/sh

check_nfsd=$(/etc/rc.d/nfsd status >/dev/null 2>&1;echo $?)
check_mountd=$(sudo /etc/rc.d/mountd status >/dev/null 2>&1;echo $?)
check_rpcbind=$(/etc/rc.d/rpcbind status >/dev/null 2>&1;echo $?)
check_statd=$(/etc/rc.d/statd status >/dev/null 2>&1;echo $?)

crit=0

if [ "$check_nfsd" != 0 ]; then
	err="nfsd is not running; "
	crit=1
fi

if [ "$check_mountd" != 0 ]; then
	err="${err}mountd is not running; "
	crit=1
fi

if [ "$check_rpcbind" != 0 ]; then
	err="${err}rpcbind is not running; "
	crit=1
fi

if [ "$check_statd" != 0 ]; then
	err="${err}statd is not running; "
	crit=1
fi


if [ $crit -eq 1 ]; then
	echo "CRITICAL: $err"
	exit 2
else
	echo "OK - everything is running"
	exit 0
fi 


