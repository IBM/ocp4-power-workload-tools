#!/bin/bash

/bin/find /sys/devices/system/node -name meminfo -exec /bin/grep Huge {} \;