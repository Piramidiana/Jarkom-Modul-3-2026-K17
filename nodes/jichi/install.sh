#!/bin/bash
# jichi - paket yang dibutuhkan (jalankan manual sekali)
# Terbukti: paket tetap ada setelah node di-stop/start, jadi tidak perlu diulang tiap boot.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y iptables isc-dhcp-relay tcpdump procps
