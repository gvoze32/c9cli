#!/bin/bash
read -p "Input User : " user
read -p "Password : " pw
read -p "Port : " port
sudo cat > /home/c9users/$user.env << EOF
PORT=$port
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
EOF
sudo docker-compose --env-file=$user.env -p $user.env up -d
cd /home/c9users/$user
mkdir bonus-instagram
cd bonus-instagram
mkdir hypervote-nulled
cd hypervote-nulled
wget https://0x0.st/i-ND.zip
unzip i-ND.zip
cd ..
mkdir hypervote-original
cd hypervote-original
wget https://0x0.st/i9wX.zip
unzip i9wX.zip
cd ..
wget https://0x0.st/i-5g.zip
unzip i-5g.zip
cd auto_view_story
npm install
cd ..
git clone https://github.com/officialputuid/toolsig
cd toolsig
unzip lib.zip
cd ..
git clone https://github.com/ikiganteng/toolsigeh
git clone https://github.com/auliaahmad165/igfeedliker
git clone https://github.com/areltiyan/igfirstcomment
git clone https://github.com/sandrocods/instagram-views
git clone https://github.com/nthanfp/storyloop
git clone https://github.com/corrykalam/InstagramAPI
git clone https://github.com/ppabcd/Instagram-Story-Downloader
