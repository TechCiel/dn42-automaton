#!/bin/bash

read -p "Enter interface name of this (internal) peer: " IFACE_NAME

rm -f /etc/bird/peers/${IFACE_NAME}.conf
birdc configure
sed -i "/dev ${IFACE_NAME} /d" /etc/hotplug.d/iface/40-dn42-wg
wg-quick down ${IFACE_NAME}
systemctl disable  wg-quick@${IFACE_NAME}
rm -f /etc/wireguard/${IFACE_NAME}.conf
