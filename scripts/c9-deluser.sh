#!/bin/bash
read -p "Input User : " user
systemctl stop c9-$user.service
sudo killall -u $user && sudo deluser --remove-home -f $user
