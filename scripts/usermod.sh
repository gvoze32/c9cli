#!/bin/bash
read -p "Input User : " user
echo "Input user password"
passwd user
echo "Warning, C9 will be restart!"
usermod -aG sudo user
sudo systemctl daemon-reload
sudo systemctl enable c9-$user.service
sudo systemctl restart c9-$user.service
sleep 10
sudo systemctl status c9-$user.service