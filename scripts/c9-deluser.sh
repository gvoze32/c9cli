#!/bin/bash
read -p "Input User : " user
sleep 10
sudo systemctl stop c9-$user.service
sleep 10
sudo killall -u $user
sleep 10
sudo deluser --remove-home -f $user
