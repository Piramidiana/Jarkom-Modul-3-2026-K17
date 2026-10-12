#!/bin/bash
# ==== SOAL 9 - simulasi gangguan DHCP relay ====
# A. jichi: matikan relay
pkill dhcrelay; sleep 1; pgrep -a dhcrelay || echo "RELAY MATI"

# B. fushiguro: minta lease saat relay mati (link tetap UP agar DISCOVER benar-benar terkirim)
#   ifdown eth0
#   ip link set eth0 up
#   udhcpc -i eth0 -n -q -t 3 -T 3      # gejala: 3x discover, "no lease, failing"
#   ip -br a show eth0; ip route        # tanpa IPv4, tanpa default route

# C. jichi: pulihkan relay
bash /root/soal_3.sh; pgrep -a dhcrelay
#   fushiguro: ifdown eth0; ifup eth0; ip -br a show eth0; ip route | head -1
#   -> kembali 10.72.2.11 (Pool 1), default via 10.72.2.1
