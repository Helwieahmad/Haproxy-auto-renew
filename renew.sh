#!/bin/bash
for i in $( ls /etc/letsencrypt/live ); do

web_service='haproxy'
config_file='/usr/local/bin/le-renew-haproxy.ini'
domain=$i
http_01_port='80'
combined_file="/etc/haproxy/certs/${domain}.pem"

le_path='/usr/bin'
exp_limit=60;

if [ ! -f $config_file ]; then
        echo "[ERROR] File Konfigurasi Tidak Ada: $config_file"
        exit 1;
fi

cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
key_file="/etc/letsencrypt/live/$domain/privkey.pem"

if [ ! -f $cert_file ]; then
	echo "[ERROR] File sertifikat Tidak ditemukan pada Domain $domain."
fi

exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
datenow=$(date -d "now" +%s)
days_exp=$(echo \( $exp - $datenow \) / 86400 |bc)

echo "Mengechek Tanggal Kadaluarsa Untuk Domain $domain..."

if [ "$days_exp" -gt "$exp_limit" ] ; then
	echo "Sertikat SSL pada Domain $domain Masih Aktif dan Belum Membutuhkan Pembaruan. (SSL Kadaluarsa Masih $days_exp Hari Lagi)."
else
	echo "Menghentikan Sementara Service $web_service"
	/usr/sbin/service $web_service stop
	echo " Sertifikat Untuk Domain $domain Akan Segera Kadaluarsa. Lets Encrypt Mulai (Haproxy:$http_01_port) Memperbarui Script..."
	$le_path/certbot certonly --standalone --preferred-challenges http --renew-by-default --http-01-port $http_01_port -d $domain -d $domain 
	echo "Membuat File $combined_file Dengan Cert Terbaru Pada Domain $domain..."
	sudo bash -c "cat /etc/letsencrypt/live/$domain/fullchain.pem /etc/letsencrypt/live/$domain/privkey.pem > $combined_file"

	echo "Memuat Ulang Service $web_service"
	/usr/sbin/service $web_service start
	echo "Proses Pembaruan SSL Untuk Domain $domain Sukses Diperbarui."
fi
done
