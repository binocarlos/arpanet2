#!/bin/sh
while ! grep -q ^1$ /sys/class/net/ethwe/carrier 2>/dev/null
do sleep 1
done
$@