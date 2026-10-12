# JARKOM MODUL 3 2026 - K17

## Member

| Nama | NRP | Nomor |
| --- | --- | --- |
| Dian Piramidiana Rachmatika | 5027251031 | 1–10, 13 |
| Jude | _(isi NRP)_ | 11, 12, 14–20 |

## Struktur Repo

```
nodes/<node>/          konfigurasi per node (interfaces, install.sh, startup.sh, script soal)
perquest-scripts/      script per nomor: soal_<N>.sh
artefacts/             hasil capture (soal8_dora.txt)
assets/                screenshot (JARKOM#3_<nomor>_<isi>.png)
```

## Topologi & Alamat

![Topologi](assets/JARKOM%233_01_topologi.png)

Prefix kelompok: `10.72`. Semua subnet `/24`.

| Node | Peran | Alamat | Gateway |
| --- | --- | --- | --- |
| jichi | Router, NAT, DHCP Relay | eth0 DHCP (NAT), eth1 10.72.1.1, eth2 10.72.2.1, eth3 10.72.3.1, eth4 10.72.4.1 | dari NAT |
| utahime / shoko / gojo | DNS Master / DNS Slave / Reverse Proxy | 10.72.1.2 / .1.3 / .1.4 | 10.72.1.1 |
| tengen | DHCP Server | 10.72.4.10 | 10.72.4.1 |
| yaga / inumaki | DB Master / DB Slave | 10.72.4.11 / .4.12 | 10.72.4.1 |
| geto | Load Balancer | 10.72.4.20 | 10.72.4.1 |
| maki / panda | Worker frontend | 10.72.4.21 / .4.22 | 10.72.4.1 |
| nanami / todo / kirara | Worker API | 10.72.4.31 / .32 / .33 | 10.72.4.1 |
| itadori, fushiguro | Client Pool 1 | DHCP 10.72.2.10–.35 | 10.72.2.1 |
| zenin, okkotsu | Client Pool 2 | DHCP 10.72.2.70–.95 | 10.72.2.1 |
| ino, kusakabe | Client short lease | DHCP 10.72.3.10–.89 | 10.72.3.1 |
| miwa | Client long lease | DHCP 10.72.3.100–.199 | 10.72.3.1 |
| kugisaki | Client fixed address | 10.72.3.99 | 10.72.3.1 |

## Catatan Lingkungan GNS3 (hasil pengujian)

- Network config diisi lewat **Edit config** dan diterapkan dengan **restart node** (`ifup` tidak tersedia di shell debinet).
- Saat boot, `/gns3/init.sh` menjalankan `ifup -a -f`, sehingga baris `up bash /root/startup.sh` di network config dijalankan otomatis.
- Saat node di-Stop/Start, **`/root` dan `/etc/network` bertahan**, sedangkan **paket yang di-install hilang**. Karena itu setiap `startup.sh` meng-install ulang paket bila belum ada.
- Container tidak memakai systemd, jadi service dijalankan dengan `service <nama> start`.

## Laporan

### Soal 1 — Router, NAT, dan IP statis

jichi: eth0 memperoleh IP dari NAT, eth1–eth4 menjadi gateway Network 1–4. IPv4 forwarding dan source NAT (MASQUERADE) diaktifkan di `startup.sh` sehingga berlaku lagi setiap boot. Dua belas host infrastruktur diberi IP statis dengan gateway jichi.

Script: `perquest-scripts/soal_1.sh`, `nodes/jichi/{interfaces,install.sh,startup.sh}`, `nodes/<host>/interfaces`.

![IP jichi](assets/JARKOM%233_01_ip-jichi.png)
![Internet jichi](assets/JARKOM%233_01_jichi-internet.png)
![Ping semua host dari jichi](assets/JARKOM%233_01_ping-semua-host.png)
![Antar network (TTL 63)](assets/JARKOM%233_01_antar-network.png)

Hasil: 12 host `OK` dari jichi. gojo → tengen TTL 63 (melewati satu router). Ping 8.8.8.8 dari host internal berhasil, membuktikan NAT bekerja.

### Soal 2 — DHCP Server tengen

`isc-dhcp-server` melayani `eth0`. Network 4 dideklarasikan tanpa pool, sedangkan Network 2 dan 3 diberi scope.

