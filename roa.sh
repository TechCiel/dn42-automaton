#!/bin/bash

curl -sfSLR {-o,-z}/etc/bird/roa6_dn42.conf "https://dn42.tech9.io/roa/bird6_roa_dn42.conf" && curl -sfSLR {-o,-z}/etc/bird/roa4_dn42.conf "https://dn42.tech9.io/roa/bird_roa_dn42.conf" && sed -i "s/roa/route/g" /etc/bird/roa{4,6}_dn42.conf

[ "$1" == "-o" ] && {
	grep roa_dn42 /etc/crontabs/root || {
		echo '*/10 * * * * curl -sfSLR {-o,-z}/etc/bird/roa6_dn42.conf "https://dn42.tech9.io/roa/bird6_roa_dn42.conf" && curl -sfSLR {-o,-z}/etc/bird/roa4_dn42.conf "https://dn42.tech9.io/roa/bird_roa_dn42.conf" && sed -i "s/roa/route/g" /etc/bird/roa{4,6}_dn42.conf' >> /etc/crontabs/root
	}
	return
}

cat <<'EOF' > /etc/systemd/system/roa-update.service
[Unit]
Description=Update ROAs of DN42
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'curl -sfSLR {-o,-z}/etc/bird/roa6_dn42.conf "https://dn42.tech9.io/roa/bird6_roa_dn42.conf" && curl -sfSLR {-o,-z}/etc/bird/roa4_dn42.conf "https://dn42.tech9.io/roa/bird_roa_dn42.conf" && sed -i "s/roa/route/g" /etc/bird/roa{4,6}_dn42.conf && birdc configure'
EOF

cat <<'EOF' > /etc/systemd/system/roa-update.timer
[Unit]
Description=Update ROAs of DN42

[Timer]
OnUnitActiveSec=10m

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable roa-update.timer
systemctl restart roa-update.timer
