#!/bin/bash

# COMMANDS

banner() {
    echo "        ___       _ _ "
    echo "   ___ / _ \  ___| (_)"
    echo "  / __| (_) |/ __| | |"
    echo " | (__ \__, | (__| | |"
    echo "  \___|  /_/ \___|_|_|"
    echo
    echo "=====  CLOUD9 CLI MANAGER  ====="
    echo
}
about() {
    echo "Name of File  : c9cli.sh"
    echo "Version       : v4.1 [Budi - Kecekluk] Linux Version"
    echo "Built         : 2024.7 [Kecirit]"
    echo "Tested on     :"
    echo "    - Debian  : Ubuntu 24.04"
    echo
    echo "Built with love♡ by gvoze32"
}
# =========== DON'T CHANGE THE ORDER OF THIS FUNCTION =========== #

bantuan() {
    echo "How to use:"
    echo "Please use sudo!"
    echo "c9cli [command] [argument] [argument]"
    echo
    echo "Commands List:"
    echo "create"
    echo "  workspace   : Create a new SystemD workspace"
    echo "  limit       : Create a new SystemD workspace with limited RAM"
    echo "manage"
    echo "  delete      : Delete workspace"
    echo "  status      : Show workspace status"
    echo "  restart     : Restart workspace"
    echo "  password    : Change user password"
    echo "  schedule    : Schedule workspace deletion"
    echo "  scheduled   : Show scheduled workspace deletion"
    echo "  convert     : Convert user to superuser"
    echo "port          : Show used port lists"
    echo "backup        : Backup workspace data with rclone in one archive"
    echo "help          : Show help"
    echo "version       : Show version"
    echo
    echo "Copyright (c) 2022 c9cli (under MIT License)"
    echo "Built with love♡ by gvoze32"
}

# CREATE SYSTEMD

createnewsystemd(){
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    return 1
fi

read -p "Username : " user
read -s -p "Password : " password
echo
read -p "Port : " port

apt-get update -y
apt-get upgrade -y

adduser --disabled-password --gecos "" $user
echo "$user:$password" | chpasswd

mkdir -p /home/$user/my-projects
mkdir -p /home/$user/c9sdk
chown -R $user:$user /home/$user

sudo -u $user git clone https://github.com/c9/core.git /home/$user/c9sdk

sudo -u $user bash -c "cd /home/$user/c9sdk && sudo rm scripts/install-sdk.sh && sudo wget https://raw.githubusercontent.com/gvoze32/install/master/install-sdk.sh -O scripts/install-sdk.sh && scripts/install-sdk.sh"

chmod 700 /home/$user

cat > /lib/systemd/system/c9-$user.service << EOF
[Unit]
Description=c9 for $user
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
SyslogIdentifier=c9-$user

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable c9-$user.service
systemctl restart c9-$user.service
sleep 10
systemctl status c9-$user.service
}

createnewsystemdlimit(){
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    return 1
fi

read -p "Username : " user
read -s -p "Password : " password
echo
read -p "Memory Limit (Example = 1G) : " mem
read -p "Port : " port

apt-get update -y
apt-get upgrade -y

adduser --disabled-password --gecos "" $user
echo "$user:$password" | chpasswd

mkdir -p /home/$user/my-projects
mkdir -p /home/$user/c9sdk
chown -R $user:$user /home/$user

sudo -u $user git clone https://github.com/c9/core.git /home/$user/c9sdk

sudo -u $user bash -c "cd /home/$user/c9sdk && sudo rm scripts/install-sdk.sh && sudo wget https://raw.githubusercontent.com/gvoze32/install/master/install-sdk.sh -O scripts/install-sdk.sh && scripts/install-sdk.sh"

chmod 700 /home/$user

cat > /lib/systemd/system/c9-$user.service << EOF
[Unit]
Description=c9 for $user
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /home/${user}/c9sdk/server.js -a $user:$password --listen 0.0.0.0 -w /home/$user/my-projects
Environment=NODE_ENV=production PORT=$port
User=$user
Group=$user
UMask=0002
MemoryLimit=$mem
MemoryMax=$mem
Restart=on-failure
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=c9-$user

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable c9-$user.service
systemctl restart c9-$user.service
sleep 10
systemctl status c9-$user.service
}

# MANAGE SYSTEMD

deletesystemd(){
read -p "Input User : " user
sleep 3
sudo systemctl stop c9-$user.service
sleep 3
sudo killall -u $user
sleep 3
sudo userdel $user
rm -rf /home/$user
}

statussystemd(){
read -p "Input User : " user
sudo systemctl status c9-$user.service
}

restartsystemd(){
read -p "Input User : " user
sudo systemctl daemon-reload
sudo systemctl enable c9-$user.service
sudo systemctl restart c9-$user.service
sleep 10
sudo systemctl status c9-$user.service
}

