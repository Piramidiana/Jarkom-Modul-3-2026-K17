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

SOAL : Ketika Curtain menutup Shibuya, jalur komunikasi antar zona Jujutsu High terputus. Pulihkan konektivitas dasar dengan mengonfigurasi jichi: eth0 memperoleh WAN dari NAT, sedangkan eth1–eth4 menjadi gateway Network 1–4 sesuai tabel pemetaan. Aktifkan IPv4 forwarding dan source NAT, lalu tetapkan IP statis host infrastruktur sesuai tabel spesifikasi. Buktikan konektivitas setiap host ke gateway dan akses eksternal dari host yang relevan.


jichi: eth0 memperoleh IP dari NAT, eth1–eth4 menjadi gateway Network 1–4. IPv4 forwarding dan source NAT (MASQUERADE) diaktifkan di `startup.sh` sehingga berlaku lagi setiap boot. Dua belas host infrastruktur diberi IP statis dengan gateway jichi.

Script: `perquest-scripts/soal_1.sh`, `nodes/jichi/{interfaces,install.sh,startup.sh}`, `nodes/<host>/interfaces`.

![IP jichi](assets/JARKOM%233_01_ip-jichi.png)
![Internet jichi](assets/JARKOM%233_01_jichi-internet.png)
![Ping semua host dari jichi](assets/JARKOM%233_01_ping-semua-host.png)
![Antar network (TTL 63)](assets/JARKOM%233_01_antar-network.png)

Hasil: 12 host `OK` dari jichi. gojo → tengen TTL 63 (melewati satu router). Ping 8.8.8.8 dari host internal berhasil, membuktikan NAT bekerja.

### Soal 2 — DHCP Server tengen

SOAL : Tengen, penjaga pusat distribusi di Data Center, harus mengambil alih pengalokasian alamat bagi wilayah yang membutuhkan konfigurasi dinamis. Konfigurasikan isc-dhcp-server pada [PREFIX IP].4.10. Deklarasikan Network 4 ([PREFIX IP].4.0/24) sebagai subnet lokal tanpa pool dinamis, lalu siapkan scope DHCP untuk Network 2 ([PREFIX IP].2.0/24) dan Network 3 ([PREFIX IP].3.0/24). Validasi konfigurasi dan pastikan service aktif tanpa error “No subnet declaration”.

`isc-dhcp-server` melayani `eth0`. Network 4 dideklarasikan tanpa pool, sedangkan Network 2 dan 3 diberi scope.

Script: `perquest-scripts/soal_2.sh`.

![dhcpd running](assets/JARKOM%233_02_dhcpd-running.png)

Hasil: `dhcpd -t` tanpa error (tidak ada *No subnet declaration*), service running.

### Soal 3 — DHCP Relay jichi

SOAL : Permintaan alamat dari Divisi A dan Divisi B tidak dapat menyeberangi subnet secara langsung. Konfigurasikan jichi sebagai DHCP Relay menuju tengen ([PREFIX IP].4.10), menggunakan eth2 untuk Network 2 dan eth3 untuk Network 3. Buktikan bahwa client dari kedua subnet berhasil memperoleh lease melalui relay.

Relay meneruskan permintaan dari eth2 (Network 2) dan eth3 (Network 3) ke `10.72.4.10`. eth4 ikut didaftarkan agar balasan dari tengen diterima. Debian trixie tidak menyediakan `/etc/init.d/isc-dhcp-relay`, sehingga `dhcrelay` dijalankan langsung dengan nilai dari `/etc/default/isc-dhcp-relay`.

Script: `perquest-scripts/soal_3.sh`.

![Relay running](assets/JARKOM%233_03_relay-running.png)
![Lease lewat relay](assets/JARKOM%233_03_lease-via-relay.png)

Hasil: itadori memperoleh 10.72.2.10 dan ino 10.72.3.10, keduanya tercatat di `dhcpd.leases` tengen.

