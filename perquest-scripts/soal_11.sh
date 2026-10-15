#!/bin/bash
# Rekap Konfigurasi Praktikum - Soal 11 (DNS Master & Slave)
# Domain: jujutsu.K17.com
# ====================================================================

# ==========================================
# 1. NODE JICHI (ROUTER & NAT)
# ==========================================
# Aktifkan IP Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Konfigurasi NAT Masquerade agar node di bawahnya bisa akses internet
# (Asumsi eth0 adalah interface yang terhubung ke NAT1)
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Konfigurasi IP Gateway untuk Switch 1 (Jalur utahime & shoko)
ip addr add 10.72.1.1/24 dev eth1
ip link set eth1 up

# Konfigurasi IP Gateway untuk Switch 2 (Jalur itadori)
ip addr add 10.72.2.1/24 dev eth2
ip link set eth2 up


# ==========================================
# 2. NODE UTAHIME (DNS MASTER)
# ==========================================
# Konfigurasi Default Route dan DNS Resolver agar bisa internetan
ip route add default via 10.72.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Install BIND9
apt-get update
apt-get install bind9 bind9utils dnsutils -y

# Edit Konfigurasi Master Zone
nano /etc/bind/named.conf.local
# ==========================================
# ISI NANO /etc/bind/named.conf.local (utahime):
# ==========================================
zone "jujutsu.K17.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.K17.com";
    allow-transfer { 10.72.1.3; };
    also-notify { 10.72.1.3; };
};

# Membuat direktori dan file record zone Master
mkdir -p /etc/bind/jujutsu
nano /etc/bind/jujutsu/jujutsu.K17.com
# ==========================================
# ISI NANO /etc/bind/jujutsu/jujutsu.K17.com:
# ==========================================
$TTL    604800
@       IN      SOA     ns1.jujutsu.K17.com. admin.jujutsu.17.com. (
                              2023102602 ; Serial (Sengaja dinaikkan untuk test sinkronisasi)
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      ns1.jujutsu.K17.com.
@       IN      NS      ns2.jujutsu.K17.com.

ns1     IN      A       10.72.1.2
ns2     IN      A       10.72.1.3
@       IN      A       10.72.1.2
test    IN      A       192.168.100.100

# Restart layanan DNS
service named restart


# ==========================================
# 3. NODE SHOKO (DNS SLAVE)
# ==========================================
# Konfigurasi Default Route dan DNS Resolver agar bisa internetan
ip route add default via 10.72.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Install BIND9
apt-get update
apt-get install bind9 bind9utils dnsutils -y

# Edit Konfigurasi Slave Zone
nano /etc/bind/named.conf.local
# ==========================================
# ISI NANO /etc/bind/named.conf.local (shoko):
# ==========================================
zone "jujutsu.K17.com" {
    type slave;
    file "/var/lib/bind/jujutsu.K17.com";
    masters { 10.72.1.2; };
};

# Restart layanan DNS
service named restart


# ==========================================
# 4. NODE ITADORI (CLIENT / PENGUJIAN)
# ==========================================
# Konfigurasi IP Address dan Routing Client
ip addr add 10.72.2.2/24 dev eth0
ip link set eth0 up
ip route add default via 10.72.2.1

# Pengujian Ping ke DNS Slave untuk memastikan routing antar switch berhasil
ping -c 3 10.72.1.3

# Pengujian Akhir: Query DNS ke Slave
# Jika sinkronisasi transfer otomatis berhasil, query ini akan mengembalikan IP 192.168.100.100
dig @10.72.1.3 test.jujutsu.K17.com
