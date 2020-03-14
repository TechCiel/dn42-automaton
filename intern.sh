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
echo "This script is for iBGP config."
echo

read -p "Choose a short name for this internal peer: " PEER_NAME
read -p "Enter your ASN (e.g. 4242420817): " YOUR_ASN
read -p "Enter peer DN42 IPv4 address: " PEER_IP4
read -p "Enter peer DN42 IPv6 address: " PEER_IP6
read -p "Enter peer DN42 IPv4 network(s) (space separated): " PEER_NET4
read -p "Enter peer DN42 IPv6 network(s) (space separated): " PEER_NET6
read -p "Enter peer WireGuard endpoint ADDRESS: " PEER_ENDPOINT
read -p "Enter peer WireGuard pubkey: " PEER_PUBKEY
read -p "Enter local DN42 IPv4 address: " YOUR_IP4
read -p "Enter local DN42 IPv6 address: " YOUR_IP6
YOUR_PORT="000${PEER_IP4##*.}"
YOUR_PORT="3${YOUR_PORT:(-4)}"
PEER_PORT="000${YOUR_IP4##*.}"
PEER_PORT="3${PEER_PORT:(-4)}"
echo "Local <---> ${PEER_NAME}"
echo "${YOUR_IP4} <---> ${PEER_IP4}"
echo "${YOUR_IP6} <---> ${PEER_IP6}"
echo "Will route: ${PEER_NET4}"
echo "Will route: ${PEER_NET6}"
echo "Peer endpoint: ${PEER_ENDPOINT}:${PEER_PORT}"
echo "Peer pubkey: ${PEER_PUBKEY}"
pause "Is that right?"

[ "$1" == "-o" -o "$2" == "-o" ] || {
mkdir -p /etc/wireguard/
cd /etc/wireguard/
cat <<EOF > intern_${PEER_NAME}.conf
[Interface]
ListenPort = ${YOUR_PORT}
PrivateKey = `cat private`
Address = ${YOUR_IP4}
Address = ${YOUR_IP6}
Table = off
PostUp = ip -4 route add dev intern_${PEER_NAME} ${PEER_IP4}/32
PostUp = ip -6 route add dev intern_${PEER_NAME} ${PEER_IP6}/128
`echo -n ${PEER_NET4} | xargs -rn1 echo PostUp = ip -4 route add dev intern_${PEER_NAME}`
`echo -n ${PEER_NET6} | xargs -rn1 echo PostUp = ip -6 route add dev intern_${PEER_NAME}`

[Peer]
PublicKey = ${PEER_PUBKEY}
Endpoint = ${PEER_ENDPOINT}:${PEER_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 30
EOF
$BATCH || vi intern_${PEER_NAME}.conf || exit
chmod 0600 intern_${PEER_NAME}.conf
wg-quick down intern_${PEER_NAME}
wg-quick up intern_${PEER_NAME} && systemctl enable wg-quick@intern_${PEER_NAME}
sleep 2
wg show intern_${PEER_NAME}
pause
}

[ "$1" == "-o" -o "$2" == "-o" ] && {
	sed -i "/dev intern_${PEER_NAME} /d" /etc/hotplug.d/iface/40-dn42-wg
	cat <<EOF >> /etc/hotplug.d/iface/40-dn42-wg
[ "\$ACTION" = "ifup" -a "\$INTERFACE" = "intern_${PEER_NAME}" ] && ip -4 route add dev intern_${PEER_NAME} ${PEER_IP4}/32
[ "\$ACTION" = "ifup" -a "\$INTERFACE" = "intern_${PEER_NAME}" ] && ip -6 route add dev intern_${PEER_NAME} ${PEER_IP6}/128
EOF
	$BATCH || vi /etc/hotplug.d/iface/40-dn42-wg || exit
}

mkdir -p /etc/bird/peers/
cd /etc/bird/peers/
cat <<EOF > intern_${PEER_NAME}.conf
protocol bgp ${PEER_NAME}4 from intern {
    neighbor ${PEER_IP4} as ${YOUR_ASN};
}
protocol bgp ${PEER_NAME}6 from intern {
    neighbor ${PEER_IP6} as ${YOUR_ASN};
}
EOF
$BATCH || vi intern_${PEER_NAME}.conf || exit
birdc configure
sleep 5
birdc show protocols
$BATCH || birdc
