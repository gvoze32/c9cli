#!/bin/bash
#Run as sudo or root user
read -p "Input User : " user
read -p "Input Password : " password
read -p "Input Port (Recomend Range : 1000-5000) : " port

sudo apt-get update && apt-get upgrade
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
sudo apt-get install -y curl git build-essential nodejs npm php php-exif php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python-pip python3-pip python python2.7 python-pyfiglet build-essential zip unzip unp unrar unrar-free unar p7zip
pip install requests selenium colorama bs4

#Create User
sudo adduser --disabled-password --gecos "" $user

#echo "$password" | passwd --stdin $user
sudo echo -e "$password\n$password" | passwd $user
mkdir -p /home/$user/my-projects
cd /home/$user/my-projects
wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/bonus-instagram.sh
bash bonus-instagram.sh
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
