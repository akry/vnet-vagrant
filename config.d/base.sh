#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

# Do some changes ...

cat > /etc/yum.repos.d/openvnet-third-party.repo <<EOF
[openvnet-third-party]
name=OpenVNet Third Party
baseurl=http://dlc.openvnet.axsh.jp/packages/rhel/6/third_party/current/
enabled=1
gpgcheck=0
EOF

cat > /etc/yum.repos.d/openvnet.repo <<EOF
[openvnet]
name=OpenVNet
baseurl=http://dlc.openvnet.axsh.jp/packages/rhel/6/vnet/current/
enabled=1
gpgcheck=0
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br0
BOOTPROTO=none
ONBOOT=yes
HOTPLUG=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
DEVICE=br0
TYPE=OVSBridge
DEVICETYPE=ovs
ONBOOT=yes
BOOTPROTO=static
IPADDR=10.100.0.2
NETMASK=255.255.255.0
OVS_EXTRA="
 set bridge     \${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     \${DEVICE} other_config:disable-in-band=true --
 set bridge     \${DEVICE} other-config:datapath-id=0000aaaaaaaaaaaa --
 set bridge     \${DEVICE} other-config:hwaddr=02:01:00:00:00:01 --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

rpm -Uvh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release
yum -y install openvnet