### Soal 4 — Dua pool Network 2
SOAL : Agar tim Dev dan Support di Divisi A menerima jatah alamat yang berbeda, atur dua pool DHCP pada Network 2. Tetapkan Pool 1 ([PREFIX IP].2.10–[PREFIX IP].2.35) untuk itadori dan fushiguro, serta Pool 2 ([PREFIX IP].2.70–[PREFIX IP].2.95) untuk zenin dan okkotsu. Rentang [PREFIX IP].2.36–[PREFIX IP].2.69 tidak boleh dialokasikan. Karena seluruh client berada pada subnet yang sama, gunakan DHCP class berdasarkan MAC Address atau Client ID untuk memisahkan kedua kelompok

Class berdasarkan MAC: `divA-dev` (itadori, fushiguro) → Pool 1, `divA-support` (zenin, okkotsu) → Pool 2. Rentang .2.36–.2.69 tidak pernah ditulis sebagai range. MAC okkotsu dikunci dengan `hwaddress ether` di network config-nya.

Script: `perquest-scripts/soal_4.sh`.

![Sebelum class](assets/JARKOM%233_04_sebelum-class.png)
![MAC okkotsu dikunci](assets/JARKOM%233_04_okkotsu-hwaddress.png)
![Pool 1 dan Pool 2](assets/JARKOM%233_04_pool1-pool2.png)

Hasil: itadori .2.10, fushiguro .2.11 (Pool 1); zenin dan okkotsu pindah ke .2.70/.2.71 (Pool 2).

### Soal 5 — Short/long lease, DNS, domain-search
SOAL : Setiap tim lapangan memiliki durasi operasi yang berbeda. Pada Network 3, berikan short lease 30 menit (1800 detik) kepada ino dan kusakabe, serta long lease 12 jam (43200 detik) kepada miwa. Gunakan pool short lease [PREFIX IP].3.10–[PREFIX IP].3.89 dan pool long lease [PREFIX IP].3.100–[PREFIX IP].3.199. Sesuaikan default-lease-time dan max-lease-time untuk setiap kelas client. Berikan pula DHCP options berupa DNS [PREFIX IP].1.2 dan [PREFIX IP].1.3, serta domain-search <xxxx>.com.

Class `divB-short` (ino, kusakabe) 1800 detik di .3.10–.3.89, `divB-long` (miwa) 43200 detik di .3.100–.3.199. Opsi global: DNS 10.72.1.2 dan 10.72.1.3, `domain-name` dan `domain-search` `K17.com`. udhcpc tidak meminta opsi 119, sehingga tengen dipaksa selalu mengirimnya (`dhcp-parameter-request-list` + `77`).

Script: `perquest-scripts/soal_5.sh`.

![Config](assets/JARKOM%233_05_dhcpd-config.png)
![Short dan long lease](assets/JARKOM%233_05_short-long-lease.png)
![domain-search](assets/JARKOM%233_05_domain-search.png)

Hasil: ino/kusakabe `lease time 1800`, miwa `lease time 43200` di 10.72.3.100, resolv.conf berisi `search K17.com` dan dua nameserver.

### Soal 6 — Fixed address kugisaki
SOAL : Kugisaki ditetapkan sebagai personel VIP yang harus mempertahankan alamat yang sama setiap kali terhubung. Buat DHCP static lease berdasarkan MAC Address client tersebut dengan fixed address [PREFIX IP].3.99. Pastikan alamat ini berada di luar seluruh pool dinamis, validasi konfigurasi server, lalu renew lease pada client. Buktikan bahwa alamat yang diterima sesuai dengan reservasi.

`host kugisaki` dengan MAC 02:42:49:6f:98:00 → 10.72.3.99, di luar semua pool. MAC kugisaki semula kembar dengan okkotsu, sehingga dikunci ke MAC bawaan GNS3 dengan `hwaddress`.

Script: `perquest-scripts/soal_6.sh` (dijalankan setelah `soal_5.sh`).

![MAC kugisaki](assets/JARKOM%233_06_kugisaki-mac-unik.png)
![Fixed address](assets/JARKOM%233_06_fixed-address.png)

Hasil: setelah restart kugisaki langsung mendapat 10.72.3.99, gateway 10.72.3.1, dan `search K17.com`.

