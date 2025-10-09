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
}

install_docker() {
        sudo adduser --disabled-password --gecos "" c9users
        sudo cat >/home/c9users/docker-compose.yml <<EOF
services:
  cloud9:
    image: \${DOCKER_IMAGE}
    container_name: c9-\${NAMA_PELANGGAN}
    environment:
      - TZ=Asia/Jakarta
      - USERNAME=\${NAMA_PELANGGAN}
      - PASSWORD=\${PASSWORD_PELANGGAN}
    volumes:
      - /home/c9users/\${NAMA_PELANGGAN}:/workspace
    ports:
      - \${PORT}:8000
    restart: always
EOF
}

install_docker_memlimit() {
        sudo adduser --disabled-password --gecos "" c9usersmemlimit
        sudo cat >/home/c9usersmemlimit/docker-compose.yml <<EOF
services:
  cloud9:
    image: \${DOCKER_IMAGE}
    container_name: c9-\${NAMA_PELANGGAN}
    environment:
      - TZ=Asia/Jakarta
      - USERNAME=\${NAMA_PELANGGAN}
      - PASSWORD=\${PASSWORD_PELANGGAN}
    volumes:
      - /home/c9usersmemlimit/\${NAMA_PELANGGAN}:/workspace
    ports:
      - \${PORT}:8000
    restart: always
    deploy:
      resources:
        limits:
          memory: \${MEMORY}
          cpus: \${CPU_LIMIT}
EOF
}

blank_env() {
        >/home/c9users/.env
        >/home/c9usersmemlimit/.env
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

update_packages() {
        sudo DEBIAN_FRONTEND=noninteractive apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
        sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
        sudo DEBIAN_FRONTEND=noninteractive apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
}

second_dep() {
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common
}

ensure_python2() {
        if command -v python2 >/dev/null 2>&1; then
                echo "Python2 already installed."
                return 0
        fi

        if [[ "$ubuntu_version" = "24.04" || "$ubuntu_version" = "22.04" ]]; then
                sudo apt install -y software-properties-common
                if ! ls /etc/apt/sources.list.d/ | grep -qi "deadsnakes" 2>/dev/null; then
                        sudo add-apt-repository -y ppa:deadsnakes/ppa
                fi
        fi

        sudo apt update
        if sudo apt install -y python2; then
                return 0
        fi

        if sudo apt install -y python2-minimal; then
                return 0
        fi

        echo "Python2 is not available via apt; skipping Python2 installation."
        return 1
}

start_atd() {
        if systemctl list-unit-files | grep -q '^atd.service'; then
                sudo systemctl enable --now atd.service
        else
                echo "atd.service not found; skipping at daemon setup."
        fi
}

pip_dep() {
        sudo apt install -y python3-pip
        python3 -m pip install requests selenium colorama bs4 wget pyfiglet
        if ensure_python2; then
                curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | sudo python2 -
                python2 -m pip install requests selenium colorama bs4 wget pyfiglet
        else
                echo "Skipping Python2 pip dependencies."
        fi
}

case $ubuntu_version in
24.04)
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
        sudo apt install -y curl at git nodejs npm build-essential python3 zip unzip
        pip_dep
        start_atd
        second_dep

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        install_docker_app
        install_docker
        install_docker_memlimit
        blank_env
        custom_docker_size
        ;;
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
        sudo apt install -y curl at git nodejs npm build-essential python3 zip unzip
        pip_dep
        start_atd
        second_dep

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        install_docker_app
        install_docker
        install_docker_memlimit
        blank_env
        custom_docker_size
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
        sudo apt install -y curl at git nodejs npm build-essential python3 zip unzip
        pip_dep
        start_atd
        second_dep

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        install_docker_app
        install_docker
        install_docker_memlimit
        blank_env
        custom_docker_size
        ;;
18.04)
        echo "Setting up Ubuntu $ubuntu_version.."

        # Update packages
        update_packages

        # Install dependencies
        sudo apt install -y curl at git nodejs npm build-essential python3 zip unzip
        pip_dep
        start_atd
        second_dep

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        install_docker_app
        install_docker
        install_docker_memlimit
        blank_env
        custom_docker_size
        ;;
esac
