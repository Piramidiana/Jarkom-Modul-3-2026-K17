#!/bin/bash
# ==== SOAL 13 - yaga sebagai DB master ====
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
