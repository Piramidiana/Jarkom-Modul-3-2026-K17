# 1. NODE YAGA (MASTER MARIADB)

# Jalankan di terminal yaga untuk menambahkan kolom client_ip pada tabel request_logs:
mysql -u root << 'EOF'
USE db_shibuya_K17;
ALTER TABLE request_logs ADD COLUMN IF NOT EXISTS client_ip VARCHAR(45);
EOF



# 2. NODE GOJO (PUBLIC GATEWAY PROXY)

# Edit konfigurasi Nginx utama di gojo untuk memastikan header penerusan IP aktif:
nano /etc/nginx/nginx.conf

# ISI NANO /etc/nginx/nginx.conf (GOJO):

# Pastikan di dalam blok location / dan location /api terdapat baris berikut:
#
#        location / {
#            proxy_pass http://frontend_pool;
#            proxy_set_header Host $host;
#            proxy_set_header X-Real-IP $remote_addr;
#            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        }
#
#        location /api {
#            proxy_pass http://10.72.4.2/api;
#            proxy_set_header Host $host;
#            proxy_set_header X-Real-IP $remote_addr;
#            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        }

# Uji sintaks dan restart Nginx di gojo:
nginx -t
service nginx restart



# 3. NODE GETO (INTERNAL REVERSE PROXY)

# Edit konfigurasi Nginx utama di geto:
nano /etc/nginx/nginx.conf

# ISI NANO /etc/nginx/nginx.conf (GETO):

# Pastikan di dalam blok location /api terdapat baris penerusan header berikut:
#
#        location /api {
#            proxy_pass http://api_cluster/;
#            proxy_set_header Host $host;
#            proxy_set_header X-Real-IP $remote_addr;
#            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        }

# Uji sintaks dan restart Nginx di geto:
nginx -t
service nginx restart



# 4. NODE NANAMI, TODO, KIRARA (BACKEND WORKER / PHP API)

# Jalankan di setiap node backend (nanami, todo, kirara) untuk memperbarui script API PHP:
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

// Mengambil IP asli klien dari header X-Real-IP atau X-Forwarded-For
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

# Restart layanan PHP-FPM di setiap node backend:
service php8.4-fpm restart



# 5. NODE ITADORI / CLIENT (PENGUJIAN AKHIR)

# Jalankan perintah pengujian berikut di terminal client (misal: itadori):
# 
# 1. Uji request endpoint API melalui gojo:
# curl -H "Host: jujutsu.K17.com" http://<IP_GOJO>/api
#
# 2. Periksa hasil pencatatan di database yaga:
# mysql -u root -e "USE db_shibuya_K17; SELECT * FROM request_logs ORDER BY id DESC LIMIT 5;"
