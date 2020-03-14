# DN42 Automaton

This is a repo for my [DN42](https://wiki.dn42.us/) network configuration and scripts.

Stuff designed to use in my specific environment. It might be useful for you, but consider it a documentation only.

**I promise this will NOT WORK for you without modification.**

I use WireGuard tunnels for internal networking, and run both eBGP and iBGP in my full-mesh network.

## File List

- install.sh - install WireGuard & bird2, apply config, run roa.sh
- roa.sh - download ROA data of DN42 and set a timer to update it
- intern.sh - configure WireGuard and bird2 for internal node
	- `-b` to skip confirmations
- peer.sh - configure WireGuard and bird2 for a new peer
	- `-b` to skip confirmations
- delete.sh - stop and delete a peer (use with care)
- upgrade.sh - force pull this repo
	- `-c` to update `/etc/bird/bird.conf`

Parameter `-o` could be use for OpenWRT router on `install.sh`, `intern.sh`, and `peer.sh`. This way, WireGuard tunnel should be correctly configured in LuCI.

Registering AS/IP, firewall management, and WireGuard endpoint host re-resolving are not done in these scripts.

## Copyright & Contact

This repo uses WTFPL. Feel free to do anything you want.

Find me as `CIEL-DN42` in registry or just visit https://dn42.ciel.dev for contact.
