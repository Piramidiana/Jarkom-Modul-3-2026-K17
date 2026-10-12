#!/bin/bash
# ==== SOAL 2 - tengen sebagai DHCP server ====
# Jalankan di node: tengen   (setelah bash /root/install.sh)
# Catatan: range di sini SEMENTARA; diganti pool/class di soal 4-6.

# Interface yang dilayani: eth0 (menghadap Network 4 / jalur dari relay)
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

cat > /etc/dhcp/dhcpd.conf <<'CONF'
authoritative;
default-lease-time 600;
max-lease-time 7200;

# Network 4 - subnet lokal tengen, TANPA pool dinamis
subnet 10.72.4.0 netmask 255.255.255.0 {
}

# Network 2 - Divisi A (lewat relay jichi eth2)
subnet 10.72.2.0 netmask 255.255.255.0 {
    range 10.72.2.10 10.72.2.35;
    option routers 10.72.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.72.2.255;
}

# Network 3 - Divisi B (lewat relay jichi eth3)
subnet 10.72.3.0 netmask 255.255.255.0 {
    range 10.72.3.10 10.72.3.89;
    option routers 10.72.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.72.3.255;
}
CONF

dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart

# Verifikasi
grep ^INTERFACESv4 /etc/default/isc-dhcp-server
service isc-dhcp-server status
pgrep -a dhcpd
