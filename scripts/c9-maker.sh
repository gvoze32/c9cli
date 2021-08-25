#!/bin/bash
#Run as sudo or root user
read -p "Input User : " user
read -p "Input Password : " password
read -p "Input Port (Recomend Range : 1000-5000) : " port

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get update -y

#Create User
sudo adduser --disabled-password --gecos "" $user

#echo "$password" | passwd --stdin $user
sudo echo -e "$password\n$password" | passwd $user
mkdir -p /home/$user/my-projects
cd /home/$user/my-projects

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

#Get script to user directory
git clone https://github.com/c9/core.git /home/$user/c9sdk
sudo chown $user.$user /home/$user -R
sudo -u $user -H sh -c "cd /home/$user/c9sdk; scripts/install-sdk.sh"
sudo chown $user.$user /home/$user/ -R
sudo chmod 700 /home/$user/ -R
sudo cat > /lib/systemd/system/c9-$user.service << EOF

# Run:
# - systemctl enable c9
# - systemctl {start,stop,restart} c9
#
[Unit]
Description=c9
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /home/${user}/c9sdk/server.js -a $user:$password --listen 0.0.0.0 -w /home/$user/my-projects
Environment=NODE_ENV=production PORT=$port
User=$user
Group=$user
UMask=0002
Restart=on-failure

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=c9

[Install]
WantedBy=multi-user.target
#End
EOF

sudo systemctl daemon-reload
sudo systemctl enable c9-$user.service
sudo systemctl restart c9-$user.service
sleep 10
sudo systemctl status c9-$user.service
