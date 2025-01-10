#!/bin/bash

# Check Ubuntu Version
ubuntu_version=$(lsb_release -r | awk '{print $2}')
echo "Checking Ubuntu Version.."
echo "Ubuntu version is $ubuntu_version"
echo "Installing dependencies.."

install_docker_app() {
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Initialize Docker Swarm
    if ! docker info | grep -q "Swarm: active"; then
        echo "Initializing Docker Swarm..."
        docker swarm init --advertise-addr $(curl -s ifconfig.me) || {
            echo "Failed to initialize swarm"
            return 1
        }
    else
        echo "Swarm is already initialized"
    fi
}

# Hapus/komen fungsi install_docker dan install_docker_memlimit karena sudah tidak digunakan
# install_docker() { ... }
# install_docker_memlimit() { ... }

blank_env() {
    # Tidak lagi diperlukan karena menggunakan Docker configs
    echo "Using Docker configs instead of .env files"
}

custom_docker_size() {
    echo "Creating /etc/docker/daemon.json file"
    echo "Setting custom Docker default address pools"
    sudo cat >/etc/docker/daemon.json <<EOF
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
    echo "Docker default address pools set to 10.10.0.0/16 with size 24"
}

install_ioncube() {
    curl -O https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
    tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
    rm ioncube_loaders_lin_x86-64.tar.gz
    cd ioncube
    php_ext_dir="$(command php -i | grep extension_dir 2>'/dev/null' |
        command head -n 1 |
        command cut --characters=31-38)"
    php_version="$(command php --version 2>'/dev/null' |
        command head -n 1 |
        command cut --characters=5-7)"
    cp ioncube_loader_lin_${php_version}.so /usr/lib/php/${php_ext_dir}
    cd ..
    rm -rf ioncube
    cat >/etc/php/${php_version}/cli/conf.d/00-ioncube-loader.ini <<EOF
zend_extension=ioncube_loader_lin_${php_version}.so
EOF
    php -v
}

update_packages() {
    sudo DEBIAN_FRONTEND=noninteractive apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    sudo DEBIAN_FRONTEND=noninteractive apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
}

second_dep() {
    sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common
}

pip_dep() {
    sudo apt install -y python3-pip
    python3 -m pip install requests selenium colorama bs4 wget pyfiglet
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | sudo python2 -
    python2 -m pip install requests selenium colorama bs4 wget pyfiglet
}

case $ubuntu_version in
22.04)
    # Set NEEDRESTART frontend to avoid prompts
    sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_SUSPEND=1
    export NEEDRESTART_MODE=l

    echo "Setting up Ubuntu $ubuntu_version.."

    # Update packages
    update_packages

    # Install dependencies
    sudo apt install -y at git nodejs npm build-essential php php8.1-common php-gd php-mbstring php-curl php8.1-mysql php-json php8.1-xml php-fpm python2 python3 zip unzip dos2unix
    pip_dep
    systemctl start atd
    second_dep

    # Install rclone
    curl https://rclone.org/install.sh | sudo bash

    install_docker_app
    blank_env
    custom_docker_size

    # Install ioncube
    install_ioncube
    ;;
20.04)
    # Set NEEDRESTART frontend to avoid prompts
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_SUSPEND=1
    export NEEDRESTART_MODE=l

    echo "Setting up Ubuntu $ubuntu_version.."

    # Update packages
    update_packages

    # Install dependencies
    sudo apt install -y at git nodejs npm build-essential php7.4-cli php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python2 python3 zip unzip dos2unix
    pip_dep
    systemctl start atd
    second_dep

    # Install rclone
    curl https://rclone.org/install.sh | sudo bash

    install_docker_app
    blank_env
    custom_docker_size

    # Install ioncube
    install_ioncube
    ;;
18.04)
    echo "Setting up Ubuntu $ubuntu_version.."

    # Update packages
    update_packages

    # Install dependencies
    sudo apt install -y curl at git nodejs npm build-essential php php7.2-common php-gd php-mbstring php-curl php7.2-mysql php-json php7.2-xml php-fpm python2-minimal python3 zip unzip dos2unix
    pip_dep
    systemctl start atd
    second_dep

    # Install rclone
    curl https://rclone.org/install.sh | sudo bash

    install_docker_app
    blank_env
    custom_docker_size

    # Install ioncube
    install_ioncube
    ;;
esac
