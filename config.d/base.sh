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

rpm -Uvh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release || :
# rpm -Uvh ftp://ftp.riken.go.jp/Linux/centos/6.6/os/x86_64/Packages/libyaml-0.1.3-1.4.el6.x86_64.rpm || :
yum -y install openvnet || :

cat > /etc/openvnet/common.conf <<EOF
registry {
  adapter "redis"
  host "${vnmgr}"
  port 6379
}

db {
  adapter "mysql2"
  host "localhost"
  database "vnet"
  port 3306
  user "root"
  password ""
}
EOF

echo 1 > /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv4/ip_forward

iptables --flush
iptables -L
service iptables stop
chkconfig iptables off
