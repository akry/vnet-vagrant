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
    public ""
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
 set bridge     \${DEVICE} other-config:hwaddr=02:02:00:00:00:02 --
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

initctl start vnet-vna

lxc-create -t centos -n inst3
lxc-create -t centos -n inst4

cat > /var/lib/lxc/inst3/config <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst3
lxc.network.ipv4 = 10.200.0.12
lxc.network.hwaddr = 52:54:FF:00:00:03
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
lxc.network.hwaddr = 52:54:FF:00:00:04
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