### Soal 7 — Audit client
SOAL : Setelah aturan alokasi diterapkan, pastikan setiap client menerima konfigurasi jaringan sesuai wilayahnya: subnet mask 255.255.255.0 (/24), gateway dan broadcast address yang benar, DNS [PREFIX IP].1.2 serta [PREFIX IP].1.3, dan domain-search yang ditentukan. Periksa IP address dan routing seluruh client Divisi A dan Divisi B, kemudian cocokkan lease dengan /var/lib/dhcp/dhcpd.leases pada tengen. Pastikan tidak ada alamat yang bertabrakan atau berada di luar kebijakan pool.

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
SOAL : Sebelum Curtain dibuka kembali, buktikan bahwa proses pemberian alamat berjalan sesuai protokol. Lakukan packet capture saat salah satu client Network 2 atau Network 3 meminta lease baru. Gunakan tcpdump pada tengen atau jalur menuju Data Center untuk menunjukkan urutan DHCPDISCOVER → DHCPOFFER → DHCPREQUEST → DHCPACK. Identifikasi alamat server, alamat yang diberikan, lease time, dan field giaddr. Pastikan nilai giaddr sesuai dengan interface jichi yang menerima request dari subnet client.

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
SOAL : Sebuah gangguan memutus jalur relay dan membuat permintaan alamat tidak sampai ke Data Center. Hentikan service DHCP Relay pada jichi, lalu paksa salah satu client di Network 2 atau Network 3 meminta lease baru dan catat gejalanya. Pulihkan service relay, ulangi permintaan DHCP, lalu buktikan bahwa client kembali memperoleh alamat dari pool yang benar dengan gateway semula.

Script: `perquest-scripts/soal_9.sh`.

![Relay mati](assets/JARKOM%233_09_relay-mati.png)
![Relay pulih](assets/JARKOM%233_09_relay-pulih.png)

Saat relay dimatikan, fushiguro mengirim DISCOVER tiga kali lalu `no lease, failing`, tanpa IPv4 dan tanpa default route. Setelah relay dinyalakan, fushiguro kembali mendapat 10.72.2.11 (Pool 1) dengan gateway 10.72.2.1.

### Soal 10 — Autostart
SOAL : Setelah gangguan Shibuya tertangani, pastikan pemulihan bertahan setelah restart. Aktifkan autostart DHCP Server pada tengen dan DHCP Relay pada jichi, lalu restart kedua node. Verifikasi status layanan, IP, gateway, lease, dan konektivitas client Network 2–3. Pastikan kebijakan Pool 1, Pool 2, short lease, long lease, dan fixed address tetap berlaku.

`startup.sh` dipanggil dari baris `up` di network config. jichi: ip_forward, NAT, install ulang dhcrelay bila hilang, jalankan relay. tengen: install ulang dhcpd bila hilang, set `INTERFACESv4`, jalankan `soal_5.sh` dan `soal_6.sh`.

Script: `perquest-scripts/soal_10.sh`, `nodes/jichi/startup.sh`, `nodes/tengen/startup.sh`.

![Autostart jichi](assets/JARKOM%233_10_jichi-autostart.png)
![Autostart tengen](assets/JARKOM%233_10_tengen-autostart.png)
![Client setelah restart](assets/JARKOM%233_10_client-setelah-restart.png)

Hasil: setelah kedua node di-restart, relay dan dhcpd berjalan tanpa perintah manual. Kedelapan client kembali ke pool masing-masing, kugisaki tetap 10.72.3.99, dan semua `INTERNET OK`.

### Soal 11–12 — DNS (Jude)

### Soal 11 — DNS Master
SOAL : Konfigurasi Utahime sebagai DNS Master untuk domain jujutsu.K17.com agar dapat mengarahkan lalu lintas dari jaringan klien menuju public load balancer (Gojo).
Solusi : Utahime dikonfigurasi menggunakan BIND9 sebagai DNS Master dengan zone jujutsu.K17.com. File zone dikonfigurasi untuk mengatur A record domain utama ke IP Gojo (10.72.4.21).
Script : /root/soal_11.sh (di Utahime), /etc/bind/named.conf.local, /etc/bind/jujutsu.k17.com

