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
  id "vna"
  addr {
    protocol "tcp"
    host "${vnmgr}"
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

cat > /etc/openvnet/vnmgr.conf <<EOF
node {
  id "vnmgr"
  addr {
    protocol "tcp"
    host "${vnmgr}"
    port 9102
  }
  plugins []
}
EOF

cat > /etc/openvnet/webapi.conf <<EOF
node {
  id "webapi"
  addr {
    protocol "tcp"
    host "${vnmgr}"
    port 9101
  }
}
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
 set bridge     \${DEVICE} other-config:hwaddr=02:02:00:00:00:01 --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<EOF
DEVICE=eth2
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=172.16.9.10
NETMASK=255.255.255.0
EOF

yum -y install lxc lxc-templates
if [ ! -e /cgroup ]; then
  mkdir /cgroup
  echo "cgroup /cgroup cgroup defaults 0 0" >> /etc/fstab
  mount /cgroup
fi

vnet_root=/opt/axsh/openvnet

ifdown eth1
ifdown eth2
ifup eth1 || :
ifup eth2 || :

sed -i -e 's/bind/#bind/g' /etc/redis.conf

service mysqld  stop || :
service redis   stop || :

chkconfig mysqld  on
chkconfig redis   on

service mysqld  start || :
service redis   start || :


PATH=${vnet_root}/ruby/bin:${PATH}

cd ${vnet_root}/vnet
bundle exec rake db:create
bundle exec rake db:init

initctl start vnet-vnmgr
initctl start vnet-webapi

sleep 10

curl -s -X POST \
--data-urlencode uuid=dp-1 \
--data-urlencode display_name="vna" \
--data-urlencode dpid="0x0000aaaaaaaaaaaa" \
--data-urlencode node_id="vna" \
http://${vnmgr}:9090/api/datapaths

curl -s -X POST \
--data-urlencode uuid=nw-pub \
--data-urlencode display_name="nw-pub" \
--data-urlencode ipv4_network="10.100.0.0" \
--data-urlencode ipv4_prefix="24" \
--data-urlencode network_mode="physical" \
http://${vnmgr}:9090/api/networks

curl -s -X POST \
--data-urlencode uuid=nw-vnet1 \
--data-urlencode display_name="nw-vnet1" \
--data-urlencode ipv4_network="10.200.0.0" \
--data-urlencode ipv4_prefix="24" \
--data-urlencode network_mode="virtual" \
http://${vnmgr}:9090/api/networks

curl -s -X POST \
--data-urlencode uuid="if-dp1eth1" \
--data-urlencode owner_datapath_uuid="dp-1" \
--data-urlencode mac_address="02:02:00:00:00:01" \
--data-urlencode network_uuid="nw-pub" \
--data-urlencode ipv4_address="10.100.0.2" \
--data-urlencode port_name="eth1" \
--data-urlencode mode="host" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="if-inst1" \
--data-urlencode owner_datapath_uuid="dp-1" \
--data-urlencode mac_address="52:54:FF:00:00:01" \
--data-urlencode network_uuid="nw-vnet1" \
--data-urlencode ipv4_address="10.200.0.10" \
--data-urlencode port_name="inst1" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="if-inst2" \
--data-urlencode owner_datapath_uuid="dp-1" \
--data-urlencode mac_address="52:54:FF:00:00:02" \
--data-urlencode network_uuid="nw-vnet1" \
--data-urlencode ipv4_address="10.200.0.11" \
--data-urlencode port_name="inst2" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="if-dhcp1" \
--data-urlencode network_uuid="nw-vnet1" \
--data-urlencode mac_address="02:01:00:00:01:01" \
--data-urlencode ipv4_address="10.200.0.2" \
--data-urlencode mode="simulated" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="ns-dhcp1" \
--data-urlencode interface_uuid="if-dhcp1" \
--data-urlencode type="dhcp" \
http://${vnmgr}:9090/api/network_services

curl -s -X POST \
--data-urlencode broadcast_mac_address="99:88:77:00:00:01" \
--data-urlencode interface_uuid="if-dp1eth1" \
http://${vnmgr}:9090/api/datapaths/dp-1/networks/nw-vnet1

curl -s -X POST \
--data-urlencode broadcast_mac_address="99:88:66:00:00:01" \
--data-urlencode interface_uuid="if-dp1eth1" \
http://${vnmgr}:9090/api/datapaths/dp-1/networks/nw-pub

curl -s -X POST \
--data-urlencode uuid=dp-2 \
--data-urlencode display_name="vna2" \
--data-urlencode dpid="0x0000bbbbbbbbbbbb" \
--data-urlencode node_id="vna2" \
http://${vnmgr}:9090/api/datapaths

curl -s -X POST \
--data-urlencode uuid="if-dp2eth1" \
--data-urlencode owner_datapath_uuid="dp-2" \
--data-urlencode mac_address="02:02:00:00:00:02" \
--data-urlencode network_uuid="nw-pub" \
--data-urlencode ipv4_address="10.100.0.3" \
--data-urlencode port_name="eth1" \
--data-urlencode mode="host" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="if-inst3" \
--data-urlencode owner_datapath_uuid="dp-2" \
--data-urlencode mac_address="52:54:FF:00:00:03" \
--data-urlencode network_uuid="nw-vnet1" \
--data-urlencode ipv4_address="10.200.0.12" \
--data-urlencode port_name="inst3" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode uuid="if-inst4" \
--data-urlencode owner_datapath_uuid="dp-2" \
--data-urlencode mac_address="52:54:FF:00:00:04" \
--data-urlencode network_uuid="nw-vnet1" \
--data-urlencode ipv4_address="10.200.0.13" \
--data-urlencode port_name="inst4" \
http://${vnmgr}:9090/api/interfaces

curl -s -X POST \
--data-urlencode broadcast_mac_address="99:88:77:00:00:02" \
--data-urlencode interface_uuid="if-dp2eth1" \
http://${vnmgr}:9090/api/datapaths/dp-2/networks/nw-vnet1

curl -s -X POST \
--data-urlencode broadcast_mac_address="99:88:66:00:00:02" \
--data-urlencode interface_uuid="if-dp2eth1" \
http://${vnmgr}:9090/api/datapaths/dp-2/networks/nw-pub

initctl start vnet-vna

lxc-create -t centos -n inst1
lxc-create -t centos -n inst2

cat > /var/lib/lxc/inst1/config <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst1
lxc.network.ipv4 = 10.200.0.10
lxc.network.hwaddr = 52:54:FF:00:00:01
lxc.rootfs = /var/lib/lxc/inst1/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst1
lxc.autodev = 0
EOF

cat > /var/lib/lxc/inst2/config <<EOF
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = inst2
lxc.network.ipv4 = 10.200.0.11
lxc.network.hwaddr = 52:54:FF:00:00:02
lxc.rootfs = /var/lib/lxc/inst2/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = inst2
lxc.autodev = 0
EOF

lxc-start -d -n inst1
lxc-start -d -n inst2

ovs-vsctl add-port br0 inst1
ovs-vsctl add-port br0 inst2
