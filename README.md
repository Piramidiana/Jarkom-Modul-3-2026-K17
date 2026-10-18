# JARKOM MODUL 3 2026 - K17

## Member

| Nama | NRP | Nomor |
| --- | --- | --- |
| Dian Piramidiana Rachmatika | 5027251031 | 1–10, 13 |
| Jude Athala Yazid sari| | 11-20 |

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

### SOAL11:
Konfigurasi Utahime sebagai DNS Master untuk domain jujutsu.K17.com agar dapat mengarahkan lalu lintas dari jaringan klien menuju public load balancer(Gojo).SOLUSI:Utahime dikonfigurasi menggunakan BIND9 sebagai DNS Master dengan zone jujutsu.K17.com. File zone mengatur A record domain utama ke IP Gojo(10.72.4.21).

SCRIPT DAN FILE KONFIGURASI:
Script: /root/soal_11.sh (dijalankan di Utahime)
Konfigurasi zone: /etc/bind/named.conf.local
File zone: /etc/bind/jujutsu/jujutsu.K17.com

<img width="736" height="402" alt="3_11_FIX BENER ITADORI" src="https://github.com/user-attachments/assets/6bf476eb-1a4e-4a2c-b4c1-c297a07537f8" />

<img width="788" height="431" alt="3_11_FIX ITADORI" src="https://github.com/user-attachments/assets/6baf452b-1c0f-42da-bafd-7d8bdc79101e" />

expected output yang muncul : Hasil uji ping 
;; ANSWER SECTION:
jujutsu.K17.com.    604800    IN    A    10.72.4.21

### Soal 12 — DNS Slave
**SOAL:** Konfigurasikan Utahime sebagai DNS untuk `jujutsu.K17.com`, agar nama domain menuju Gojo. Tambahkan juga alias `www`, reverse lookup, dan penerusan query domain luar. Solusi:Utahime (`10.72.1.2`) menjadi DNS Master. Forward zone mengarahkan domain utama ke Gojo (`10.72.1.4`) dan `www` menjadi CNAME ke domain utama. Reverse zone memetakan `10.72.1.4` kembali ke `jujutsu.K17.com`. Konfigurasi options menggunakan forwarder `192.168.122.1`.

**Script:** `soal_12.sh` — dijalankan/diterapkan di Utahime. File konfigurasi: `/etc/bind/jujutsu/jujutsu.K17.com`, `/etc/bind/jujutsu/10.72.1.rev`, `/etc/bind/named.conf.local`, dan `/etc/bind/named.conf.options`.

<img width="747" height="274" alt="3_12_ItadoriDIG" src="https://github.com/user-attachments/assets/a8d82714-9ce2-41ae-aefb-bf628b8553cc" />

<img width="747" height="274" alt="3_12_ItadoriDIG" src="https://github.com/user-attachments/assets/06837f0e-6bee-414e-ba4d-ca98201c238d" />

<img width="661" height="128" alt="3_12_ItadoriDIG3" src="https://github.com/user-attachments/assets/7ebb47fb-ab86-4493-89c8-b01bb015d376" />

*Expected Output:**

```text
www.jujutsu.K17.com.    ...    IN    CNAME    jujutsu.K17.com.
jujutsu.K17.com.        ...    IN    A        10.72.1.4
```

Untuk `dig -x 10.72.1.4`, jawaban PTR yang diharapkan adalah `jujutsu.K17.com`. Ping `google.com` menguji bahwa DNS forwarder dapat membantu resolusi domain luar. Perintah validasi zone di skrip juga seharusnya berakhir dengan `OK`.


### Soal 13 — Replikasi MariaDB

**SOAL:** Jadikan Yaga sebagai database utama dan Inumaki sebagai replika, sehingga perubahan database di Yaga dapat disalin ke Inumaki.

**Solusi:** Yaga dikonfigurasi dengan `server-id=1`, binary log, dan user replikasi. Inumaki memakai `server-id=2`; lalu dihubungkan ke Yaga dengan `CHANGE MASTER TO`. Data uji dimasukkan di Yaga dan dicari di Inumaki.

