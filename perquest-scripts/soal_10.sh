#!/bin/bash
# ==== SOAL 10 - autostart DHCP server (tengen) & DHCP relay (jichi) ====
# Temuan: GNS3 membuat ulang container saat node di-Stop/Start.
#   - /root dan /etc/network BERTAHAN (di-mount dari /dev/sdb1)
#   - paket yang di-install HILANG
#   - tidak ada systemd; isc-dhcp-relay di Debian trixie tidak punya /etc/init.d
# Mekanisme autostart: baris "up ... /root/startup.sh" di network config node,
# dijalankan oleh "ifup -a -f" pada /gns3/init.sh saat boot.
#
# jichi  : nodes/jichi/startup.sh  -> ip_forward + NAT, install ulang dhcrelay bila hilang, soal_3.sh
# tengen : nodes/tengen/startup.sh -> install ulang dhcpd bila hilang, INTERFACESv4, soal_5.sh + soal_6.sh
#
# Uji: restart jichi lalu tengen (Stop -> Start), kemudian:
#   jichi : tail -n 4 /root/startup.log; pgrep -a dhcrelay
#   tengen: tail -n 2 /root/startup.log; pgrep -a dhcpd; grep -c "allow members" /etc/dhcp/dhcpd.conf
#   client: ifdown eth0; ifup eth0 2>&1 | grep "lease of"
#           ip -4 -o addr show eth0; ip route | head -1
#           ping -c1 -W2 8.8.8.8 >/dev/null && echo "INTERNET OK"
