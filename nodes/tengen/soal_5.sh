#!/bin/bash
# ==== SOAL 5 - short/long lease Network 3 + DNS + domain-search ====
# Jalankan di node: tengen
# MAC: ino 02:42:de:c1:3b:00, kusakabe 02:42:05:ed:30:00, miwa 02:42:e5:2c:84:00
cat > /etc/dhcp/dhcpd.conf <<'CONF'
authoritative;
default-lease-time 600;
max-lease-time 7200;

# DHCP options untuk semua client (soal 5 & 7)
option domain-name-servers 10.72.1.2, 10.72.1.3;
option domain-name "K17.com";
option domain-search "K17.com";
# Paksa kirim opsi 119 (domain-search): udhcpc tidak memintanya secara default
if exists dhcp-parameter-request-list {
    option dhcp-parameter-request-list = concat(option dhcp-parameter-request-list, 77);
}

# --- Class Divisi A (soal 4) ---
class "divA-dev" {          # Pool 1: itadori, fushiguro
    match if substring(hardware, 1, 6) = 02:42:21:14:55:00
          or substring(hardware, 1, 6) = 02:42:81:c1:9e:00;
}
class "divA-support" {      # Pool 2: zenin, okkotsu
    match if substring(hardware, 1, 6) = 02:42:76:f7:65:00
          or substring(hardware, 1, 6) = f2:dd:ec:51:c9:cb;
}

# --- Class Divisi B (soal 5) ---
class "divB-short" {        # ino, kusakabe - 30 menit
    match if substring(hardware, 1, 6) = 02:42:de:c1:3b:00
          or substring(hardware, 1, 6) = 02:42:05:ed:30:00;
    default-lease-time 1800;
    max-lease-time 1800;
}
class "divB-long" {         # miwa - 12 jam
    match if substring(hardware, 1, 6) = 02:42:e5:2c:84:00;
    default-lease-time 43200;
    max-lease-time 43200;
}

# Network 4 - subnet lokal tengen, TANPA pool dinamis
subnet 10.72.4.0 netmask 255.255.255.0 {
}

# Network 2 - Divisi A
subnet 10.72.2.0 netmask 255.255.255.0 {
    option routers 10.72.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.72.2.255;
    pool { allow members of "divA-dev";     range 10.72.2.10 10.72.2.35; }
    pool { allow members of "divA-support"; range 10.72.2.70 10.72.2.95; }
}

# Network 3 - Divisi B
subnet 10.72.3.0 netmask 255.255.255.0 {
    option routers 10.72.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.72.3.255;
    pool { allow members of "divB-short"; range 10.72.3.10  10.72.3.89;  }
    pool { allow members of "divB-long";  range 10.72.3.100 10.72.3.199; }
}
CONF
dhcpd -t -cf /etc/dhcp/dhcpd.conf || exit 1
service isc-dhcp-server stop
: > /var/lib/dhcp/dhcpd.leases
service isc-dhcp-server start

# Verifikasi di ino/kusakabe/miwa:
#   ifdown eth0; ifup eth0; ip -br a show eth0; cat /etc/resolv.conf
