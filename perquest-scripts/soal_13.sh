
# 1. NODE JICHI (ROUTER)

echo "==> [JICHI] Mengaktifkan IP Forwarding & NAT..."
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "==> [JICHI] Memindahkan IP Gateway Network 4 ke eth4..."
ip addr del 10.72.4.1/24 dev eth3 2>/dev/null
ip addr add 10.72.4.1/24 dev eth4
ip link set eth4 up



# 2. NODE YAGA (MASTER MARIADB)

echo "==> [YAGA] Mengatur Rute Jaringan & DNS..."
ip route del default 2>/dev/null
ip route add default via 10.72.4.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "==> [YAGA] Menginstal & Mengonfigurasi MariaDB Master..."
apt-get update
apt-get install mariadb-server -y

echo "==> [YAGA] Konfigurasi server-id, binlog, dan bind-address..."
nano /etc/mysql/mariadb.conf.d/50-server.cnf

# ISI NANO /etc/mysql/mariadb.conf.d/50-server.cnf (Edit pada blok [mariadbd]):

[mariadbd]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
bind-address            = 0.0.0.0
server-id               = 1
log_bin                 = /var/log/mysql/mysql-bin.log
skip-name-resolve

# Membuat direktori log dan menjalankan service
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
service mariadb restart

echo "==> [YAGA] Membuat Database, Tabel, dan User Replikasi..."
mysql -u root << 'EOF'
CREATE DATABASE IF NOT EXISTS db_shibuya_K17;
USE db_shibuya_K17;

CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'password_replica';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';

CREATE USER IF NOT EXISTS 'admin_shibuya'@'10.72.4.%' IDENTIFIED BY 'password_admin';
GRANT ALL PRIVILEGES ON db_shibuya_K17.* TO 'admin_shibuya'@'10.72.4.%';

FLUSH PRIVILEGES;
EOF



# 3. NODE INUMAKI (SLAVE MARIADB)

echo "==> [INUMAKI] Mengatur Rute Jaringan & DNS..."
ip route del default 2>/dev/null
ip route add default via 10.72.4.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "==> [INUMAKI] Menginstal & Mengonfigurasi MariaDB Slave..."
apt-get update
apt-get install mariadb-server -y

echo "==> [INUMAKI] Konfigurasi server-id dan bind-address..."
nano /etc/mysql/mariadb.conf.d/50-server.cnf

# ISI NANO /etc/mysql/mariadb.conf.d/50-server.cnf (Edit pada blok [mariadbd]):

[mariadbd]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
bind-address            = 0.0.0.0
server-id               = 2
skip-name-resolve

mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
service mariadb restart

echo "==> [INUMAKI] Membuat struktur database lokal untuk slave..."
mysql -u root << 'EOF'
CREATE DATABASE IF NOT EXISTS db_shibuya_K47;
USE db_shibuya_K47;
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF



# 4. PENGHUBUNGAN & PENGUJIAN (DIJALANKAN MANUAL)


# LANGKAH A: Cek Posisi Log di yaga (Master)
# Jalankan di terminal yaga:
# mysql -u root -e "SHOW MASTER STATUS;"
# (Catat nilai pada kolom 'File' dan 'Position')

# LANGKAH B: Hubungkan inumaki (Slave) ke yaga
# Jalankan di terminal inumaki (Masuk ke mysql -u root dulu):
STOP SLAVE;

CHANGE MASTER TO
    MASTER_HOST='10.72.4.9',
    MASTER_USER='replica',
    MASTER_PASSWORD='password_replica',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=1699;

START SLAVE;
# SHOW SLAVE STATUS \G
# (Pastikan Slave_IO_Running & Slave_SQL_Running bernilai Yes)

# LANGKAH C: Uji Coba Insert Data
# 1. Jalankan di terminal yaga:
mysql -u root -e "USE db_shibuya_K17; INSERT INTO request_logs (log_message) VALUES ('Test Replikasi Database Yaga ke Inumaki Berhasil');"
#
# 2. Jalankan di terminal inumaki (harus muncul data yang sama):
mysql -u root -e "USE db_shibuya_K17; SELECT * FROM request_logs;"