changepasswordsystemd() {
read -p "Input User :" user
read -p "Input New Password :" password

sudo sed -i "s/-a $user:.*/-a $user:$password/" /lib/systemd/system/c9-$user.service
sudo systemctl daemon-reload
sudo systemctl restart c9-$user.service
sleep 10
sudo systemctl status c9-$user.service
}

schedulesystemd(){
read -p "Input User : " user
echo " "
echo "Format Example for Time: "
echo " "
echo "10:00 AM 6/22/2015"
echo "10:00 AM July 25"
echo "10:00 AM"
echo "10:00 AM Sun"
echo "10:00 AM next month"
echo "10:00 AM tomorrow"
echo "now + 1 hour"
echo "now + 30 minutes"
echo "now + 1 week"
echo "now + 1 year"
echo "midnight"
echo " "
read -p "Time: " waktu
at $waktu <<END
sleep 3
sudo systemctl stop c9-$user.service
sleep 3
sudo killall -u $user
sleep 3
sudo userdel $user
END
}

scheduledatq(){
sudo atq
}

convertsystemd(){
read -p "Input User : " user
echo "Input user password"
passwd $user
echo "Warning, C9 will be restart!"
usermod -aG sudo $user
sudo systemctl daemon-reload
sudo systemctl enable c9-$user.service
sudo systemctl restart c9-$user.service
sleep 10
sudo systemctl status c9-$user.service
}

backups(){
echo "=Everyday Backup at 2 AM="
echo "Make sure you have set up an rclone config file using command: rclone config"
echo ""
read -p "If all has been set up correctly, then input your rclone remote name : " name
echo ""
echo "Choose the backup service provider"
echo "1. Google Drive"
echo "2. Storj"
read -r -p "Choose: " response
case "$response" in
    1) 
sudo cat > /home/backup-$name.sh << EOF
#!/bin/bash
date=\$(date +%y-%m-%d)
rclone mkdir $name:Backup/backup-\$date
cd /home
for i in */; do
    zip -r "\${i%/}.zip" "\$i"
done
mkdir /home/backup
mv /home/*.zip /home/backup
rclone copy /home/backup $name:Backup/backup-\$date
rm -rf /home/backup
lines=\$(rclone lsf $name: 2>&1 | wc -l)
if [ \$lines -gt 1 ]
then
    oldbak=\$(rclone lsf $name: 2>&1 | head -n 1)
    rclone purge "$name:\$oldbak"
else
    echo "Old backup not detected, not executing remove command"
fi
EOF
chmod +x /home/backup-$name.sh
echo ""
echo "Backup command created..."
crontab -l > backup-$name
echo "0 2 * * * /home/backup-$name.sh > /home/backup-$name.log 2>&1" >> backup-$name
crontab backup-$name
rm backup-$name
echo ""
echo "Cron job created..."
echo ""
echo "Make sure it's included on your cron list :"
crontab -l
        ;;
    *)
sudo cat > /home/backup-$name.sh << EOF
#!/bin/bash
date=\$(date +%y-%m-%d)
rclone mkdir $name:backup-\$date
cd /home
for i in */; do
    zip -r "\${i%/}.zip" "\$i"
done
mkdir /home/backup
mv /home/*.zip /home/backup/
rclone copy /home/backup/ $name:backup-\$date/
rm -rf /home/backup
lines=\$(rclone lsf $name: 2>&1 | wc -l)
if [ \$lines -gt 1 ]
then
    oldbak=\$(rclone lsf $name: 2>&1 | head -n 1)
    rclone purge "$name:\$oldbak"
else
    echo "Old backup not detected, not executing remove command"
fi
EOF
chmod +x /home/backup-$name.sh
echo ""
echo "Backup command created..."
crontab -l > backup-$name
echo "0 2 * * * /home/backup-$name.sh > /home/backup-$name.log 2>&1" >> backup-$name
crontab backup-$name
rm backup-$name
echo ""
echo "Cron job created..."
echo ""
echo "Make sure it's included on your cron list :"
crontab -l
        ;;
esac
echo "Backup rule successfully added"
}

portlist(){
sudo lsof -i -P -n | grep LISTEN
}

# BASIC MENUS

helps(){
banner
bantuan
}

versions(){
banner
about
}

# MENU

case $1 in
create)
  case $2 in
    workspace)
      createnewsystemd
    ;;
    limit)
      createnewsystemdlimit
    ;;
    *)
      echo "Command not found, type c9cli help for help"
  esac
  ;;
manage)
  case $2 in
    delete)
      deletesystemd
    ;;
    status)
      statussystemd
    ;;
    restart)
      statussystemd
    ;;
    password)
      changepasswordsystemd
    ;;
    schedule)
      schedulesystemd
    ;;
    scheduled)
      scheduledatq
    ;;
    convert)
      convertsystemd
    ;;
    *)
    echo "Command not found, type c9cli help for help"
  esac
;;
port)
  portlist
;;
backup)
  backups
;;
help)
  helps
;;
version)
  versions
;;
*)
echo "Command not found, type c9cli help for help"
esac
