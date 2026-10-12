#!/bin/bash
# jichi - dijalankan otomatis tiap boot (baris "up" di eth4 network config)
LOG=/root/startup.log
echo "startup.sh jalan: $(date)" >> $LOG
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# no.1 - IPv4 forwarding + source NAT
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# no.10 - paket hilang saat container dibuat ulang: pasang lagi bila belum ada
if ! command -v dhcrelay >/dev/null; then
  for i in $(seq 1 30); do ping -c1 -W1 deb.debian.org >/dev/null 2>&1 && break; sleep 2; done
  bash /root/install.sh >> $LOG 2>&1
fi

# no.3/10 - DHCP relay
bash /root/soal_3.sh >> $LOG 2>&1
echo "startup.sh selesai: $(date) | relay: $(pgrep -a dhcrelay)" >> $LOG
