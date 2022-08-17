#!/bin/bash
read -p "Input User : " user
read -p "Password : " pw
read -p "Port : " port
cd /home/c9users
rm .env
sudo cat > /home/c9users/.env << EOF
PORT=$port
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
EOF
sudo docker-compose -p $user up -d
if [ -d "/home/c9users/$user" ]; then
cd /home/c9users/$user

### Your custom default bundling files goes here, it's recommended to put it on resources directory
### START

### END

cd
else
echo "Workspace directory not found"
fi
