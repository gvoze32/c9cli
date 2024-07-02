#!/bin/bash

# Check Ubuntu Version
# Recommended for Ubuntu 24.04 (Noble Numbat) and above.
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
        echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
        source ~/.bashrc
        command -v nvm
        nvm install node

        # Install dependencies
        sudo apt install -y at git npm build-essential php php8.1-common php-gd php-mbstring php-curl php8.1-mysql php-json php8.1-xml php-fpm python2 python3 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        pip3 install requests selenium colorama bs4 wget pyfiglet
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common

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
        echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
        source ~/.bashrc
        command -v nvm
        nvm install node

        # Install dependencies
        sudo apt install -y at git npm build-essential php7.4-cli php-gd php-mbstring php-curl php-mysqli php-json php-dom php-fpm python2 python3 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        python3 -m pip install requests selenium colorama bs4 wget pyfiglet chardet urllib3
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common

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
        echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
        source ~/.bashrc
        command -v nvm
        nvm install node

        # Install dependencies
        sudo apt install -y curl at git npm build-essential php php7.2-common php-gd php-mbstring php-curl php7.2-mysql php-json php7.2-xml php-fpm python python2.7 python3-pip zip unzip dos2unix
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        pip3 install requests selenium colorama bs4 wget pyfiglet
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common

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
    24.04)
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
        echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
        source ~/.bashrc
        command -v nvm
        nvm install node

        # Install dependencies
        sudo apt install -y at git npm build-essential php8.3 libapache2-mod-php php8.3-common php8.3-cli php8.3-mbstring php8.3-bcmath php8.3-fpm php8.3-mysql php8.3-zip php8.3-gd php8.3-curl php8.3-xml python3 python3-pip zip unzip dos2unix checkinstall libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev
        wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
        tar -xvf Python-2.7.18.tgz
        cd Python-2.7.18
        ./configure --enable-optimizations
        make
        sudo make install
        python -V
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
        sudo python2.7 get-pip.py
        pip2.7 --version
        pip3 install requests selenium colorama bs4 wget pyfiglet
        pip2 install requests selenium colorama bs4 wget pyfiglet
        systemctl start atd
        sudo apt install -y pythonpy apt-transport-https ca-certificates gnupg-agent software-properties-common

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
        cd
        rm get-pip.py install.sh Python-2.7.18.tgz
        rm -rf Python-2.7.18
        ;;
    *)
        echo "Versi Ubuntu tidak didukung"
        ;;
esac