Script: `perquest-scripts/soal_2.sh`.

![dhcpd running](assets/JARKOM%233_02_dhcpd-running.png)

Hasil: `dhcpd -t` tanpa error (tidak ada *No subnet declaration*), service running.

### Soal 3 — DHCP Relay jichi

Relay meneruskan permintaan dari eth2 (Network 2) dan eth3 (Network 3) ke `10.72.4.10`. eth4 ikut didaftarkan agar balasan dari tengen diterima. Debian trixie tidak menyediakan `/etc/init.d/isc-dhcp-relay`, sehingga `dhcrelay` dijalankan langsung dengan nilai dari `/etc/default/isc-dhcp-relay`.

Script: `perquest-scripts/soal_3.sh`.

![Relay running](assets/JARKOM%233_03_relay-running.png)
![Lease lewat relay](assets/JARKOM%233_03_lease-via-relay.png)

Hasil: itadori memperoleh 10.72.2.10 dan ino 10.72.3.10, keduanya tercatat di `dhcpd.leases` tengen.

### Soal 4 — Dua pool Network 2

Class berdasarkan MAC: `divA-dev` (itadori, fushiguro) → Pool 1, `divA-support` (zenin, okkotsu) → Pool 2. Rentang .2.36–.2.69 tidak pernah ditulis sebagai range. MAC okkotsu dikunci dengan `hwaddress ether` di network config-nya.

Script: `perquest-scripts/soal_4.sh`.

![Sebelum class](assets/JARKOM%233_04_sebelum-class.png)
![MAC okkotsu dikunci](assets/JARKOM%233_04_okkotsu-hwaddress.png)
![Pool 1 dan Pool 2](assets/JARKOM%233_04_pool1-pool2.png)

Hasil: itadori .2.10, fushiguro .2.11 (Pool 1); zenin dan okkotsu pindah ke .2.70/.2.71 (Pool 2).

### Soal 5 — Short/long lease, DNS, domain-search

Class `divB-short` (ino, kusakabe) 1800 detik di .3.10–.3.89, `divB-long` (miwa) 43200 detik di .3.100–.3.199. Opsi global: DNS 10.72.1.2 dan 10.72.1.3, `domain-name` dan `domain-search` `K17.com`. udhcpc tidak meminta opsi 119, sehingga tengen dipaksa selalu mengirimnya (`dhcp-parameter-request-list` + `77`).

Script: `perquest-scripts/soal_5.sh`.

![Config](assets/JARKOM%233_05_dhcpd-config.png)
![Short dan long lease](assets/JARKOM%233_05_short-long-lease.png)
![domain-search](assets/JARKOM%233_05_domain-search.png)

Hasil: ino/kusakabe `lease time 1800`, miwa `lease time 43200` di 10.72.3.100, resolv.conf berisi `search K17.com` dan dua nameserver.

### Soal 6 — Fixed address kugisaki

`host kugisaki` dengan MAC 02:42:49:6f:98:00 → 10.72.3.99, di luar semua pool. MAC kugisaki semula kembar dengan okkotsu, sehingga dikunci ke MAC bawaan GNS3 dengan `hwaddress`.

Script: `perquest-scripts/soal_6.sh` (dijalankan setelah `soal_5.sh`).

![MAC kugisaki](assets/JARKOM%233_06_kugisaki-mac-unik.png)
![Fixed address](assets/JARKOM%233_06_fixed-address.png)

Hasil: setelah restart kugisaki langsung mendapat 10.72.3.99, gateway 10.72.3.1, dan `search K17.com`.

### Soal 7 — Audit client

Script: `perquest-scripts/soal_7.sh`.

![Audit client](assets/JARKOM%233_07_audit-client.png)

| Client | IP | Broadcast | Gateway |
| --- | --- | --- | --- |
| itadori / fushiguro | 10.72.2.10 / .11 | 10.72.2.255 | 10.72.2.1 |
| zenin / okkotsu | 10.72.2.71 / .72 | 10.72.2.255 | 10.72.2.1 |
| ino / kusakabe | 10.72.3.10 / .11 | 10.72.3.255 | 10.72.3.1 |
| miwa | 10.72.3.100 | 10.72.3.255 | 10.72.3.1 |
| kugisaki | 10.72.3.99 | 10.72.3.255 | 10.72.3.1 |