<img width="788" height="431" alt="3_11_FIX ITADORI" src="https://github.com/user-attachments/assets/4bdf9552-accc-4cc2-8853-32b872893210" />



expected output yang muncul : Hasil uji ping jujutsu.K17.com atau host jujutsu.K17.com dari client berhasil me-resolve ke alamat IP Gojo (10.72.4.21).

### Soal 12 — DNS Slave
SOAL : Konfigurasi Shoko sebagai DNS Slave untuk domain jujutsu.K17.com sebagai server cadangan apabila DNS Master (Utahime) mengalami kegagalan/mati.
Solusi : Utahime dikonfigurasi untuk mengizinkan transfer zone (allow-transfer) ke IP Shoko. Shoko dikonfigurasi menggunakan BIND9 bertipe slave yang mengambil data zone dari master (Utahime).
Script : /root/soal_12.sh (di Utahime & Shoko), /etc/bind/named.conf.local (di Shoko)

<img width="747" height="274" alt="3_12_ItadoriDIG" src="https://github.com/user-attachments/assets/b550db92-3d07-478c-8a3f-b8b09e801bbc" />

<img width="803" height="235" alt="3_12_ItadoriDIG2" src="https://github.com/user-attachments/assets/039c8924-1612-413c-aa68-894d7fc1609b" />

<img width="661" height="128" alt="3_12_ItadoriDIG3" src="https://github.com/user-attachments/assets/cf86ebde-21e6-4625-809f-f37f1d8b7ef3" />


expected output yang muncul : Saat service bind9 di Utahime dimatikan secara paksa, client tetap berhasil melakukan resolve domain jujutsu.K17.com melalui Shoko yang mengambil alih proses DNS query.

### Soal 13 — Replikasi MariaDB
SOAL : Kepala Sekolah Yaga dan Inumaki mendirikan database terpusat yang redundan agar log aktivitas kutukan tetap aman tersimpan. Konfigurasikan MariaDB pada yaga sebagai DB-Master dan inumaki sebagai DB-Slave. Buat database db_shibuya_<xxxx> beserta tabel request_logs di Master, aktifkan binary logging (log-bin, server-id), lalu hubungkan inumaki sebagai Slave yang menyalin data secara realtime dengan CHANGE MASTER TO. Berikan hak akses remote bagi seluruh node di Network 4, lalu buktikan replikasi berhasil dengan memasukkan data baru di Master dan memeriksa hasilnya di Slave.

<img width="658" height="143" alt="3_13_Inumaki sinkron dengan yaga" src="https://github.com/user-attachments/assets/c07ad313-9277-4340-a1e9-141c0b17ef51" />

<img width="922" height="131" alt="3_13_Yaga" src="https://github.com/user-attachments/assets/dbbc5b69-bdd7-48b2-bbf5-52b25623155a" />

<img width="674" height="523" alt="3_13_YES INUMAKI" src="https://github.com/user-attachments/assets/a6ef4e70-a601-4c3a-988b-adabf65e5690" />


yaga (master): `server-id=1`, `log-bin`, `bind-address=0.0.0.0`, database `db_shibuya_K17`, tabel `request_logs`, user replikasi `repl@10.72.4.12`, user aplikasi `k17@10.72.4.%`. inumaki (slave): `server-id=2`, `read_only`, `CHANGE MASTER TO` dari `mysql-bin.000001` posisi 4. Folder `/var/lib/mysql` dan `/etc/mysql` dibuat persisten di GNS3.

Script: `perquest-scripts/soal_13.sh`, `nodes/yaga/soal_13_master.sh`, `nodes/inumaki/soal_13_slave.sh`.

![Master](assets/JARKOM%233_13_master-status.png)
![Slave](assets/JARKOM%233_13_slave-status.png)
![Replikasi realtime](assets/JARKOM%233_13_replikasi-realtime.png)
![Setelah restart](assets/JARKOM%233_13_setelah-restart.png)

