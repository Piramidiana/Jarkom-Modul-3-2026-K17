# 1. NODE ITADORI / KUSAKABE (PENGUJIAN BENCHMARK KLIEN)

# A. Uji kapasitas / benchmark halaman utama (/) dengan 100 request beruntun:
time for i in {1..100}; do curl -s -I -H "Host: jujutsu.K17.com" http://10.72..1.4/ > /dev/null; done

# B. Uji efek rate limiting pada endpoint /api (mengirim 30 request cepat untuk menguji batas 10 req/s):
for i in {1..30}; do echo -n "Request $i: "; curl -s -I -H "Host: jujutsu.K17.com" http://10.72..1.4/api | head -n 1; done



# 2. NODE GOJO (PEMERIKSAAN ACCESS LOG NGINX)

# Jalankan perintah berikut di terminal gojo untuk melihat rincian status request 
# (membedakan status 200 OK yang sukses dengan status 503 yang diblokir rate limit):
nano /var/log/nginx/access.log
# Atau gunakan tail untuk memantau log secara real-time / baris terakhir:
tail -n 30 /var/log/nginx/access.log
