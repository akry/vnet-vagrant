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
PATH=${vnet_root}/ruby/bin:${PATH}
vnmgr=172.16.9.10

cat > /etc/openvnet/vna.conf <<EOF
node {
  id "vna2"
  addr {
    protocol "tcp"
    host "172.16.9.11"
    port 9103
  }
}

network {
  uuid ""
  gateway {
    address ""
  }
}
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
DEVICE=br0
TYPE=OVSBridge
DEVICETYPE=ovs
ONBOOT=yes
BOOTPROTO=static
IPADDR=10.100.0.3
NETMASK=255.255.255.0
OVS_EXTRA="
 set bridge     \${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     \${DEVICE} other_config:disable-in-band=true --
 set bridge     \${DEVICE} other-config:datapath-id=0000bbbbbbbbbbbb --
 set bridge     \${DEVICE} other-config:hwaddr=02:01:00:00:00:02 --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<EOF
DEVICE=eth2
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=172.16.9.11
NETMASK=255.255.255.0
EOF

yum -y install lxc lxc-templates
mkdir /cgroup
echo "cgroup /cgroup cgroup defaults 0 0" >> /etc/fstab
mount /cgroup

ifdown eth1
ifdown eth2
ifup eth1 || :
ifup eth2 || :

service mysqld  stop || :
service redis   stop || :

chkconfig mysqld  off
chkconfig redis   off

curl -s -X POST \
--data-urlencode uuid=dp-2 \
--data-urlencode display_name="vna2" \
--data-urlencode dpid="0x0000bbbbbbbbbbbb" \
--data-urlencode node_id="vna2" \
http://${vnmgr}:9090/api/datapaths

curl -s -X POST \
--data-urlencode uuid="if-dp2eth1" \
--data-urlencode owner_datapath_uuid="dp-2" \
--data-urlencode mac_address="08:00:00:00:00:02" \
--data-urlencode network_uuid="nw-pub" \
--data-urlencode ipv4_address="10.100.0.3" \
--data-urlencode port_name="eth1" \
--data-urlencode mode="host" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="if-inst3" \
--data-urlencode owner_datapath_uuid="dp-1" \
--data-urlencode mac_address="02:01:00:00:00:03" \
--data-urlencode network_uuid="nw-vnet1" \
--data-urlencode ipv4_address="10.200.0.12" \
--data-urlencode port_name="inst3" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="if-inst4" \
--data-urlencode owner_datapath_uuid="dp-1" \
--data-urlencode mac_address="02:01:00:00:00:04" \
--data-urlencode network_uuid="nw-vnet1" \
--data-urlencode ipv4_address="10.200.0.13" \
--data-urlencode port_name="inst4" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode broadcast_mac_address="99:88:77:00:00:03" \
--data-urlencode interface_uuid="if-dp2eth1" \
http://${vnmgr}:9090/api/datapaths/dp-1/networks/nw-vnet1

curl -s -X POST \
--data-urlencode broadcast_mac_address="99:88:66:00:00:02" \
--data-urlencode interface_uuid="if-dp2eth1" \
http://${vnmgr}:9090/api/datapaths/dp-2/networks/nw-pub

initctl start vnet-vna

lxc-create -t centos -n inst3
lxc-create -t centos -n inst4

cat > /var/lib/lxc/inst3/config <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst3
lxc.network.ipv4 = 10.200.0.12
lxc.network.hwaddr = 02:01:00:00:00:03
lxc.rootfs = /var/lib/lxc/inst3/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst3
lxc.autodev = 0
EOF

cat > /var/lib/lxc/inst4/config <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst4
lxc.network.ipv4 = 10.200.0.13
lxc.network.hwaddr = 02:01:00:00:00:04
lxc.rootfs = /var/lib/lxc/inst4/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst4
lxc.autodev = 0
EOF

lxc-start -d -n inst3
lxc-start -d -n inst4

ovs-vsctl add-port br0 inst3
ovs-vsctl add-port br0 inst4
