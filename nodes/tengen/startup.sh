#!/bin/bash
# tengen - dijalankan otomatis tiap boot (baris "up" di network config)
LOG=/root/startup.log
echo "startup.sh jalan: $(date)" >> $LOG
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# no.10 - paket hilang saat container dibuat ulang: pasang lagi bila belum ada
if ! command -v dhcpd >/dev/null; then
  for i in $(seq 1 30); do ping -c1 -W1 deb.debian.org >/dev/null 2>&1 && break; sleep 2; done
  bash /root/install.sh >> $LOG 2>&1
fi

# no.2 - interface yang dilayani (kembali kosong setelah install ulang)
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

# no.4-6 - dhcpd.conf lengkap (soal_5 menulis config + start, soal_6 menambah fixed address)
bash /root/soal_5.sh >> $LOG 2>&1
bash /root/soal_6.sh >> $LOG 2>&1
echo "startup.sh selesai: $(date) | $(service isc-dhcp-server status)" >> $LOG
