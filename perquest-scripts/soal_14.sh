# 1. NODE WORKER (KONFIGURASI JARINGAN UMUM)

echo "==> Mengatur Rute Jaringan & DNS (Lakukan di semua node selain jichi)..."
ip route del default 2>/dev/null
ip route add default via 10.72.4.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf



# 2. NODE GETO (REVERSE PROXY & LOAD BALANCER)

echo "==> [GETO] Menginstal dan Mengonfigurasi Nginx sebagai Reverse Proxy..."
apt-get update
apt-get install nginx -y

# Edit Konfigurasi Nginx Utama
nano /etc/nginx/nginx.conf

# ISI NANO /etc/nginx/nginx.conf (GETO):

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

    upstream frontend_pool {
        server 10.72.4.3;
        server 10.72.4.4;
    }

    upstream backend_pool {
        server 10.72.4.5;
        server 10.72.4.6;
        server 10.72.4.7;
    }

    server {
        listen 80 default_server;
        server_name jujutsu.K17.com _;

        location / {
            proxy_pass http://frontend_pool;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /api {
            proxy_pass http://backend_pool/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

# Bersihkan file situs default dan restart Nginx
rm -f /etc/nginx/sites-enabled/default
nginx -t
service nginx restart



# 3. NODE MAKI & PANDA (FRONTEND WORKER)

# Jalankan di MAKI (10.72.4.3):
apt-get update && apt-get install nginx -y
nano /var/www/html/index.html
# ISI: <h1>Frontend Server: maki</h1>
service nginx restart

# Jalankan di PANDA (10.72.4.4):
apt-get update && apt-get install nginx -y
nano /var/www/html/index.html
# ISI: <h1>Frontend Server: panda</h1>
service nginx restart



# 4. NODE NANAMI, TODO, KIRARA (BACKEND WORKER)

# Lakukan perintah berikut di setiap node backend (nanami, todo, kirara):
apt-get update
apt-get install nginx php-fpm php-mysql -y

# Membuat direktori dan file API PHP
mkdir -p /var/www/api/api
nano /var/www/api/index.php

# ISI NANO /var/www/api/index.php:

<?php
$host = '10.72.4.9';
$db = 'db_shibuya_K17';
$user = 'admin_shibuya';
$pass = 'password_admin';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}

$msg = "Request handled by worker " . gethostname();
$sql = "INSERT INTO request_logs (log_message) VALUES ('$msg')";
$conn->query($sql);

echo json_encode(["status" => "success", "worker" => gethostname()]);
$conn->close();
?>

# Salin ke subfolder /api/
cp /var/www/api/index.php /var/www/api/api/index.php

# Konfigurasi Virtual Host Nginx Backend
nano /etc/nginx/sites-available/default

# ISI NANO /etc/nginx/sites-available/default:

server {
    listen 80 default_server;
    root /var/www/api;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}

# Uji dan Jalankan Layanan
nginx -t
service nginx restart
service php8.4-fpm restart



# 5. NODE ITADORI (CLIENT / PENGUJIAN)

# Jalankan perintah ini secara manual di terminal itadori:
# curl -H "Host: jujutsu.K17.com" http://10.72.4.2
# curl -H "Host: jujutsu.K17.com" http://10.72.4.2/api