**Script:** `soal_13.sh` — konfigurasi MariaDB di Yaga dan Inumaki. File konfigurasi: `/etc/mysql/mariadb.conf.d/50-server.cnf`.

**Expected Output:**

```text
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

Setelah insert uji di Yaga, query di Inumaki diharapkan menemukan baris `replication-test` yang sama.

**Perlu dikonfirmasi:** bukti terakhir yang tercatat sebelumnya menunjukkan error replikasi `1593` akibat server ID yang sama, dan belum ada hasil akhir yang memastikan masalah itu sudah selesai. Selain itu, posisi log pada `CHANGE MASTER TO` harus mengikuti hasil `SHOW MASTER STATUS` terkini, bukan otomatis memakai nilai contoh dari skrip. Pembuatan tabel di bagian awal skrip juga belum mencantumkan semua kolom wajib yang dipakai pada insert uji.

<img width="658" height="143" alt="3_13_Inumaki sinkron dengan yaga" src="https://github.com/user-attachments/assets/c07ad313-9277-4340-a1e9-141c0b17ef51" />

<img width="922" height="131" alt="3_13_Yaga" src="https://github.com/user-attachments/assets/dbbc5b69-bdd7-48b2-bbf5-52b25623155a" />

<img width="674" height="523" alt="3_13_YES INUMAKI" src="https://github.com/user-attachments/assets/a6ef4e70-a601-4c3a-988b-adabf65e5690" />


Script: `perquest-scripts/soal_13.sh`, `nodes/yaga/soal_13_master.sh`, `nodes/inumaki/soal_13_slave.sh`.

![Master](assets/JARKOM%233_13_master-status.png)
![Slave](assets/JARKOM%233_13_slave-status.png)
![Replikasi realtime](assets/JARKOM%233_13_replikasi-realtime.png)
![Setelah restart](assets/JARKOM%233_13_setelah-restart.png)

Hasil: `Slave_IO_Running` dan `Slave_SQL_Running` Yes. Baris yang dimasukkan di yaga langsung muncul di inumaki. User `k17` dapat login dari node Network 4. Setelah kedua node di-restart, data tetap ada dan replikasi tersambung kembali.

### Soal 14–20 — Web, Load Balancer, Proxy (Jude)

### Soal 14 — Reverse Proxy dan Load Balancing

**SOAL:** Gunakan Geto sebagai reverse proxy untuk meneruskan request ke frontend Maki/Panda atau backend API.

**Solusi:** Geto (`10.72.4.20`) menerima request. Request halaman biasa diteruskan ke frontend pool Maki (`10.72.4.3`) dan Panda (`10.72.4.4`); request `/api` diteruskan ke backend Nanami (`10.72.4.31`), Todo (`10.72.4.32`), atau Kirara (`10.72.4.33`). Maki dan Panda perlu route balik melalui `10.72.4.1` agar bisa menjawab request dari jaringan lain.

**Script:** `soal_14.sh` — bagian Geto, frontend workers, backend workers, dan client. Nginx utama: `/etc/nginx/nginx.conf`; file PHP backend: `/var/www/api/index.php`.

**Expected Output:**

```text
HTTP/1.1 200 OK
X-Served-By: Maki
```

Request berikutnya dapat menunjukkan Panda. Untuk `/api`, hasilnya berupa JSON sukses dengan nama worker, misalnya Nanami atau Todo. Hasil terminal yang pernah kamu kirim menunjukkan kedua frontend membalas `200 OK` dan endpoint API berhasil.

**Catatan:** skrip memuat konfigurasi server di `nginx.conf` sekaligus include ke `sites-enabled`; pastikan tidak ada server block duplikat atau beberapa `default_server`.

<img width="757" height="475" alt="3_14_FIXX_ITADORI KELARRRR" src="https://github.com/user-attachments/assets/9a0751b6-f5f1-4b98-b9f9-a5e8f184a7d2" />

### Soal 15 — Weighted Load Balancing 3:1

**SOAL:** Atur pembagian request API agar Nanami menerima bobot tiga kali Todo.

**Solusi:** Geto membuat upstream `api_cluster` dengan Nanami (`10.72.4.31`) berbobot 3 dan Todo (`10.72.4.32`) berbobot 1. Request API dari client dikirim ke Geto (`10.72.4.20`), lalu dibagi ke kedua backend.

**Script:** `soal_15.sh` — konfigurasi Nginx Geto di `/etc/nginx/nginx.conf`; tes request dijalankan dari Itadori.

**Expected Output:**

```json
{"status":"success","worker":"Nanami"}
{"status":"success","worker":"Todo"}
```

Dalam kumpulan request yang cukup, Nanami seharusnya menerima lebih banyak request daripada Todo. Pengujian delapan request yang pernah kamu laporkan menghasilkan Nanami enam kali dan Todo dua kali, sesuai rasio 3:1 pada tes tersebut. Urutan respons tidak harus selalu berpola tetap.

<img width="619" height="142" alt="3_15 FIX BENER" src="https://github.com/user-attachments/assets/3fbb10a8-fb66-4c9a-ba02-0c7d7e441c6d" />


### Soal 16 — Path-Based Routing melalui Gojo

**SOAL:** Jadikan Gojo sebagai gateway publik yang memilih tujuan berdasarkan path: halaman web ke frontend dan `/api` ke Geto.

**Solusi:** Gojo (`10.72.1.4`) meneruskan request `/` ke Maki/Panda (`10.72.4.3` dan `.4`). Request `/api` diteruskan ke Geto (`10.72.4.20`), yang kemudian memilih backend API.

**Script:** `soal_16.sh` — konfigurasi Nginx Gojo: `/etc/nginx/nginx.conf`.

**Expected Output:**

- Akses `/` menampilkan halaman frontend dari Maki atau Panda.
- Akses `/api` mengembalikan JSON dari backend, misalnya Nanami atau Todo.
- Nginx lolos `nginx -t` sebelum restart.

Tes yang pernah kamu kirim menunjukkan halaman Gojo berhasil dan pembagian API delapan request menghasilkan Nanami enam kali, Todo dua kali.\

<img width="959" height="594" alt="3_16_FIX BERHASIL ITADORI" src="https://github.com/user-attachments/assets/468d816d-6547-49e8-b4dd-01a35cd3d602" />



### Soal 17 — Meneruskan IP Client dan Mencatat Request

**SOAL:** Teruskan alamat IP client melewati Gojo dan Geto hingga backend API, lalu simpan informasi request ke database Yaga.

**Solusi:** Gojo mengirim `X-Real-IP` dan `X-Forwarded-For` ke Geto. Geto meneruskan IP asli tersebut ke API backend. PHP backend menyimpan `worker_name`, `client_ip`, `proxy_ip`, `user_agent`, dan `log_message` ke tabel `request_logs` di Yaga.

**Script:** `soal_17.sh` — Nginx Gojo dan Geto, serta PHP di backend. File terkait: `/etc/nginx/nginx.conf` dan `/var/www/api/index.php`.

**Expected Output:**

```json
{"status":"success","worker":"Nanami","client_ip":"..."}
```

Di database Yaga, baris request yang sama diharapkan menyimpan IP client pada `client_ip` dan alamat proxy Geto pada `proxy_ip`. Nilai `client_ip` bergantung pada node asal request; pengujian yang pernah dilaporkan mencatat client Gojo `10.72.1.4` dan proxy Geto `10.72.4.20`.

<img width="958" height="563" alt="3_17_dari gojo" src="https://github.com/user-attachments/assets/07defec3-d3f6-4dc5-bf89-c353a9d629b2" />


<img width="818" height="135" alt="3_17_dari yaga" src="https://github.com/user-attachments/assets/69f3677b-3678-41fd-989d-3b76187c6875" />


### Soal 18 — API Backup dan Failover

**SOAL:** Sediakan Kirara sebagai backend cadangan apabila Nanami dan Todo tidak bisa melayani request.

**Solusi:** Geto mengatur upstream `api_cluster` dengan Nanami berbobot 3, Todo berbobot 1, dan Kirara (`10.72.4.33`) sebagai `backup`. Jika backend utama gagal, Nginx dapat mencoba Kirara. PHP Kirara mencatat kolom wajib request ke Yaga dan mengembalikan JSON.

**Script:** `soal_18.sh` — PHP dan Nginx Kirara, konfigurasi upstream Geto, serta instruksi pengujian failover.

**Expected Output:**

```json
{"status":"success","worker":"Kirara","client_ip":"10.72.2.10"}
```

Output itu sudah kamu dapat dari Itadori ketika Nanami dan Todo dihentikan; artinya request berhasil dialihkan ke backend cadangan Kirara. Hidupkan kembali Nginx di Nanami dan Todo setelah simulasi.

<img width="959" height="566" alt="3_18_FIX hasil dari Itadori Dan worker" src="https://github.com/user-attachments/assets/c11b0be3-fa2c-4e85-87d8-cc39efa83600" />

<img width="901" height="569" alt="3_18_FIX failover itadori" src="https://github.com/user-attachments/assets/52765d7d-2e8a-4527-861e-57c8da381aa4" />


### Soal 19 — Proxy Cache dan Rate Limiting

**SOAL:** Aktifkan cache pada halaman frontend dan batasi laju request ke API agar request berlebihan dapat ditolak.

**Solusi:** Gojo menyimpan cache frontend di `/var/cache/nginx/jujutsu_cache`. Cache valid selama 10 menit untuk respons `200`/`302`. Endpoint `/api` dibatasi `10r/s` per IP dengan `burst=5 nodelay`; request berlebih dapat mendapat `503`.

**Script:** `soal_19.sh` — konfigurasi Gojo di `/etc/nginx/nginx.conf`; pengujian dijalankan dari Itadori.

**Expected Output:**

```text
X-Cache-Status: MISS
X-Cache-Status: HIT
```

Gunakan URL unik yang sama dua kali agar tes menunjukkan cache baru diisi lalu digunakan. Request cepat ke API dapat menghasilkan campuran `200` dan `503`. Kamu sudah mengamati `200` serta `503`, dan header cache menunjukkan `HIT`.

**Perlu dikonfirmasi:** tes langsung dari Geto ke Nanami, Todo, dan Kirara menghasilkan JSON yang benar, tetapi output API melalui Gojo sebelumnya sempat berisi teks tidak wajar di field `status`. Tes ulang isi JSON melalui Gojo sebelum demo; status `200` saja belum memastikan isi respons API benar.

<img width="959" height="585" alt="3_19_FIX BENERR " src="https://github.com/user-attachments/assets/bba62645-0e29-4ebe-9489-5c9ed00a9aa7" />


### Soal 20 — Benchmark dan Pemeriksaan Log

**SOAL:** Uji banyak request ke halaman utama, ukur waktu request, dan amati efek rate limiting pada endpoint API melalui access log Gojo.

**Solusi:** Dari Itadori/Kusakabe, skrip mengirim 100 request ke halaman utama dan 30 request cepat ke API. Di Gojo, access log digunakan untuk melihat status respons, termasuk request sukses dan yang ditolak oleh rate limit.

**Script:** `soal_20.sh` — tes dari Itadori/Kusakabe; log di Gojo pada `/var/log/nginx/access.log`.

**Expected Output:** benchmark menampilkan waktu total dari `time`; request API menampilkan kode status, yang dapat mencakup `200` dan `503` ketika limit terlampaui. Access log Gojo seharusnya mencatat status request tersebut.

**Perlu diperbaiki sebelum demo:** kedua URL di skrip berisi typo `10.72..1.4`. Seharusnya `10.72.1.4`; jika tidak, tes benchmark dan API tidak menuju alamat Gojo yang benar.

<img width="959" height="599" alt="3_20_FIX BENER ITADORI" src="https://github.com/user-attachments/assets/e1e151d3-2939-4292-ab1a-a924c9b5b15b" />

<img width="938" height="563" alt="3_20_FIX BENER GOJO" src="https://github.com/user-attachments/assets/d7aca285-fdf4-4108-9234-fce973d23130" />


## REVISI 
Hampir semuanya dari 11-20 mengalami revisi karena ketidak sesuaian hasil

kesalahan pada hasil yang di terutama yang paling vital adalah nomor 13 yang seharusnya saya yang menghandle malah dihandle oleh Piramidiana, 
