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
mkdir bonus-instagram
cd bonus-instagram
mkdir hypervote-v3.1-official
cd hypervote-v3.1-official
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/i9wX.zip
unzip i9wX.zip
rm i9wX.zip
cd ..
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/i-5g.zip
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
git clone https://github.com/officialputuid/toolsig
cd toolsig
npm install
cd ..
git clone https://github.com/sanjidtk/masslooker
git clone https://github.com/gvoze32/massseen
git clone https://github.com/verssache/igviewstory
git clone https://github.com/corrykalam/InstagramAPI
mkdir hypervote-v3.2.1-nulled
cd hypervote-v3.2.1-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/it8C.zip
unzip -P sgbteam it8C.zip
rm it8C.zip
cd ..
mkdir hypervote-v3.2.5-nulled
cd hypervote-v3.2.5-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/iwuh.zip
unzip -P sgbteambos iwuh.zip
rm iwuh.zip
cd ..
mkdir hypervote-v3.3.2-nulled
cd hypervote-v3.3.2-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/hjas.zip 
unzip hjas.zip
rm hjas.zip
cd ..
mkdir hypervote-v3.3.5-nulled
cd hypervote-v3.3.5-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/jkjf.zip 
unzip -P sgbshare jkjf.zip
rm jkjf.zip
cd ..
mkdir hypervote-v3.4.5-nulled
cd hypervote-v3.4.5-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/g8Cl.zip
unzip -P sgbsharenow g8Cl.zip
rm g8Cl.zip
cd ..
mkdir hypervote-v3.6-nulled
cd hypervote-v3.6-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/mo8N.zip
unzip -P sgbteam mo8N.zip
rm mo8N.zip
cd ..
mkdir hypervote-v3.6.2-nulled
cd hypervote-v3.6.2-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/IUs9.zip
unzip -P sgbhypervoting IUs9.zip
rm IUs9.zip
cd ..
mkdir hypervote-v3.8-nulled
cd hypervote-v3.8-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/sfrf.zip
unzip sfrf.zip
rm sfrf.zip
cd ..
mkdir hypervote-v3.8.1-nulled
cd hypervote-v3.8.1-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/fgdh.zip
unzip fgdh.zip
rm fgdh.zip
cd ..
mkdir hypervote-v3.7.9-nulled
cd hypervote-v3.7.9-nulled
wget https://raw.githubusercontent.com/gvoze32/c9tui/master/resources/skdf.zip
unzip skdf.zip
rm skdf.zip
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
