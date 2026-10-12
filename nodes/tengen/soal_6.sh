#!/bin/bash
# ==== SOAL 6 - fixed address kugisaki (jalankan SETELAH soal_5.sh) ====
# Jalankan di node: tengen
# Kugisaki: MAC 02:42:49:6f:98:00 dikunci dengan hwaddress di network config-nya.
# 10.72.3.99 berada di celah .3.90-.3.99, di luar pool short (.3.10-.3.89) & long (.3.100-.3.199).
grep -q 'host kugisaki' /etc/dhcp/dhcpd.conf || cat >> /etc/dhcp/dhcpd.conf <<'CONF'

# Soal 6 - fixed address kugisaki, di luar semua pool dinamis
host kugisaki {
    hardware ethernet 02:42:49:6f:98:00;
    fixed-address 10.72.3.99;
}
CONF
dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart
grep -A3 'host kugisaki' /etc/dhcp/dhcpd.conf

# Verifikasi di kugisaki (setelah restart node atau ifdown/ifup):
#   ip -br a show eth0; ip route | head -1; cat /etc/resolv.conf   -> 10.72.3.99, search K17.com
