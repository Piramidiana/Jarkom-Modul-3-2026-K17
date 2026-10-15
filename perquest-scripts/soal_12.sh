#!/bin/bash
# Rekap Konfigurasi Praktikum - Soal 12 (A Record, CNAME, PTR, Forwarder & Recursion)
# Domain: jujutsu.K17.com
# ====================================================================

# ==========================================
# 1. NODE UTAHIME (DNS MASTER)
# ==========================================
echo "==> Mengonfigurasi File Master Zone (A Record & CNAME)..."
nano /etc/bind/jujutsu/jujutsu.K17.com
# ==========================================
# ISI NANO /etc/bind/jujutsu/jujutsu.K17.com:
# ==========================================
$TTL    604800
@       IN      SOA     ns1.jujutsu.K17.com. admin.jujutsu.K17.com. (
                              2023102603 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      ns1.jujutsu.K17.com.
@       IN      NS      ns2.jujutsu.K17.com.

ns1     IN      A       10.72.1.2
ns2     IN      A       10.72.1.3
@       IN      A       10.72.1.4
www     IN      CNAME   jujutsu.K17.com.
test    IN      A       192.168.100.100

echo "==> Mendaftarkan Reverse Zone ke named.conf.local..."
nano /etc/bind/named.conf.local
# ==========================================
# TAMBAHKAN DI FILE NANO /etc/bind/named.conf.local:
# ==========================================
zone "1.87.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/10.72.1.rev";
};

echo "==> Membuat File Reverse Zone (PTR)..."
nano /etc/bind/jujutsu/10.72.1.rev
# ==========================================
# ISI NANO /etc/bind/jujutsu/10.72.1.rev:
# ==========================================
$TTL    604800
@       IN      SOA     ns1.jujutsu.K17.com. admin.jujutsu.K17.com. (
                              2023102601 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      ns1.jujutsu.K17.com.
@       IN      NS      ns2.jujutsu.K17.com.

4       IN      PTR     jujutsu.K17.com.

echo "==> Mengonfigurasi DNS Forwarder dan Izin Recursion..."
nano /etc/bind/named.conf.options
# ==========================================
# ISI NANO /etc/bind/named.conf.options:
# ==========================================
options {
    directory "/var/cache/bind";

    // Mengizinkan client dari luar subnet untuk melakukan query dan rekursi ke internet
    recursion yes;
    allow-query { any; };
    allow-recursion { any; };

    // Meneruskan traffic internet yang tidak diketahui ke IP Gateway
    forwarders {
        192.168.122.1;
    };

    dnssec-validation no;
    listen-on-v6 { any; };
};

# Restart layanan DNS
echo "==> Me-restart Layanan BIND9..."
service named restart


# ==========================================
# 2. NODE ITADORI (CLIENT / PENGUJIAN)
# ==========================================
# (Dijalankan manual di itadori)

# Pastikan DNS resolver client mengarah ke utahime
nano /etc/resolv.conf
# isi: 
nameserver 10.72.1.2

# 1. Uji CNAME (Seharusnya muncul jujutsu.K17.com dan IP 10.721.4)
dig www.jujutsu.K17.com

# 2. Uji Reverse DNS / PTR (Seharusnya mengembalikan jujutsu.K17.com)
dig -x 10.72.1.4

# 3. Uji Ping Internet lewat DNS Forwarder
ping -c 3 google.com
