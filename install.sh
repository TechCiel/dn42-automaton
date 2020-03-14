#!/bin/bash

cat <<'EOF' >> /etc/sysctl.conf
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
EOF
sysctl -p
apt update
apt upgrade -y
apt install -y wireguard bird2
[ "$1" == "-o" ] && {
	opkg update
	opkg install wireguard bird2c
	echo '#!/bin/sh' > /etc/hotplug.d/iface/40-dn42-wg
	echo 'include "/etc/bird/bird.conf";' > /etc/bird.conf
	grep /etc/hotplug.d/iface/40-dn42-wg /etc/sysupgrade.conf || \
		echo /etc/hotplug.d/iface/40-dn42-wg >> /etc/sysupgrade.conf
	grep /etc/bird/ /etc/sysupgrade.conf || echo /etc/bird/ >> /etc/sysupgrade.conf
	grep /etc/bird.conf /etc/sysupgrade.conf || echo /etc/bird.conf >> /etc/sysupgrade.conf
}
mkdir -p /etc/wireguard
pushd /etc/wireguard
[ -f private ] || wg genkey | tee private | wg pubkey | tee public
popd
mkdir -p /etc/bird/peers
cp bird.conf /etc/bird/bird.conf
read -p "Enter DN42 IPv4: " CONFNET4
read -p "Enter DN42 IPv6: " CONFNET6
sed -i "s/CONFNET4/${CONFNET4}/" /etc/bird/bird.conf
sed -i "s/CONFNET6/${CONFNET6}/" /etc/bird/bird.conf
. roa.sh $1
service bird restart
[ "$1" == "-o" ] && birdc down ; /etc/init.d/bird start
sleep 2
birdc show status
birdc show protocols
birdc
