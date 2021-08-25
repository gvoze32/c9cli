#!/bin/bash
read -p "Input User : " user
read -p "Password : " pw
read -p "Port : " portenv
read -p "CPU Limit (Example = 1) : " cpu
read -p "Memory Limit (Example = 1024m) : " mem
cd /home/c9usersmemlimit
rm .env
sudo cat > /home/c9usersmemlimit/.env << EOF
PORT=$portenv
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
MEMORY=$mem
CPUS=1
EOF
sed -i '$ d' /home/c9usersmemlimit/docker-compose.yml
sed -i '$ d' /home/c9usersmemlimit/docker-compose.yml
echo "    mem_limit: $mem" >> /home/c9usersmemlimit/docker-compose.yml
echo "    cpus: $cpu" >> /home/c9usersmemlimit/docker-compose.yml
sudo docker-compose -p $user up -d
if [ -d "/home/c9usersmemlimit/$user" ]; then
cd /home/c9usersmemlimit/$user

### Your custom default bundling files goes here, it's recommended to put it on resources directory
### START
curl -O https://raw.githubusercontent.com/gvoze32/c9tui/master/scripts/firstinstall.sh
sudo cat > README.TXT << EOF
Sebelum memulai, sangat disarankan untuk menginstall PHP, IonCube dan Node.js secara otomatis dengan perintah:
bash firstinstall.sh

1. Apa spesifikasi workspace yang saya dapat?
Workspace C9 dibuat menggunakan docker dengan image Debian dengan beberapa konfigurasi limit agar tidak terjadi overload pada server utama

2. Apakah saya dapat user root?
Mendapatkan user root, kalian dapat menginstall atau merubah konfigurasi sesuka hati

3. Apa yang harus saya lakukan ketika baru mendapatkan workspace?
Silahkan lakukan update dan upgrade base system kamu agar saling terintegrasi dengan cara menjalankan perintah "apt update" dan "apt upgrade"

4. Bagaimana cara menginstall package?
Gunakan perintah "apt" atau "apt-get" dilanjutkan dengan nama package yang akan diinstall

5. Bagaimana cara menjalankan program?
Tergantung menggunakan bahasa apa program tersebut, contohnya:

PHP: php namafile.php
Node.js: node namafile.js
Python: python namafile.py

6. Membuka via Android?
Silahkan gunakan keyboard tambahan Hacker Keyboard atau BeHe Keyboard

7. Bagaimana cara mengatasi error bot WhatsApp?
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install ./google-chrome-stable_current_amd64.deb
npm install
EOF
### END

cd
else
echo "Workspace directory not found"
fi
