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

currenttime=$(date +%H:%M)
if [[ "$currenttime" > "22:00" ]] || [[ "$currenttime" < "04:00" ]]; then

  # let  suntrol sleep...
  wattwr="0"
  echo $wattwr
  echo $wattwr > /var/www/html/openWB/ramdisk/pvwatt

else

  #
  # fill pvwatt
  #

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

  #
  # fill pvkwh
  #

  e_sum_wh=0
  re_only_digits='[0-9]+'

  readarray e_year_wh < <(curl --connect-timeout 10 -s http://${suntrol_host}/years.js?nocache | grep "ye\[yx" | sed 's/ye.*|//g' | sed 's/"//g' | sed 's/[^0-9]*//g')

  for e in "${e_year_wh[@]}"
  do
    if [[ $e =~ $re_only_digits ]] ; then
      ((e_sum_wh += $e))
    fi
  done

  if (( $e_sum_wh > 0)); then
    e_today_wh=$(curl --connect-timeout 10 -s http://${suntrol_host}/days.js?nocache | grep "da\[dx" | sed 's/da.*|//' | sed 's/;.*//g' | sed 's/[^0-9]*//g')

    if [[ $e_today_wh =~ $re_only_digits ]] ; then
      ((e_sum_wh += $e_today_wh))
      echo $e_sum_wh
      echo $e_sum_wh > /var/www/html/openWB/ramdisk/pvkwh
    fi

  fi

fi
