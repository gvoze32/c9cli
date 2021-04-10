#!/bin/bash
read -p "Input User : " user
sleep 3
sudo systemctl stop c9-$user.service
sleep 3
sudo killall -u $user
sleep 3
sudo deluser $user
