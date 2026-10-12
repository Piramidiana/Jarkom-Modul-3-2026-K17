#!/bin/bash
# ==== SOAL 4 - dua pool di Network 2 berdasarkan MAC (class) ====
# Jalankan di node: tengen
# MAC: itadori 02:42:21:14:55:00, fushiguro 02:42:81:c1:9e:00,
#      zenin 02:42:76:f7:65:00, okkotsu f2:dd:ec:51:c9:cb (dikunci hwaddress)
cat > /etc/dhcp/dhcpd.conf <<'CONF'
authoritative;
default-lease-time 600;
max-lease-time 7200;

# --- Class Divisi A ---
class "divA-dev" {          # Pool 1: itadori, fushiguro
    match if substring(hardware, 1, 6) = 02:42:21:14:55:00
          or substring(hardware, 1, 6) = 02:42:81:c1:9e:00;
}
class "divA-support" {      # Pool 2: zenin, okkotsu
    match if substring(hardware, 1, 6) = 02:42:76:f7:65:00
          or substring(hardware, 1, 6) = f2:dd:ec:51:c9:cb;
}

# Network 4 - subnet lokal tengen, TANPA pool dinamis
subnet 10.72.4.0 netmask 255.255.255.0 {
}

# Network 2 - Divisi A: dua pool, .2.36-.2.69 tidak dialokasikan
subnet 10.72.2.0 netmask 255.255.255.0 {
    option routers 10.72.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.72.2.255;
    pool {
        allow members of "divA-dev";
        range 10.72.2.10 10.72.2.35;
    }
    pool {
        allow members of "divA-support";
        range 10.72.2.70 10.72.2.95;
    }
}

# Network 3 - Divisi B (sementara, diatur di soal 5-6)
subnet 10.72.3.0 netmask 255.255.255.0 {
    range 10.72.3.10 10.72.3.89;
    option routers 10.72.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.72.3.255;
}
CONF
dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart

# Bersihkan lease lama (sebelum class) agar tidak ada lease di luar kebijakan pool
service isc-dhcp-server stop
: > /var/lib/dhcp/dhcpd.leases
service isc-dhcp-server start

# Verifikasi di tiap client Network 2:
#   ifdown eth0; ifup eth0; ip -br a show eth0
# Verifikasi di tengen (lease aktif):
#   awk '/^lease/{ip=$2} /^  binding state/{st=$3} /hardware ethernet/{mac=$3} /^}/{if(st=="active;") a[ip]=mac} END{for(i in a) print i, a[i]}' /var/lib/dhcp/dhcpd.leases | sort -V
