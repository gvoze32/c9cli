#!/bin/bash
date=$(date +%y-%m-%d)
rclone mkdir $name:Backup/backup-$date
rclone copy /home/ $name:Backup/backup-$date