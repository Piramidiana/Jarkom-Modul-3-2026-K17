#!/bin/bash
# Rekap Konfigurasi Praktikum - Soal 18 (API Backup Server & Passive Health Check)
# Domain: jujutsu.K17.com
==========================


# 1. NODE KIRARA (BACKUP WORKER / PHP API)

# Jalankan di terminal kirara untuk menginstal layanan dan menyiapkan script API:
apt-get update
apt-get install nginx php-fpm php-mysql -y

mkdir -p /var/www/api/api
nano /var/www/api/index.php

# ISI NANO /var/www/api/index.php (KIRARA):

<?php
$host = '10.72.4.9';
$db = 'db_shibuya_K17';
$user = 'admin_shibuya';
$pass = 'password_admin';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}

$client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
if (strpos($client_ip, ',') !== false) {
    $client_ip = trim(explode(',', $client_ip)[0]);
}

$msg = "Request handled by worker " . gethostname();
$sql = "INSERT INTO request_logs (log_message, client_ip) VALUES ('$msg', '$client_ip')";
$conn->query($sql);

echo json_encode(["status" => "success", "worker" => gethostname(), "client_ip" => $client_ip]);
$conn->close();
?>

# Salin file ke subfolder /api/:
cp /var/www/api/index.php /var/www/api/api/index.php

# Konfigurasi Virtual Host Nginx di Kirara
nano /etc/nginx/sites-available/default

# ISI NANO /etc/nginx/sites-available/default (KIRARA):

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

# Uji dan Jalankan Layanan di Kirara
nginx -t
service nginx restart
service php8.4-fpm restart



# 2. NODE GETO (UPSTREAM BACKUP & HEALTH CHECK)

# Edit konfigurasi Nginx utama di geto untuk menambahkan health check dan backup server:
nano /etc/nginx/nginx.conf

# ISI NANO /etc/nginx/nginx.conf (GETO):

# Ubah blok upstream api_cluster menjadi seperti berikut:
#
#    upstream api_cluster {
#        server 10.72.4.5 weight=3 max_fails=2 fail_timeout=5s;  # nanami
#        server 10.72.4.6 weight=1 max_fails=2 fail_timeout=5s;  # todo
#        server 10.72.4.7 backup;                                # kirara (backup server)
#    }

# Uji sintaks dan restart Nginx di geto:
nginx -t
service nginx restart



# 3. SIMULASI & PENGUJIAN FAILOVER (DI ITADORI & WORKER)

# A. Uji normal (request dilayani nanami dan todo):
# for i in {1..8}; do curl -s -H "Host: jujutsu.K17.com" http://10.72.1.4/api; echo ""; done
#
# B. Simulasi gangguan dengan mematikan worker utama (nanami & todo):
# service nginx stop  (dijalankan di terminal nanami dan todo)
#
# C. Uji failover dari itadori (request otomatis dialihkan ke kirara tanpa error 502):
# curl -H "Host: jujutsu.K17.com" http://10.72.1.4/api
