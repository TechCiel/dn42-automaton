#!/bin/bash

wget https://github.com/TechCiel/dn42-automaton/archive/master.zip
unzip master.zip
mv dn42-automaton-master/* .
rm -rf dn42-automaton-master/ master.zip

[ "$1" == "-c" ] && {
	cp bird.conf /etc/bird/bird.conf
	read -p "Enter DN42 IPv4: " CONFNET4
	read -p "Enter DN42 IPv6: " CONFNET6
	sed -i "s/CONFNET4/${CONFNET4}/" /etc/bird/bird.conf
	sed -i "s/CONFNET6/${CONFNET6}/" /etc/bird/bird.conf
	service bird restart
	[ "$1" == "-o" -o "$2" == "-o" ] && birdc down ; /etc/init.d/bird start
	sleep 5
	birdc show status
	birdc show protocols
	birdc
}
