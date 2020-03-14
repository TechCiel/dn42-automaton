#!/bin/bash

[ "$1" == "-b" -o "$2" == "-b" ] && BATCH=true || BATCH=false
pause () {
	$BATCH && return
	echo
	echo -n "$1 "
	echo "Press ENTER to proceed or Control-C to abort."
	read
}
echo
echo "This is a Peer Automaton."
echo

read -p "Choose a short name for this peer: " PEER_NAME
read -p "Enter peer ASN (e.g. 4242420817): " PEER_ASN
read -p "Enter peer DN42 IPv4 address: " PEER_IP4
read -p "Enter peer DN42 IPv6 address: " PEER_IP6
read -p "Enter peer WireGuard endpoint: " PEER_ENDPOINT
read -p "Enter peer WireGuard pubkey: " PEER_PUBKEY
read -p "Enter local DN42 IPv4 address: " YOUR_IP4
read -p "Enter local DN42 IPv6 address: " YOUR_IP6
echo
echo "Your AS <---> AS${PEER_ASN}"
echo "${YOUR_IP4} <---> ${PEER_IP4}"
echo "${YOUR_IP6} <---> ${PEER_IP6}"
echo "Peer endpoint: ${PEER_ENDPOINT}"
echo "Peer pubkey: ${PEER_PUBKEY}"
pause "Is that right?"

[ "$1" == "-o" -o "$2" == "-o" ] || {
mkdir -p /etc/wireguard/
cd /etc/wireguard/
cat <<EOF > dn42_${PEER_NAME}.conf
[Interface]
ListenPort = 2${PEER_ASN:(-4)}
PrivateKey = `cat private`
Address = ${YOUR_IP4}/32
Address = ${YOUR_IP6}/128
Table = off
PostUp = ip -4 route add dev dn42_${PEER_NAME} ${PEER_IP4}/32
PostUp = ip -6 route add dev dn42_${PEER_NAME} ${PEER_IP6}/128

[Peer]
PublicKey = ${PEER_PUBKEY}
Endpoint = ${PEER_ENDPOINT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 30
EOF
$BATCH || vi dn42_${PEER_NAME}.conf || exit
chmod 0600 dn42_${PEER_NAME}.conf
wg-quick down dn42_${PEER_NAME}
wg-quick up dn42_${PEER_NAME} && systemctl enable wg-quick@dn42_${PEER_NAME}
sleep 2
wg show dn42_${PEER_NAME}
pause
}

[ "$1" == "-o" -o "$2" == "-o" ] && {
	sed -i "/dev dn42_${PEER_NAME} /d" /etc/hotplug.d/iface/40-dn42-wg
	cat <<EOF >> /etc/hotplug.d/iface/40-dn42-wg
[ "\$ACTION" = "ifup" -a "\$INTERFACE" = "dn42_${PEER_NAME}" ] && ip -4 route add dev dn42_${PEER_NAME} ${PEER_IP4}/32
[ "\$ACTION" = "ifup" -a "\$INTERFACE" = "dn42_${PEER_NAME}" ] && ip -6 route add dev dn42_${PEER_NAME} ${PEER_IP6}/128
EOF
	$BATCH || vi /etc/hotplug.d/iface/40-dn42-wg || exit
}

mkdir -p /etc/bird/peers/
cd /etc/bird/peers/
cat <<EOF > dn42_${PEER_NAME}.conf
protocol bgp ${PEER_NAME}4 from dn42 {
    neighbor ${PEER_IP4} as ${PEER_ASN};
}
protocol bgp ${PEER_NAME}6 from dn42 {
    neighbor ${PEER_IP6} as ${PEER_ASN};
}
EOF
$BATCH || vi dn42_${PEER_NAME}.conf || exit
birdc configure
sleep 5
birdc show protocols
$BATCH || birdc
