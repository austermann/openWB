#!/bin/bash

. /var/www/html/openWB/openwb.conf

#
# WR module for Suntrol STL 200
#
# uses http://suntrol/min_cur.js?nocache
# which returns:
# ---
# var Datum="27.10.19"
# var Uhrzeit="09:30:10"
# var Pac=608
# var aPdc=new Array(505,138,0)
# var curStatusCode = new Array(1)
# curStatusCode[0]=1
# var curFehlerCode = new Array(1)
# curFehlerCode[0]=0
# ---

# TODO @KevinW suntrol host konfigurierbar machen
suntrol_host=192.168.178.51

wattwr=$(curl --connect-timeout 10 -s http://${suntrol_host}/min_cur.js?nocache | grep "var Pac=" | sed 's/var Pac=//' | sed 's/[^0-9]*//g')

re='^-?[0-9]+$'

if ! [[ $wattwr =~ $re ]] ; then
	wattwr="0"
fi

if (( wattwr > 3 )); then
	wattwr=$(( wattwr * -1 ))
fi

echo $wattwr
echo $wattwr > /var/www/html/openWB/ramdisk/pvwatt

# TODO fill $pvkwhk
# echo $pvkwhk > /var/www/html/openWB/ramdisk/pvkwhk
