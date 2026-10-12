#!/bin/bash
# ==== SOAL 13 - MariaDB master (yaga) & slave (inumaki) ====
# Persiapan GNS3 (yaga & inumaki): Configure > Advanced > Additional persistent directories:
#   /var/lib/mysql
#   /etc/mysql
# lalu: bash /root/install.sh ; service mariadb start
#
# ---------- yaga (master) : nodes/yaga/soal_13_master.sh ----------
cat > /etc/mysql/mariadb.conf.d/60-replication.cnf <<'CNF'
[mysqld]
server-id     = 1
log-bin       = mysql-bin
binlog_format = ROW
bind-address  = 0.0.0.0
CNF
service mariadb restart

mariadb -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_K17;
CREATE USER IF NOT EXISTS 'repl'@'10.72.4.12' IDENTIFIED BY 'repl123';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'10.72.4.12';
CREATE USER IF NOT EXISTS 'k17'@'10.72.4.%' IDENTIFIED BY 'k17pass';
GRANT ALL PRIVILEGES ON db_shibuya_K17.* TO 'k17'@'10.72.4.%';
FLUSH PRIVILEGES;
USE db_shibuya_K17;
CREATE TABLE IF NOT EXISTS request_logs (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(50) NOT NULL,
    client_ip   VARCHAR(50) NOT NULL,
    proxy_ip    VARCHAR(50) NOT NULL,
    user_agent  TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SQL

# ---------- inumaki (slave) : nodes/inumaki/soal_13_slave.sh ----------
# cat > /etc/mysql/mariadb.conf.d/60-replication.cnf  (server-id=2, relay-log, read_only=1, bind 0.0.0.0)
# service mariadb restart
# CHANGE MASTER TO MASTER_HOST='10.72.4.11', MASTER_USER='repl', MASTER_PASSWORD='repl123',
#   MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=4, MASTER_CONNECT_RETRY=10;
# START SLAVE;
#
# ---------- Verifikasi ----------
# inumaki: SHOW SLAVE STATUS\G  -> Slave_IO_Running: Yes, Slave_SQL_Running: Yes
# yaga   : INSERT INTO db_shibuya_K17.request_logs (...) VALUES ('uji-replikasi','10.72.2.10','10.72.4.20','tes-soal13');
# inumaki: SELECT * FROM db_shibuya_K17.request_logs;          -> baris yang sama
# inumaki: mariadb -h 10.72.4.11 -u k17 -pk17pass -e "SELECT CURRENT_USER();"  -> akses remote Network 4
#
# ---------- Autostart (yaga & inumaki): nodes/<node>/startup.sh ----------
# install ulang MariaDB bila hilang (--force-confold), lalu service mariadb start.
# Uji: restart yaga lalu inumaki -> startup.log "selesai", COUNT(*) tetap, Slave_IO/SQL_Running: Yes
