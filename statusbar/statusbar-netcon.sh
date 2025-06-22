#!/bin/sh

ICON_WIRELESS_STR1="󰤟"
ICON_WIRELESS_STR2="󰤢"
ICON_WIRELESS_STR3="󰤥"
ICON_WIRELESS_STR4="󰤨"
ICON_WIRELESS_DISC="󰤫"
ICON_WIRELESS_DISABLED="󰤭"
ICON_WIRED_CON="󰛳"
ICON_WIRED_DISC="󰲜"



WIRELESS_IF=wlo1
WIRED_IF=enp5s0

wireless_state="$(cat /sys/class/net/$WIRELESS_IF/operstate)"
ethernet_state="$(cat /sys/class/net/$WIRED_IF/operstate)"

if [ "$wireless_state" == "up" ] ; then
  wireless_quality="$(awk '/^\s*w/ {print int($3)}' /proc/net/wireless)"
  wireless_ssid="$(iw dev $WIRELESS_IF info | grep ssid | cut -d' ' -f2)"
  if [ "$wireless_quality" -lt 20 ] ; then
    wifiicon="$ICON_WIRELESS_STR1  $wireless_ssid "
  elif [[ "$wireless_quality" -ge 20 && "$wireless_quality" -lt 40 ]] ; then
    wifiicon="$ICON_WIRELESS_STR2  $wireless_ssid "
  elif [[ "$wireless_quality" -ge 40 && "$wireless_quality" -lt 60 ]] ; then
    wifiicon="$ICON_WIRELESS_STR3 $wireless_ssid "
  elif [ "$wireless_quality" -ge 60 ] ; then
    wifiicon="$ICON_WIRELESS_STR4  $wireless_ssid "
  fi
  #echo $wireless_ssid
  #echo $wireless_quality
	#wifiicon="$(awk '/^\s*w/ { print "📶", int($3 * 100 / 70) "% " }' /proc/net/wireless)"
elif [ "$wireless_state" == "down" ] ; then
	[ "$(cat /sys/class/net/wlo1/flags 2>/dev/null)" = '0x1003' ] && wifiicon=$ICON_WIRELESS_DISC || wifiicon=$ICON_WIRELESS_DISABLED
fi

[ "$(cat /sys/class/net/e*/operstate 2>/dev/null)" = 'up' ] && ethericon="$ICON_WIRED_CON " || ethericon="$ICON_WIRED_DISC "

printf "%s %s\n" "$ethericon" "$wifiicon"
sleep 1