Hasil: `Slave_IO_Running` dan `Slave_SQL_Running` Yes. Baris yang dimasukkan di yaga langsung muncul di inumaki. User `k17` dapat login dari node Network 4. Setelah kedua node di-restart, data tetap ada dan replikasi tersambung kembali.

### Soal 14–20 — Web, Load Balancer, Proxy (Jude)

### Soal 14 — Nginx Web, API Workers, dan Access Control
SOAL : Siapkan worker Web (Maki, Panda) untuk melayani halaman HTML dan worker API (Nanami, Todo, Kirara) untuk melayani JSON dan terhubung ke database. Blokir akses langsung dari client ke worker; hanya Load Balancer (Gojo/Geto) yang diizinkan mengakses worker secara langsung.
Solusi : Maki dan Panda diinstal Nginx statis. Nanami, Todo, dan Kirara diinstal Nginx + PHP-FPM untuk merender JSON yang menyimpan log ke DB Yaga (db_shibuya_K17). Nginx pada semua worker dipasang aturan allow <subnet_Gojo_Geto>; deny all; agar klien tidak bisa melalukan bypass proksi.
Script : /root/soal_14.sh di setiap worker (Maki, Panda, Nanami, Todo, Kirara).

[screenshoot]

[screenshoot]

expected output yang muncul : Klien (Itadori) yang mencoba curl langsung ke IP Worker mendapatkan error 403 Forbidden. Namun jika diakses dengan benar melalui proxy, API mengembalikan JSON dengan parameter worker yang sesuai.

### Soal 15 — Internal Load Balancer API
SOAL : Konfigurasi Geto sebagai internal load balancer yang membagi lalu lintas request secara proporsional ke API worker (Nanami dan Todo) dengan rasio beban 3:1.
Solusi : Geto dipasang Nginx sebagai Reverse Proxy. Blok upstream api_cluster dibuat dengan mengarahkan traffic ke IP Nanami menggunakan atribut weight=3 dan ke IP Todo menggunakan atribut weight=1.
Script : /root/soal_15.sh (di Geto), /etc/nginx/conf.d/geto-upstream.conf

[screenshoot]

[screenshoot]

expected output yang muncul : Ketika dilakukan looping request puluhan kali dari client (Itadori), hasil perhitungan log menunjukkan respons dikembalikan oleh Nanami sekitar 3 kali lebih banyak daripada Todo (misal: 30 Nanami, 10 Todo).

### Soal 16 — Public Reverse Proxy & Path-Based Routing
SOAL : Konfigurasi Gojo sebagai gerbang utama (Public Reverse Proxy) untuk melayani klien. Terapkan Path-Based Routing di mana akses ke path / (root) diarahkan ke cluster Web (Maki/Panda) dan path /api diarahkan ke internal LB (Geto).
Solusi : Gojo dipasang Nginx. Dua blok location dikonfigurasi: location / melakukan proxy_pass ke upstream Web Cluster, dan location /api/ melakukan proxy_pass ke IP Geto.
Script : /root/soal_16.sh (di Gojo), konfigurasi server block Nginx di Gojo.

[screenshoot]

[screenshoot]

