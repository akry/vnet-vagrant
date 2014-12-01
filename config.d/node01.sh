#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

# Do some changes ...

vnet_root=/opt/axsh/openvnet

ifup eth1

sed -e 's,bind,#bind,g' /etc/redis.conf

service mysqld  stop || :
service redis   stop || :

chkconfig mysqld  on
chkconfig redis   on

service mysqld  start || :
service redis   start || :

PATH=/opt/axsh/openvnet/ruby/bin:${PATH}

initctl start vnet-vnmgr
initctl start vnet-webapi

cd ${vnet_root}/vnctl; bundle install

./bin/vnctl datapaths add --uuid dp-1 --display-name "vna" --dpid "0x0000aaaaaaaaaaaa" --node-id "vna"
./bin/vnctl networks add --uuid nw-pub --display-name "nw-pub" --ipv4-network "10.100.0.0" --ipv4-prefix 24 --network-mode "physical"
./bin/vnctl networks add --uuid nw-vnet1 --display-name "vnet1" --ipv4-network "10.200.0.0" --ipv4-prefix 24 --network-mode "virtual"
./bin/vnctl datapaths networks add dp-1 nw-vnet1 --broadcast-mac-address "99:88:77:00:00:01" --interface-uuid if-eth1
./bin/vnctl interfaces add --uuid if-eth1 --owner-datapath-uuid dp-1 --mac-address "08:00:27:ee:f0:20" --network-uuid nw-pub --ipv4-address "10.100.0.2" --port-name "eth1" --mode "host"
