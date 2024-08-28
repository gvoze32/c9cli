#!/bin/bash

# Check Ubuntu Version
# Recommended for Ubuntu 24.04 (Noble Numbat) and above.
ubuntu_version=$(lsb_release -r | awk '{print $2}')
echo "Checking Ubuntu Version.."
echo "Ubuntu version is $ubuntu_version"
echo "Installing dependencies.."

#Variables
USER_HOME=$(eval echo ~$USER)

install_docker_app() {
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update

        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker() {
        sudo adduser --disabled-password --gecos "" c9users
        sudo cat > /home/c9users/docker-compose.yml << EOF
services:
  code-server:
    image: lscr.io/linuxserver/cloud9:latest
    container_name: code-\${NAMA_PELANGGAN}
    environment:
      - TZ=Asia/Jakarta
      - USERNAME=\${NAMA_PELANGGAN}
      - PASSWORD=\${PASSWORD_PELANGGAN}
    volumes:
      - /home/c9users/\${NAMA_PELANGGAN}:/workspace
    ports:
      - \${PORT}:8443
    restart: always
EOF
}

install_docker_memlimit() {
        sudo adduser --disabled-password --gecos "" c9usersmemlimit
        sudo cat > /home/c9usersmemlimit/docker-compose.yml << EOF
services:
  code-server:
    image: lscr.io/linuxserver/cloud9:latest
    container_name: code-\${NAMA_PELANGGAN}
    environment:
      - TZ=Asia/Jakarta
      - USERNAME=\${NAMA_PELANGGAN}
      - PASSWORD=\${PASSWORD_PELANGGAN}
    volumes:
      - /home/c9usersmemlimit/\${NAMA_PELANGGAN}:/workspace
    ports:
      - \${PORT}:8443
    restart: always
    deploy:
      resources:
        limits:
          memory: \${MEMORY}
EOF
}

blank_env() {
        > /home/c9users/.env
        > /home/c9usersmemlimit/.env
}

custom_docker_size(){
        read -p "Increase docker network limit to more than 30 containers? [y/N] (Default = n): " choice
        if [[ $choice == [yY] || $choice == [yY][eE][sS] ]]; then
            echo "Setting docker daemon service rule.."
            sudo cat > /etc/docker/daemon.json << EOF
{
    "default-address-pools": [
        {
            "base": "10.10.0.0/16",
            "size": 24
        }
    ]
}
EOF
            sudo service docker restart
            sudo docker network inspect bridge | grep Subnet
            echo "Done."
        else
            echo ""
            echo "==============================="
            echo " Default docker version is set "
            echo "==============================="
            echo ""
            echo ""
        fi
}

install_ioncube(){
        curl -O https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
        tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
        rm ioncube_loaders_lin_x86-64.tar.gz
        cd ioncube
        php_ext_dir="$(command php -i | grep extension_dir 2>'/dev/null' \
            | command head -n 1 \
            | command cut --characters=31-38)"
        php_version="$(command php --version 2>'/dev/null' \
            | command head -n 1 \
            | command cut --characters=5-7)"
        cp ioncube_loader_lin_${php_version}.so /usr/lib/php/${php_ext_dir}
        cd ..
        rm -rf ioncube
        cat > /etc/php/${php_version}/cli/conf.d/00-ioncube-loader.ini << EOF
zend_extension=ioncube_loader_lin_${php_version}.so
EOF
        php -v
}

case $ubuntu_version in
    18.04)
        echo "Setting up Ubuntu $ubuntu_version.."

        # Update packages
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt update -y

        # Install dependencies
        sudo apt install -y curl at git nodejs npm build-essential php php7.2-common php-gd php-mbstring php-curl php7.2-mysql php-json php7.2-xml php-fpm python python2.7 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        pip3 install requests selenium colorama bs4 wget pyfiglet
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        install_docker_app
        install_docker
        install_docker_memlimit
        blank_env
        custom_docker_size
        
        # Install ioncube
        install_ioncube

        #Cleanup
        rm get-pip.py install.sh
        ;;
esac
