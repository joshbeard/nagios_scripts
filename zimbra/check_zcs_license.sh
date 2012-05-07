#!/bin/sh
# check_zlicense.sh
# Josh Beard <jbeard /at/ dsdk12.net>
# Checks Zimbra license and reports it via Nagios

ZMLICENSE="sudo /opt/zimbra/bin/zmlicense"
ZMEXPIRE=`sudo /opt/zimbra/bin/zmlicense -p|grep ValidUntil`

DATE=$(echo $ZMEXPIRE|cut -d "=" -f 2)
YEAR=$(echo $DATE|cut -d '' -c1-4)
MONTH=$(echo $DATE|cut -d '' -c5-6)
DAY=$(echo $DATE|cut -d '' -c7-8)

WARN=30
CRIT=10

if $ZMLICENSE --check>/dev/null = "license is OK" ]; then
        echo "OK: License okay - Expires $YEAR-$MONTH-$DAY"
        exit 0
elif $ZMLICENSE --check>/dev/null = "license is in grace period" ]; then
        echo "WARNING: License is in grace period. Expires $YEAR-$MONTH-$DAY"
        exit 1
else
        echo "CRITICAL: Expires $YEAR-$MONTH-$DAY"
        exit 2
fi
