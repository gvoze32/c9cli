#!/bin/bash
echo "=Everyday Backup at 2 AM="
echo "Make sure you has been setup a rclone config file using command:"
echo "rclone config"
echo ""
echo "If all has been set up correctly, then input your rclone remote name"
read -p "Name : " name
sudo wget https://raw.githubusercontent.com/gvoze32/C9IDECoreDeploy/master/misc/backup.sh -O /home/backup-$name.sh
chmod +x /home/backup-$name.sh
crontab -l > backup-$name
echo "0 2 * * * /home/backup-$name.sh > /home/backup-$name.log 2>&1" >> backup-$name
crontab backup-$name
rm backup-$name
echo "Cron List"
crontab -l
echo "Backup Executable File, check if it's correct"
cat /home/backup-$name.sh