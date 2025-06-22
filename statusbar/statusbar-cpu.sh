#!/bin/sh
mpstat 10 1 | awk 'NR==4 {print "", 100 - $NF "%"}'
sleep 1