expected output yang muncul : Client mengeksekusi curl [http://jujutsu.K17.com/](http://jujutsu.K17.com/) merespons isi HTML statis. Sementara curl [http://jujutsu.K17.com/api](http://jujutsu.K17.com/api) merespons output JSON dari backend.

### Soal 17 — Real IP Forwarding & Security Headers
SOAL : Pastikan IP asli klien diteruskan dari Gojo ke Geto hingga ke API Worker sehingga log database mencatat IP klien yang sebenarnya. Cegah manipulasi (spoofing) IP dari klien dengan mengabaikan header injeksi dari luar.
Solusi : Gojo menginjeksi header X-Real-IP dan menimpa X-Forwarded-For. Geto menggunakan modul Nginx set_real_ip_from agar menerima IP klien asli dari Gojo dan meneruskannya lagi. API Worker melakukan hal serupa dari Geto.
Script : /root/soal_17.sh (di Gojo, Geto, Nanami, Todo).

[screenshoot]

[screenshoot]

expected output yang muncul : Hasil akses dari Itadori memunculkan properti JSON client_ip: 10.72.2.10 (IP asli). Saat Itadori mencoba spoofing (curl -H "X-Forwarded-For: 1.1.1.1"), nilai client_ip tetap kebal dan mencatat IP 10.72.2.10 yang sah, lalu tersimpan aman di log database.

### Soal 18 — Failover API Worker
SOAL : Konfigurasi Kirara sebagai worker cadangan. Jika Nanami dan Todo down secara bersamaan, traffic langsung dialihkan ke Kirara tanpa menampilkan error 502 Bad Gateway ke pengguna.
Solusi : Pada konfigurasi upstream di Geto, Kirara (10.72.4.33) ditambahkan dengan atribut backup. Modul proxy_next_upstream dikonfigurasi untuk langsung melempar traffic yang gagal di primary worker (error/timeout) ke worker backup.
Script : /root/soal_18.sh (di Geto), snippet proxy_next_upstream Nginx.

[screenshoot]

[screenshoot]

expected output yang muncul : Saat service Nginx/PHP-FPM di Nanami dan Todo dimatikan manual, request dari Itadori tidak menerima status HTTP 502. Klien menerima status 200 OK dengan properti JSON "worker":"Kirara". Ketika primary dinyalakan lagi, rasio otomatis normal ke Nanami/Todo.

### Soal 19 — Proxy Cache & Rate Limiting
SOAL : Kurangi beban load balancer dengan mengaktifkan proxy cache (durasi 10 menit) di Gojo untuk endpoint Web. Terapkan Rate Limiting pada endpoint /api untuk mencegah DDoS, maksimal 10 request per detik (r/s).
Solusi : Direktori /var/cache/nginx/gojo dikonfigurasi menggunakan proxy_cache_valid 200 10m untuk path /. Limitasi dibuat dengan zone $binary_remote_addr dengan parameter rate=10r/s burst=5 nodelay pada path /api.
Script : /root/soal_19.sh (di Gojo).

[screenshoot]

[screenshoot]

expected output yang muncul : Curl pertama ke URL statis menghasilkan header X-Cache-Status: MISS, sedangkan akses kedua menghasilkan HIT. Saat client melakukan looping request cepat ke /api, hanya sebagian awal yang berhasil (200), sisanya ditolak dan menghasilkan respons HTTP 429 Too Many Requests yang juga terbukti tercatat di error.log Gojo sebagai limiting requests.

### Soal 20 — Pengujian Kapasitas (Apache Benchmark)
SOAL : Lakukan audit beban menggunakan Apache Benchmark (ab) dari Kusakabe dengan parameter -n 600 -c 30. Catat performa RPS dan Latensi untuk endpoint web (/) lalu bandingkan efek rate limiting ketika menguji endpoint API (/api). Bedakan jenis kegagalan melalui akses log Gojo.
Solusi : Kusakabe dipasang modul apache2-utils. Skenario A (Web) dieksekusi, menghasilkan beban yang semuanya ditangani oleh Cache Gojo. Skenario B (API) dieksekusi dan bertabrakan dengan sistem pembatasan Rate Limit Nginx. Log Gojo diringkas menggunakan script log_summary.sh dengan manipulasi awk/grep.
Script : /root/soal_20.sh (di Kusakabe, instalasi ab) dan /root/log_summary.sh (di Gojo).

[screenshoot]

[screenshoot]

expected output yang muncul : Pada skenario web (/), hasil ab menampilkan Requests per Second (RPS) tinggi (>3000) dan Failed requests bernilai 0 dengan status log 100% cache=HIT. Pada skenario API (/api), RPS turun drastis dan muncul ratusan Failed requests. Log log_summary.sh membuktikan bahwa server worker tidak ada yang mati/error (5xx bernilai 0), dan ratusan kegagalan murni karena ditolak (429) oleh kebijakan limit_req dari Nginx.

## REVISI 
Hampir semuanya dari 11-20 mengalami revisi karena ketidak sesuaian hasil

kesalahan pada hasil yang di terutama yang paling vital adalah nomor 13 yang seharusnya saya yang menghandle malah dihandle oleh Piramidiana, 
