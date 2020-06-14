#!/bin/bash
read -p "Input User : " user
sudo systemctl stop c9-$user.service
sleep 10
sudo killall -u $user
sudo deluser --remove-home -f $user
