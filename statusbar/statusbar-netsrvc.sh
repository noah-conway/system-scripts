#!/bin/sh

ALERT_ICON="󰌙 "
REG_ICON=""
TIMEOUT=2
COUNT=3

test_connection () {
  local host=$1

  if ! ping -c $COUNT -W $TIMEOUT "$host" > /dev/null 2>&1; then
    notify-send "Connection Alert\nCannot reach $host"
    return 1
  else
    return 0
  fi

}

if test_connection 192.168.5.250; then
  echo $REG_ICON
else
  echo $ALERT_ICON
fi





