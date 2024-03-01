#!/bin/bash

# Check Ubuntu Version
ubuntu_version=$(lsb_release -r | awk '{print $2}')
echo "Ubuntu version is $ubuntu_version"

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
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt update -y

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        # Install nvm-nodejs
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install node

        # Install dependencies
        sudo apt install -y at git npm build-essential php php8.1-common php-gd php-mbstring php-curl php8.1-mysql php-json php8.1-xml php-fpm python2 python3 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        pip3 install requests selenium colorama bs4 wget pyfiglet
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common docker docker.io docker-compose

        # Add docker compose
        sudo adduser --disabled-password --gecos "" c9users
        sudo cat > /home/c9users/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9users/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
EOF

        # Add docker compose memlimit
        sudo adduser --disabled-password --gecos "" c9usersmemlimit
        sudo cat > /home/c9usersmemlimit/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9usersmemlimit/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
# This rule is optional, uncomment if you need to use it.
    mem_limit: \${MEMORY}
    cpus: \${CPUS}
EOF

        # Create blank .env files
        > /home/c9users/.env
        > /home/c9usersmemlimit/.env

        # Custom docker daemon service option
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

        # Install ioncube
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

        #Cleanup
        rm get-pip.py install.sh
        ;;
    20.04)
        # Set NEEDRESTART frontend to avoid prompts
        export DEBIAN_FRONTEND=noninteractive
        export NEEDRESTART_SUSPEND=1
        export NEEDRESTART_MODE=l

        echo "Setting up Ubuntu $ubuntu_version.."

        # Update packages
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt update -y

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        # Install nvm-nodejs
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install node

        # Install dependencies
        sudo apt install -y at git npm build-essential php7.4-cli php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python2 python3 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        python3 -m pip install requests selenium colorama bs4 wget pyfiglet chardet urllib3
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common docker docker.io docker-compose

        # Add docker compose
        sudo adduser --disabled-password --gecos "" c9users
        sudo cat > /home/c9users/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9users/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
EOF

        # Add docker compose memlimit
        sudo adduser --disabled-password --gecos "" c9usersmemlimit
        sudo cat > /home/c9usersmemlimit/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9usersmemlimit/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
# This rule is optional, uncomment if you need to use it.
    mem_limit: \${MEMORY}
    cpus: \${CPUS}
EOF

        # Create blank .env files
        > /home/c9users/.env
        > /home/c9usersmemlimit/.env

        # Custom docker daemon service option
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

        # Install ioncube
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

        #Cleanup
        rm get-pip.py install.sh
        ;;
    18.04)
        echo "Setting up Ubuntu $ubuntu_version.."

        # Update packages
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt update -y

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        # Install nvm-nodejs
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install node

        # Install dependencies
        sudo apt install -y curl at git npm build-essential php php7.2-common php-gd php-mbstring php-curl php7.2-mysql php-json php7.2-xml php-fpm python python2.7 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        pip3 install requests selenium colorama bs4 wget pyfiglet
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common docker docker.io docker-compose

        # Add docker compose
        sudo adduser --disabled-password --gecos "" c9users
        sudo cat > /home/c9users/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9users/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
EOF

        # Add docker compose memlimit
        sudo adduser --disabled-password --gecos "" c9usersmemlimit
        sudo cat > /home/c9usersmemlimit/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9usersmemlimit/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
# This rule is optional, uncomment if you need to use it.
    mem_limit: \${MEMORY}
    cpus: \${CPUS}
EOF

        # Create blank .env files
        > /home/c9users/.env
        > /home/c9usersmemlimit/.env

        # Custom docker daemon service option
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

        # Install ioncube
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

        #Cleanup
        rm get-pip.py install.sh
        ;;
    23.10)
        # Set NEEDRESTART frontend to avoid prompts
        sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
        sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf
        export DEBIAN_FRONTEND=noninteractive
        export NEEDRESTART_SUSPEND=1
        export NEEDRESTART_MODE=l

        echo "Setting up Ubuntu $ubuntu_version.."

        # Update packages
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt update -y

        # Install rclone
        curl https://rclone.org/install.sh | sudo bash

        # Install nvm-nodejs
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install node

        # Install dependencies
        sudo apt install -y at git npm build-essential php8.2 php8.2-cli php8.2-fpm php-gd php-mbstring php-curl php8.2-mysql php-json php8.2-xml python2 python3 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        pip3 install requests selenium colorama bs4 wget pyfiglet
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common docker docker.io docker-compose

        # Add docker compose
        sudo adduser --disabled-password --gecos "" c9users
        sudo cat > /home/c9users/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9users/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
EOF

        # Add docker compose memlimit
        sudo adduser --disabled-password --gecos "" c9usersmemlimit
        sudo cat > /home/c9usersmemlimit/docker-compose.yml << EOF
version: '2.2'
services:
  cloud9:
    image: sapk/cloud9:latest
    volumes:
      - /home/c9usersmemlimit/\${NAMA_PELANGGAN}:/workspace
    restart: always
    ports:
      - "\${PORT}:\${PORT}"
    command:
      - --auth=\${NAMA_PELANGGAN}:\${PASSWORD_PELANGGAN}
      - --port=\${PORT}
# This rule is optional, uncomment if you need to use it.
    mem_limit: \${MEMORY}
    cpus: \${CPUS}
EOF

        # Create blank .env files
        > /home/c9users/.env
        > /home/c9usersmemlimit/.env

        # Custom docker daemon service option
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

        # Install ioncube
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

        #Cleanup
        rm get-pip.py install.sh
        ;;
    *)
        echo "Versi Ubuntu tidak didukung"
        ;;
esac