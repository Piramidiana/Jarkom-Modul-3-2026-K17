#!/bin/bash
# ==== SOAL 13 - inumaki sebagai DB slave dari yaga ====
cat > /etc/mysql/mariadb.conf.d/60-replication.cnf <<'CNF'
[mysqld]
server-id    = 2
relay-log    = relay-bin
read_only    = 1
bind-address = 0.0.0.0
CNF
service mariadb restart

# CHANGE MASTER hanya sekali (info replikasi tersimpan di /var/lib/mysql yang persisten)
if [ -z "$(mariadb -u root -N -e 'SHOW SLAVE STATUS')" ]; then
mariadb -u root <<'SQL'
CHANGE MASTER TO
    MASTER_HOST='10.72.4.11',
    MASTER_USER='repl',
    MASTER_PASSWORD='repl123',
    MASTER_PORT=3306,
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=4,
    MASTER_CONNECT_RETRY=10;
SQL
fi
mariadb -u root -e "START SLAVE;"
