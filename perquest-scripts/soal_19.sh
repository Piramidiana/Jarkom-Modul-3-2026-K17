# 1. NODE GOJO (PEMBUATAN DIREKTORI CACHE)

# Jalankan di terminal gojo untuk menyiapkan direktori penyimpanan cache Nginx:
mkdir -p /var/cache/nginx/jujutsu_cache
chown -R www-data:www-data /var/cache/nginx/jujutsu_cache



# 2. NODE GOJO (KONFIGURASI NGINX UTAMA)

# Edit file konfigurasi Nginx utama di gojo:
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

    # Konfigurasi Proxy Cache Path (Masa berlaku/inactive 60m, ukuran max 100m)
    proxy_cache_path /var/cache/nginx/jujutsu_cache levels=1:2 keys_zone=jujutsu_cache:10m max_size=100m inactive=60m use_temp_path=off;

    # Konfigurasi Rate Limiting untuk /api (Batas 10 request per detik per IP)
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    upstream frontend_pool {
        server 10.72..4.3;  # maki
        server 10.72..4.4;  # panda
    }

    server {
        listen 80;
        server_name jujutsu.K17.com www.jujutsu.K17.com;

        # Path / (Frontend dengan Proxy Caching & Masa berlaku cache 10 menit)
        location / {
            proxy_pass http://frontend_pool;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            # Terapkan Caching
            proxy_cache jujutsu_cache;
            proxy_cache_valid 200 302 10m;
            proxy_cache_valid 404 1m;
            
            # Tambahkan Header X-Cache-Status
            add_header X-Cache-Status $upstream_cache_status;
        }

        # Path /api (Dilengkapi Rate Limiting 10 req/s dengan burst)
        location /api {
            limit_req zone=api_limit burst=5 nodelay;
            
            proxy_pass http://10.72..4.2/api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

# Uji sintaks dan restart Nginx di gojo:
nginx -t
service nginx restart



# 3. NODE ITADORI / CLIENT (PENGUJIAN AKHIR)

# Jalankan perintah pengujian berikut di terminal client (misal: itadori):
#
# A. Uji Proxy Caching & Header X-Cache-Status (Akses pertama MISS, akses berikutnya HIT):
# curl -I -H "Host: jujutsu.K17.com" http://10.72..1.4/
#
# B. Uji Rate Limiting pada /api (Mengirim 20 request cepat, melampaui batas akan menghasilkan status 503):
# for i in {1..20}; do curl -s -I -H "Host: jujutsu.K17.com" http://10.72..1.4/api | grep "HTTP/"; done
