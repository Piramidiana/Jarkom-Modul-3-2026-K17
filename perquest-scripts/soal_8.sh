#!/bin/bash
# ==== SOAL 8 - packet capture DORA lewat relay ====
# Jalankan di node: tengen. -l = output langsung (tanpa buffer) agar paket ACK ikut tercetak.
tcpdump -l -i eth0 -n -vvv 'udp port 67 or udp port 68' | tee /root/soal8_dora.txt
# Sementara capture berjalan, di itadori:  ifdown eth0; ifup eth0
# Tunggu +-3 detik setelah lease didapat, lalu Ctrl+C.
#
# Hasil (lihat artefacts/soal8_dora.txt):
#   Discover : Gateway-IP 10.72.2.1 (giaddr = jichi eth2)
#   Offer    : Your-IP 10.72.2.10, Server-ID 10.72.4.10, Lease-Time 600
#   Request  : Requested-IP 10.72.2.10
#   ACK      : Your-IP 10.72.2.10, Gateway-IP 10.72.2.1, Lease-Time 600
