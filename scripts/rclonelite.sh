#!/bin/bash
# BETA: ONLY SUPPORT DOCKERMEMLIMIT
echo "=Everyday Backup at 2 AM="
echo "Make sure you has been setup a rclone config file using command: rclone config"
echo ""
read -p "If all has been set up correctly, then input your rclone remote name : " name
sudo cat > /home/backup-$name.sh << EOF
#!/bin/bash
date=\$(date +%y-%m-%d)
rclone mkdir $name:Backup/backup-\$date
cd /home/c9usersmemlimit
for i in */; do zip -r "\${i%/}.zip" "\$i"; done
mkdir backup
mv *.zip backup
rclone copy backup $name:Backup/backup-\$date
rm -rf backup
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