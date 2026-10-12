#!/bin/bash
# tengen - paket yang dibutuhkan (jalankan manual sekali)
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-server tcpdump
