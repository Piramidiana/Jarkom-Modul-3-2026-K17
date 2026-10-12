#!/bin/bash
# ==== SOAL 7 - audit konfigurasi seluruh client Divisi A & B ====
# Tidak mengubah konfigurasi; hanya renew + verifikasi.

# --- Jalankan di tiap client (itadori, fushiguro, zenin, okkotsu, ino, kusakabe, miwa, kugisaki) ---
# ifdown eth0; ifup eth0 >/dev/null 2>&1
# echo "== $(hostname)"
# ip -4 -o addr show eth0 | awk '{print "ip", $4, "brd", $6}'
# ip route | awk '/default/{print "gw", $3}'
# grep -E 'search|nameserver' /etc/resolv.conf | tr '\n' ' '; echo

# --- Jalankan di tengen: lease aktif (fixed-address kugisaki tidak tercatat di sini) ---
awk '/^lease/{ip=$2} /^  binding state/{st=$3} /hardware ethernet/{mac=$3} /^}/{if(st=="active;") a[ip]=mac} END{for(i in a) print i, a[i]}' /var/lib/dhcp/dhcpd.leases | sort -V
