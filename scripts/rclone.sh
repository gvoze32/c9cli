#!/bin/bash
echo "=Everyday Backup at 2 AM="
echo "Make sure you has been setup a rclone config file using command:"
echo "rclone config"
echo ""
echo "If all has been set up correctly, then input your rclone remote name"
read -p "Name : " name
sudo cat > /home/backup-$name.sh << EOF
#!/bin/bash
date=\$(date +%y-%m-%d)
rclone mkdir $name:Backup/backup-\$date
rclone copy /home/ $name:Backup/backup-\$date
EOF
chmod +x /home/backup-$name.sh
crontab -l > backup-$name
echo "0 2 * * * /home/backup-$name.sh > /home/backup-$name.log 2>&1" >> backup-$name
crontab backup-$name
rm backup-$name
echo "Cron List :"
crontab -l
echo ""