Semua client menerima mask /24, DNS 10.72.1.2 dan 10.72.1.3, serta `search K17.com`. Lease di tengen cocok dengan MAC client, tidak ada IP kembar, dan tidak ada IP di luar pool. Fixed address tidak tercatat di `dhcpd.leases`.

### Soal 8 — Capture DORA

`tcpdump -l -i eth0 -n -vvv 'udp port 67 or udp port 68'` di tengen saat itadori meminta lease. Capture lengkap ada di `artefacts/soal8_dora.txt`.

Script: `perquest-scripts/soal_8.sh`.

![Discover dan Offer](assets/JARKOM%233_08_dora-discover-offer.png)
![Request dan ACK](assets/JARKOM%233_08_dora-request-ack.png)

| Field | Nilai |
| --- | --- |
| Urutan | Discover → Offer → Request → ACK (xid 0xf1fc2f58) |
| Server | 10.72.4.10 |
| Alamat diberikan | 10.72.2.10 |
| Lease time | 600 |
| giaddr | 10.72.2.1 (jichi eth2) |

### Soal 9 — Gangguan relay

Script: `perquest-scripts/soal_9.sh`.

![Relay mati](assets/JARKOM%233_09_relay-mati.png)
![Relay pulih](assets/JARKOM%233_09_relay-pulih.png)

Saat relay dimatikan, fushiguro mengirim DISCOVER tiga kali lalu `no lease, failing`, tanpa IPv4 dan tanpa default route. Setelah relay dinyalakan, fushiguro kembali mendapat 10.72.2.11 (Pool 1) dengan gateway 10.72.2.1.

### Soal 10 — Autostart

`startup.sh` dipanggil dari baris `up` di network config. jichi: ip_forward, NAT, install ulang dhcrelay bila hilang, jalankan relay. tengen: install ulang dhcpd bila hilang, set `INTERFACESv4`, jalankan `soal_5.sh` dan `soal_6.sh`.

Script: `perquest-scripts/soal_10.sh`, `nodes/jichi/startup.sh`, `nodes/tengen/startup.sh`.

![Autostart jichi](assets/JARKOM%233_10_jichi-autostart.png)
![Autostart tengen](assets/JARKOM%233_10_tengen-autostart.png)
![Client setelah restart](assets/JARKOM%233_10_client-setelah-restart.png)

Hasil: setelah kedua node di-restart, relay dan dhcpd berjalan tanpa perintah manual. Kedelapan client kembali ke pool masing-masing, kugisaki tetap 10.72.3.99, dan semua `INTERNET OK`.

### Soal 11–12 — DNS (Jude)

_Diisi Jude._

### Soal 13 — Replikasi MariaDB

yaga (master): `server-id=1`, `log-bin`, `bind-address=0.0.0.0`, database `db_shibuya_K17`, tabel `request_logs`, user replikasi `repl@10.72.4.12`, user aplikasi `k17@10.72.4.%`. inumaki (slave): `server-id=2`, `read_only`, `CHANGE MASTER TO` dari `mysql-bin.000001` posisi 4. Folder `/var/lib/mysql` dan `/etc/mysql` dibuat persisten di GNS3.

Script: `perquest-scripts/soal_13.sh`, `nodes/yaga/soal_13_master.sh`, `nodes/inumaki/soal_13_slave.sh`.

![Master](assets/JARKOM%233_13_master-status.png)
![Slave](assets/JARKOM%233_13_slave-status.png)
![Replikasi realtime](assets/JARKOM%233_13_replikasi-realtime.png)
![Setelah restart](assets/JARKOM%233_13_setelah-restart.png)

Hasil: `Slave_IO_Running` dan `Slave_SQL_Running` Yes. Baris yang dimasukkan di yaga langsung muncul di inumaki. User `k17` dapat login dari node Network 4. Setelah kedua node di-restart, data tetap ada dan replikasi tersambung kembali.

### Soal 14–20 — Web, Load Balancer, Proxy (Jude)

_Diisi Jude._
