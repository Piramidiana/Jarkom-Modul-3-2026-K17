#!/bin/bash
# ==== SOAL 3 - jichi sebagai DHCP relay ke tengen ====
# Jalankan di node: jichi   (setelah bash /root/install.sh)
# Debian trixie tidak menyediakan /etc/init.d/isc-dhcp-relay,
# jadi dhcrelay dijalankan langsung dengan nilai dari file default.
# eth2/eth3 = sisi client (Network 2/3), eth4 = sisi server (balasan dari tengen).
cat > /etc/default/isc-dhcp-relay <<'CONF'
SERVERS="10.72.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
CONF

. /etc/default/isc-dhcp-relay
pkill dhcrelay 2>/dev/null
dhcrelay -4 $(for i in $INTERFACES; do printf -- '-i %s ' "$i"; done) $OPTIONS $SERVERS

# Verifikasi (jichi)
pgrep -a dhcrelay

# Verifikasi (client itadori / ino):  ip -br a show eth0; ip route
# Verifikasi (tengen): grep -E "^lease|hardware ethernet" /var/lib/dhcp/dhcpd.leases
