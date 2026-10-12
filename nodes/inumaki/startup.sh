#!/bin/bash
# yaga / inumaki - dijalankan otomatis tiap boot (baris "up" di network config)
LOG=/root/startup.log
echo "startup.sh jalan: $(date)" >> $LOG
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# paket hilang saat container dibuat ulang; data & config aman di folder persisten
if ! command -v mariadbd >/dev/null; then
  for i in $(seq 1 30); do ping -c1 -W1 deb.debian.org >/dev/null 2>&1 && break; sleep 2; done
  bash /root/install.sh >> $LOG 2>&1
fi
service mariadb start >> $LOG 2>&1
echo "startup.sh selesai: $(date) | $(service mariadb status 2>&1 | grep -m1 -E 'Uptime|running|stopped')" >> $LOG
