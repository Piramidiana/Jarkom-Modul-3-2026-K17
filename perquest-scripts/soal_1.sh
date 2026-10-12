#!/bin/bash
# ==== SOAL 1 - jichi router + NAT, IP statis host infrastruktur ====
# Prefix K17 = 10.72
# Network config tiap node ada di nodes/<node>/interfaces (diisi lewat GNS3 "Edit config",
# diterapkan dengan restart node karena ifup tidak tersedia di shell).

# ---------- Jalankan di: jichi ----------
# 1. Paket (sekali saja)
bash /root/install.sh

# 2. Startup tiap boot: resolv.conf + ip_forward + source NAT (aman diulang)
cat > /root/startup.sh <<'EOS'
#!/bin/bash
# jichi - dijalankan otomatis tiap boot (dipanggil dari network config)
echo "startup.sh jalan: $(date)" >> /root/startup.log
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# no.1 - IPv4 forwarding + source NAT ke internet
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOS
bash /root/startup.sh

# 3. Verifikasi jichi
ip -br a
ip route
cat /proc/sys/net/ipv4/ip_forward      # harus 1
iptables -t nat -S POSTROUTING         # MASQUERADE muncul sekali
tail -n 3 /root/startup.log            # bukti startup.sh jalan saat boot
ping -c 3 8.8.8.8

# 4. Verifikasi 12 host infrastruktur dari jichi
for ip in 10.72.1.2 10.72.1.3 10.72.1.4 \
          10.72.4.10 10.72.4.11 10.72.4.12 \
          10.72.4.20 10.72.4.21 10.72.4.22 \
          10.72.4.31 10.72.4.32 10.72.4.33; do
  ping -c1 -W1 $ip >/dev/null && echo "$ip OK" || echo "$ip GAGAL"
done

# ---------- Jalankan di: tiap host infrastruktur ----------
# ip -br a show eth0; ip route | head -1
# ping -c1 -W2 <gateway> >/dev/null && echo "GATEWAY OK" || echo "GATEWAY GAGAL"
# ping -c1 -W2 8.8.8.8  >/dev/null && echo "INTERNET OK" || echo "INTERNET GAGAL"
