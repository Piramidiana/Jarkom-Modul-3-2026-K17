# 1. NODE GOJO (KONFIGURASI JARINGAN DASAR)

# Atur default route dan DNS resolver di node gojo agar terhubung ke jaringan
ip route del default 2>/dev/null
ip route add default via 10.72.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf



# 2. NODE GOJO (INSTALASI & KONFIGURASI NGINX)

# Instal Nginx di node gojo
apt-get update
apt-get install nginx -y

# Edit Konfigurasi Utama Nginx untuk Path-Based Routing (Soal 16)
nano /etc/nginx/nginx.conf

# ISI NANO /etc/nginx/nginx.conf (GOJO):

user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    # Upstream frontend pool untuk path root (/) -> Round Robin ke maki & panda
    upstream frontend_pool {
        server 10.72.4.3;  # maki
        server 10.72.4.4;  # panda
    }

    server {
        listen 80;
        server_name jujutsu.K17.com www.jujutsu.K17.com;

        # Path / -> Diteruskan secara Round Robin ke frontend (maki/panda)
        location / {
            proxy_pass http://frontend_pool;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        # Path /api -> Diteruskan langsung ke node geto (misal IP: 10.72.4.2)
        location /api {
            proxy_pass http://10.72.4.2/api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

# Bersihkan file situs default, uji sintaks, dan restart Nginx
rm -f /etc/nginx/sites-enabled/default
nginx -t
service nginx restart



# 3. NODE ITADORI / CLIENT (PENGUJIAN AKHIR)

# Jalankan perintah pengujian berikut di terminal client (misal: itadori):
#
# 1. Uji akses web utama / root (harus dibalas bergantian oleh maki/panda):
curl -H "Host: jujutsu.K17.com" http://10.72.1.4
#
# 2. Uji akses path /api (harus diteruskan ke geto dan dijawab nanami/todo dengan rasio 3:1):
for i in {1..8}; do curl -s -H "Host: jujutsu.K17.com" http://10.72.1.4/api; echo ""; done
