#!/bin/bash
read -p "Input User : " user
read -p "Password : " pw
read -p "Port : " port
cd /home/c9users
rm .env
sudo cat > /home/c9users/.env << EOF
PORT=$port
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
EOF
sudo docker-compose -p $user up -d
if [ -d "/home/c9users/$user" ]; then
cd /home/c9users/$user
mkdir bonus-instagram
cd bonus-instagram
mkdir hypervote-v3.1-official
cd hypervote-v3.1-official
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/i9wX.zip
unzip i9wX.zip
rm i9wX.zip
cd ..
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/i-5g.zip
unzip i-5g.zip
rm i-5g.zip
cd auto_view_story
npm install
cd ..
git clone https://github.com/auliaahmad165/igfeedliker
git clone https://github.com/areltiyan/igfirstcomment
cd igfirstcomment
npm install
cd ..
git clone https://github.com/sandrocods/instagram-views
git clone https://github.com/1F1R5T/storyloop
git clone https://github.com/sanjidtk/sbot
git clone https://github.com/sanjidtk/masslooker
git clone https://github.com/corrykalam/InstagramAPI
mkdir hypervote-v3.2.1-nulled
cd hypervote-v3.2.1-nulled
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/it8C.zip
unzip -P sgbteam it8C.zip
rm it8C.zip
cd ..
mkdir hypervote-v3.2.5-nulled
cd hypervote-v3.2.5-nulled
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/iwuh.zip
unzip -P sgbteambos iwuh.zip
rm iwuh.zip
cd ..
mkdir hypervote-v3.3.2-nulled
cd hypervote-v3.3.2-nulled
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/hjas.zip 
unzip hjas.zip
rm hjas.zip
cd ..
mkdir hypervote-v3.3.5-nulled
cd hypervote-v3.3.5-nulled
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/jkjf.zip 
unzip -P sgbshare jkjf.zip
rm jkjf.zip
cd ..
mkdir hypervote-v3.4.5-nulled
cd hypervote-v3.4.5-nulled
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/g8Cl.zip
unzip -P sgbsharenow g8Cl.zip
rm g8Cl.zip
cd ..
mkdir hypervote-v3.6-nulled
cd hypervote-v3.6-nulled
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/mo8N.zip
unzip -P sgbteam mo8N.zip
rm mo8N.zip
cd ..
mkdir hypervote-v3.6.2-nulled
cd hypervote-v3.6.2-nulled
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/resources/IUs9.zip
unzip -P sgbhypervoting IUs9.zip
rm IUs9.zip
cd
else
echo "Workspace directory not found"
fi
