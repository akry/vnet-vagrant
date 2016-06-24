#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

echo 1 > /proc/sys/net/ipv4/ip_forward
route add -net 10.100.0.0 netmask 255.255.255.0 gw 10.100.0.1
route add -net 10.101.0.0 netmask 255.255.255.0 gw 10.101.0.1
