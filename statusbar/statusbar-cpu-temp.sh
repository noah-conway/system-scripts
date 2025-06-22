#!/bin/sh

# Get the line with the temperature
label='Package id 0'
sensors_output=$(sensors | grep "$label")

# Extract the current, high, and critical temps in Celsius
temp=$(echo "$sensors_output" | grep -oP '\+\K[0-9.]+(?=°C)' | sed -n 1p)
high=$(echo "$sensors_output" | grep -oP 'high = \+\K[0-9.]+(?=°C)')
crit=$(echo "$sensors_output" | grep -oP 'crit = \+\K[0-9.]+(?=°C)')

# Output
echo "$temp°C"
sleep 1
