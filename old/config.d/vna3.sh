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

lxc_root_passwd=${lxc_root_passwd:-"root"}

yum -y install openvnet-vna

cat > /etc/openvnet/vna.conf <<EOF
node {
  id "vna3"
  addr {
    protocol "tcp"
    host "172.16.9.12"
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
IPADDR=10.101.0.4
NETMASK=255.255.255.0
OVS_EXTRA="
 set bridge     \${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     \${DEVICE} other_config:disable-in-band=true --
 set bridge     \${DEVICE} other-config:datapath-id=0000cccccccccccc --
 set bridge     \${DEVICE} other-config:hwaddr=02:02:00:00:00:03 --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<EOF
DEVICE=eth2
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=172.16.9.12
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

initctl start vnet-vna

lxc-create -t centos -n inst5
lxc-create -t centos -n inst6

chroot_dirs="
 /var/lib/lxc/inst5/rootfs
 /var/lib/lxc/inst6/rootfs
"
for dir in ${chroot_dirs}; do
chroot ${dir} /bin/bash -ex <<EOS
  echo root:${lxc_root_passwd} | chpasswd
EOS

done
cat > /var/lib/lxc/inst5/config <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst5
lxc.network.ipv4 = 10.200.0.14
lxc.network.hwaddr = 52:54:FF:00:00:05
lxc.rootfs = /var/lib/lxc/inst5/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst5
lxc.autodev = 0
EOF

cat > /var/lib/lxc/inst6/config <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst6
lxc.network.ipv4 = 10.200.0.15
lxc.network.hwaddr = 52:54:FF:00:00:06
lxc.rootfs = /var/lib/lxc/inst6/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst6
lxc.autodev = 0
EOF

lxc-start -d -n inst5
lxc-start -d -n inst6

ovs-vsctl add-port br0 inst5
ovs-vsctl add-port br0 inst6
