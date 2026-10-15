#!/bin/bash
# Rekap Konfigurasi Praktikum - Soal 15 (Weighted Round Robin Load Balancer pada Geto)
# Domain: jujutsu.K17.com
==========================


# 1. NODE GETO (MENGUBAH UPSTREAM & PEMBOBOTAN API)

# Buka file konfigurasi Nginx utama di geto
nano /etc/nginx/nginx.conf


# ISI / PERUBAHAN PADA NANO /etc/nginx/nginx.conf (GETO):

# Ubah atau pastikan blok upstream api_cluster memiliki weight 3:1 untuk nanami dan todo:
#
    upstream api_cluster {
        server 10.72.4.5 weight=3;
        server 10.72.4.6 weight=1;
    }
#
# Dan pastikan location /api mengarah ke api_cluster:
#
    location /api {
        proxy_pass http://api_cluster/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

# Simpan file (Ctrl+O, Enter, Ctrl+X), lalu uji sintaks dan restart Nginx:
nginx -t
service nginx restart



# 2. NODE ITADORI (PENGUJIAN / LOOPING REQUEST)

# Jalankan perintah looping ini di terminal itadori untuk membuktikan rasio 3:1 (nanami : todo):
for i in {1..8}; do curl -s -H "Host: jujutsu.K17.com" http://10.72.4.2/api; echo ""; done
