#!/bin/bash
# paket MariaDB (dijalankan manual / dari startup.sh bila hilang)
# --force-confold: pertahankan config di /etc/mysql (folder persisten) saat install ulang
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef mariadb-server mariadb-client
