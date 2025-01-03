#!/bin/bash
VERSION="5.17"

if [ "$(id -u)" != "0" ]; then
    echo "c9cli must be run as root!" 1>&2
    exit 1
fi

ubuntu_version=$(lsb_release -r | awk '{print $2}')

check_update() {
    echo "Checking for available updates..."
    
    REPO_URL="https://hostingjaya.ninja/api/c9cli"
    
    if ! curl --connect-timeout 5 -s "https://8.8.8.8" > /dev/null; then
        echo "No internet connection detected."
        return 1
    fi
    
    max_attempts=3
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if latest_info=$(curl -s --connect-timeout 10 "$REPO_URL/c9cli"); then
            latest_version=$(echo "$latest_info" | grep -o 'VERSION="[0-9]*\.[0-9]*"' | cut -d '"' -f 2)
            
            if [ -n "$latest_version" ]; then
                if [ "$latest_version" != "$VERSION" ]; then
                    echo "New version available: v$latest_version (current: v$VERSION)"
                    echo "Run 'c9cli update' to update."
                fi
                return 0
            fi
        fi
        
        attempt=$((attempt + 1))
        [ $attempt -le $max_attempts ] && sleep 2
    done
    
    echo "Failed to check for updates after $max_attempts attempts."
    return 1
}

LAST_CHECK_FILE="/tmp/c9cli_last_check"
CHECK_INTERVAL=86400

current_time=$(date +%s)

if [ -f "$LAST_CHECK_FILE" ]; then
    last_check=$(cat "$LAST_CHECK_FILE")
    time_diff=$((current_time - last_check))

    if [ $time_diff -gt $CHECK_INTERVAL ]; then
        check_update
        echo "$current_time" > "$LAST_CHECK_FILE"
    fi
else
    echo "$current_time" > "$LAST_CHECK_FILE"
    check_update
fi

# COMMANDS

banner() {
    echo "        ___       _ _ "
    echo "   ___ / _ \  ___| (_)"
    echo "  / __| (_) |/ __| | |"
    echo " | (__ \__, | (__| | |"
    echo "  \___|  /_/ \___|_|_|"
    echo
    echo "=====  CLOUD9 CLI MANAGER  ====="
    echo
}
about() {
    echo "Name of File  : c9cli.sh"
    echo "Version       : $VERSION"
    echo "Tested on     :"
    echo "    - Debian  : Ubuntu 18.04, 20.04, 22.04"
    echo
    echo "Built with love♡ by gvoze32"
}
# =========== DON'T CHANGE THE ORDER OF THIS FUNCTION =========== #

bantuan() {
    echo "How to use:"
    echo "c9cli must be run as root"
    echo "c9cli [command] [argument] [argument]"
    echo
    echo "Command Lists:"
    echo "quickcreate         : Quick create C9 workspace in root"
    echo "  restart           : Restart quick created C9"
    echo "  fix               : Fix quick created C9 installation"
    echo "create"
    echo "  systemd           : Create a new SystemD workspace"
    echo "  systemdlimit      : Create a new SystemD workspace with limited RAM"
    echo "  docker            : Create a new Docker container"
    echo "  dockerlimit       : Create a new Docker container with limited RAM"
    echo "manage"
    echo "  systemd"
    echo "    stop            : Stop workspace"
    echo "    start           : Start workspace"
    echo "    delete          : Delete workspace"
    echo "    status          : Show workspace status"
    echo "    restart         : Restart workspace"
    echo "    password        : Change user password"
    echo "    schedule        : Schedule workspace deletion"
    echo "    scheduled       : Show scheduled workspace deletion"
    echo "    convert         : Convert user to superuser"
    echo "  docker"
    echo "    stop            : Stop Docker container"
    echo "    start           : Start Docker container"
    echo "    delete          : Delete Docker container"
    echo "    status          : Show container status"
    echo "    restart         : Restart running containers"
    echo "    restartall      : Restart (all) running containers"
    echo "    reset           : Reset Docker container"
    echo "    password        : Change user password, port & update limited RAM for dockerlimit"
    echo "    schedule        : Schedule container deletion"
    echo "    scheduled       : Show scheduled container deletion"
    echo "    list            : Show Docker container lists"
    echo "    configure       : Stop, start or restart running container"
    echo "port                : Show used port lists"
    echo "backup              : Backup workspace data with Rclone (Docker only)"
    echo "update              : Update c9cli to the latest version"
    echo "help                : Show help"
    echo "version             : Show version"
    echo
    echo "Options:"
    echo "-u                  : Username"
    echo "-p                  : Password"
    echo "-o                  : Port number"
    echo "-l                  : Memory limit (e.g., 1024m)"
    echo "-c                  : CPU limit (e.g., 10% or 1.0)"
    echo "-i                  : Image (e.g., gvoze32/cloud9:jammy)"
    echo "-t                  : Type (e.g., 1 for Docker, 2 for Docker Memory Limit)"
    echo "-n                  : Rclone remote name"
    echo "-h                  : Backup hour"
    echo "-f                  : Backup folder name"
    echo "-s                  : Backup service provider"
    echo
    echo "Copyright (c) 2024 c9cli (under MIT License)"
    echo "Built with love♡ by gvoze32"
}

# CREATE SYSTEMD

createnewsystemd(){
while getopts "u:p:o:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    p) pw="$OPTARG" ;;
    o) port="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Username: " user
fi
if [[ -z "$pw" ]]; then
  read -p "Password: " pw
fi
if [[ -z "$port" ]]; then
  read -p "Port: " port
fi
echo
echo "Creating workspace:"
echo "Username: $user"
echo "Password: $pw"
echo "Port: $port"

apt-get update -y
apt-get upgrade -y
apt-get update -y

adduser --disabled-password --gecos "" $user

case $ubuntu_version in
  22.04 | 20.04)
    echo "$user:$pw" | chpasswd
    mkdir -p /home/$user/my-projects /home/$user/c9sdk
    chown -R $user:$user /home/$user
    chmod 700 /home/$user
    sudo -u $user git clone --depth=5 https://github.com/c9/core.git /home/$user/c9sdk
    sudo -u $user bash -c "cd /home/$user/c9sdk && scripts/install-sdk.sh"
    ;;
  18.04)
    echo -e "$pw\n$pw" | passwd $user
    mkdir -p /home/$user/my-projects /home/$user/c9sdk
    chown $user.$user /home/$user -R
    chmod 700 /home/$user
    sudo -u $user git clone --depth=5 https://github.com/c9/core.git /home/$user/c9sdk
    sudo -u $user -H sh -c "cd /home/$user/c9sdk; scripts/install-sdk.sh"
    ;;
esac

cat > /lib/systemd/system/c9-$user.service << EOF
[Unit]
Description=c9 for $user
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /home/${user}/c9sdk/server.js -a $user:$pw --listen 0.0.0.0 --packed -w /home/$user/my-projects
Environment=NODE_ENV=production PORT=$port
User=$user
Group=$user
UMask=0002
Restart=on-failure
StandardOutput=journal
StandardError=journal
SyslogIdentifier=c9-$user

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable c9-$user.service
systemctl restart c9-$user.service
sleep 10
systemctl status c9-$user.service
}

createnewsystemdlimit(){
while getopts "u:p:o:l:c:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    p) pw="$OPTARG" ;;
    o) port="$OPTARG" ;;
    l) limit="$OPTARG" ;;
    c) cpu_limit="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Username: " user
fi
if [[ -z "$pw" ]]; then
  read -p "Password: " pw
fi
if [[ -z "$port" ]]; then
  read -p "Port: " port
fi
if [[ -z "$limit" ]]; then
  read -p "Memory Limit (e.g., 1024m): " limit
fi
if [[ -z "$cpu_limit" ]]; then
  read -p "CPU Limit (e.g., 10%): " cpu_limit
fi
echo
echo "Creating workspace with memory limit:"
echo "Username: $user"
echo "Password: $pw"
echo "Port: $port"
echo "Memory Limit: $limit"
echo "CPU Limit: $cpu_limit"

apt-get update -y
apt-get upgrade -y
apt-get update -y

adduser --disabled-password --gecos "" $user

case $ubuntu_version in
  22.04 | 20.04)
    echo "$user:$pw" | chpasswd
    mkdir -p /home/$user/my-projects /home/$user/c9sdk
    chown -R $user:$user /home/$user
    chmod 700 /home/$user
    sudo -u $user git clone --depth=5 https://github.com/c9/core.git /home/$user/c9sdk
    sudo -u $user bash -c "cd /home/$user/c9sdk && scripts/install-sdk.sh"
    ;;
  18.04)
    echo -e "$pw\n$pw" | passwd $user
    mkdir -p /home/$user/my-projects /home/$user/c9sdk
    chown $user.$user /home/$user -R
    chmod 700 /home/$user
    sudo -u $user git clone --depth=5 https://github.com/c9/core.git /home/$user/c9sdk
    sudo -u $user -H sh -c "cd /home/$user/c9sdk; scripts/install-sdk.sh"
    ;;
esac

cat > /lib/systemd/system/c9-$user.service << EOF
[Unit]
Description=c9 for $user
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /home/${user}/c9sdk/server.js -a $user:$pw --listen 0.0.0.0 --packed -w /home/$user/my-projects
Environment=NODE_ENV=production PORT=$port
User=$user
Group=$user
UMask=0002
MemoryMax=$limit
CPUQuota=$cpu_limit
Restart=on-failure
StandardOutput=journal
StandardError=journal
SyslogIdentifier=c9-$user

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable c9-$user.service
systemctl restart c9-$user.service
sleep 10
systemctl status c9-$user.service
}

createnewdocker(){
while getopts "u:p:o:i:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    p) pw="$OPTARG" ;;
    o) port="$OPTARG" ;;
    i) image="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Username: " user
fi
if [[ -z "$pw" ]]; then
  read -p "Password: " pw
fi
if [[ -z "$port" ]]; then
  read -p "Port: " port
fi
if [[ -z "$image" ]]; then
  echo "Select image:"
  echo "1. Ubuntu 20.04"
  echo "2. Ubuntu 22.04"
  echo "3. Ubuntu 24.04"
  read -p "Enter image option (1/3): " image_choice
  if [ "$image_choice" == "1" ]; then
    image="gvoze32/cloud9:focal"
  elif [ "$image_choice" == "2" ]; then
    image="gvoze32/cloud9:jammy"
  elif [ "$image_choice" == "3" ]; then
    image="gvoze32/cloud9:noble"
  else
    echo "Invalid option, using default image."
    image="gvoze32/cloud9:jammy"
  fi
else
  echo "Using provided image: $image"
fi
echo
echo "Creating docker container:"
echo "Username: $user"
echo "Password: $pw"
echo "Port: $port"
echo "Image: $image"

cd /home/c9users
rm .env
cat > /home/c9users/.env << EOF
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
PORT=$port
DOCKER_IMAGE=$image
EOF
docker compose -p $user up -d
if [ -d "/home/c9users/$user" ]; then
cd /home/c9users/$user

### Your custom default bundling files goes here, it's recommended to put it on resources directory
### START

### END

cd
else
echo -e "\033[33mWARN! Workspace directory not found - Ignore this message if you are not adding default bundling files\033[0m"
fi
}

# CREATE DOCKERLIMIT
createnewdockermemlimit(){
while getopts "u:p:o:l:c:i:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    p) pw="$OPTARG" ;;
    o) port="$OPTARG" ;;
    l) limit="$OPTARG" ;;
    c) cpu_limit="$OPTARG" ;;
    i) image="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Username: " user
fi
if [[ -z "$pw" ]]; then
  read -p "Password: " pw
fi
if [[ -z "$port" ]]; then
  read -p "Port: " port
fi
if [[ -z "$limit" ]]; then
  read -p "Memory Limit (e.g., 1024m): " limit
fi
if [[ -z "$cpu_limit" ]]; then
  read -p "CPU Limit (e.g., 1.0 for 1 core): " cpu_limit
fi
if [[ -z "$image" ]]; then
  echo "Select image:"
  echo "1. Ubuntu 20.04"
  echo "2. Ubuntu 22.04"
  echo "3. Ubuntu 24.04"
  read -p "Enter image option (1/3) : " image_choice
  if [ "$image_choice" == "1" ]; then
    image="gvoze32/cloud9:focal"
  elif [ "$image_choice" == "2" ]; then
    image="gvoze32/cloud9:jammy"
  elif [ "$image_choice" == "3" ]; then
    image="gvoze32/cloud9:noble"
  else
    echo "Invalid option, using default image."
    image="gvoze32/cloud9:jammy"
  fi
else
  echo "Using provided image: $image"
fi
echo
echo "Creating docker container with memory limit:"
echo "Username: $user"
echo "Password: $pw"
echo "Port: $port"
echo "Memory Limit: $limit"
echo "CPU Limit: $cpu_limit"
echo "Image: $image"

cd /home/c9usersmemlimit
rm .env
cat > /home/c9usersmemlimit/.env << EOF
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
PORT=$port
MEMORY=$limit
CPU_LIMIT=$cpu_limit
DOCKER_IMAGE=$image
EOF
docker compose -p $user up -d
if [ -d "/home/c9usersmemlimit/$user" ]; then
cd /home/c9usersmemlimit/$user

### Your custom default bundling files goes here, it's recommended to put it on resources directory
### START

### END

cd
else
echo -e "\033[33mWARN! Workspace directory not found - Ignore this message if you are not adding default bundling files\033[0m"
fi
}

# MANAGE SYSTEMD

stopsystemd(){
while getopts "u:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

sleep 3
systemctl stop c9-$user.service
}

startsystemd(){
while getopts "u:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

sleep 3
systemctl start c9-$user.service
}

deletesystemd(){
while getopts "u:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

sleep 3
systemctl stop c9-$user.service
sleep 3
killall -u $user
sleep 3
userdel $user
# OPTIONAL: Remove user directory
# rm -rf /home/$user
}

statussystemd(){
while getopts "u:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

systemctl status c9-$user.service
}

restartsystemd(){
while getopts "u:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

systemctl daemon-reload
systemctl enable c9-$user.service
systemctl restart c9-$user.service
sleep 10
systemctl status c9-$user.service
}

changepasswordsystemd() {
  while getopts "u:p:o:" opt; do
    case $opt in
      u) user="$OPTARG" ;;
      p) password="$OPTARG" ;;
      o) port="$OPTARG" ;;
      \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -p "Input User: " user
  fi

  if [[ -z "$password" ]]; then
    read -p "Input New Password: " password
  fi

  if [[ -z "$port" ]]; then
    read -p "Input New Port: " port
  fi

  sed -i "s/-a $user:.*/-a $user:$password/" /lib/systemd/system/c9-$user.service
  sed -i "s/PORT=.*/PORT=$port/" /lib/systemd/system/c9-$user.service

  systemctl daemon-reload
  systemctl restart c9-$user.service
  sleep 10
  systemctl status c9-$user.service
}

schedulesystemd(){
read -p "Input User: " user
echo " "
echo "Format Example for Time: "
echo " "
echo "10:00 AM 6/22/2015"
echo "10:00 AM July 25"
echo "10:00 AM"
echo "10:00 AM Sun"
echo "10:00 AM next month"
echo "10:00 AM tomorrow"
echo "now + 1 hour"
echo "now + 30 minutes"
echo "now + 1 week"
echo "now + 1 year"
echo "midnight"
echo " "
read -p "Time: " waktu
at $waktu <<END
sleep 3
systemctl stop c9-$user.service
# OPTIONAL: Remove user directory
# sleep 3
# killall -u $user
# sleep 3
# userdel $user
END
}

scheduledatq(){
atq
}

convertsystemd(){
read -p "Input User: " user
echo "Input user password"
passwd $user
echo "Warning, C9 will be restart!"
usermod -aG sudo $user
systemctl daemon-reload
systemctl enable c9-$user.service
systemctl restart c9-$user.service
sleep 10
systemctl status c9-$user.service
}

# MANAGE DOCKER

stopdocker(){
while getopts "u:t:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

if [[ -z "$type" ]]; then
  echo "Are the file is using Docker or Docker Memory Limit?"
  echo "1. Docker"
  echo "2. Docker Memory Limit"
  read -r -p "Choose: " response
else
  response="$type"
fi

case "$response" in
    1) 
cd /home/c9users
        ;;
    *)
cd /home/c9usersmemlimit
        ;;
esac
docker compose -p $user stop
}

startdocker(){
while getopts "u:t:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

if [[ -z "$type" ]]; then
  echo "Are the file is using Docker or Docker Memory Limit?"
  echo "1. Docker"
  echo "2. Docker Memory Limit"
  read -r -p "Choose: " response
else
  response="$type"
fi

case "$response" in
    1) 
cd /home/c9users
        ;;
    *)
cd /home/c9usersmemlimit
        ;;
esac
docker compose -p $user start
}

deletedocker(){
while getopts "u:t:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

if [[ -z "$type" ]]; then
  echo "Are the file is using Docker or Docker Memory Limit?"
  echo "1. Docker"
  echo "2. Docker Memory Limit"
  read -r -p "Choose: " response
else
  response="$type"
fi

case "$response" in
    1) 
cd /home/c9users
        ;;
    *)
cd /home/c9usersmemlimit
        ;;
esac
docker compose -p $user down
# OPTIONAL: Remove user directory
# rm -rf $user
}

listdocker(){
docker ps
}

statusdocker(){
docker stats
}

changepassworddocker(){
  while getopts "u:p:t:o:l:c:" opt; do
    case $opt in
      u) user="$OPTARG" ;;
      p) newpw="$OPTARG" ;;
      t) type="$OPTARG" ;;
      o) port="$OPTARG" ;;
      l) mem="$OPTARG" ;;
      c) cpu_limit="$OPTARG" ;;
      \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -p "Input Username: " user
  fi

  if [[ -z "$newpw" ]]; then
    read -p "Input New Password: " newpw
  fi

  if [[ -z "$port" ]]; then
    read -p "Input Port: " port
  fi

  if [[ -z "$type" ]]; then
    echo "Is the user using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
  else
    response="$type"
  fi

  case "$response" in
    1) 
      base_dir="/home/c9users"
      mem=""
      cpu_limit=""
      ;;
    2) 
      base_dir="/home/c9usersmemlimit"
      if [[ -z "$mem" ]]; then
        read -p "Memory Limit (e.g., 1024m): " mem
      fi
      if [[ -z "$cpu_limit" ]]; then
        read -p "CPU Limit (e.g., 1.0 for 1 core): " cpu_limit
      fi
      ;;
    *) 
      echo "Invalid option" 
      return 
      ;;
  esac

  cd "$base_dir" || return

  cat > .env << EOF
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$newpw
PORT=$port
EOF

  if [ "$response" = "2" ]; then
    cat >> .env << EOF
MEMORY=$mem
CPU_LIMIT=$cpu_limit
DOCKER_IMAGE=gvoze32/cloud9:jammy
EOF
  fi

  if [ -d "$base_dir/$user" ]; then
    cd "$base_dir/$user" || return
    cat > .env << EOF
PORT=$port
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$newpw
EOF

    if [ "$response" = "2" ]; then
      cat >> .env << EOF
MEMORY=$mem
CPU_LIMIT=$cpu_limit
EOF
    fi

    cd "$base_dir"
    echo "Password, port and .env updated for user $user"
    docker compose -p $user down
    docker compose -p $user up -d
    echo "Docker container recreated for user $user"
  else
    echo "User $user does not exist or workspace directory not found"
  fi
}

scheduledocker(){
read -p "Input User: " user
echo Are the file is using docker or dockermemlimit?
read -r -p "Answer Y if you are using docker and answer N if you are using dockermemlimit [y/N] " response
echo " "
echo "Format Example for Time: "
echo " "
echo "10:00 AM 6/22/2015"
echo "10:00 AM July 25"
echo "10:00 AM"
echo "10:00 AM Sun"
echo "10:00 AM next month"
echo "10:00 AM tomorrow"
echo "now + 1 hour"
echo "now + 30 minutes"
echo "now + 1 week"
echo "now + 1 year"
echo "midnight"
echo " "
read -p "Time: " waktu
case "$response" in
    [yY][eE][sS]|[yY]) 
at $waktu <<END
cd /home/c9users
docker compose -p $user stop
# OPTIONAL: Remove user setup
# docker compose -p $user down
END
        ;;
    *)
at $waktu <<END
cd /home/c9usersmemlimit
docker compose -p $user stop
# OPTIONAL: Remove user setup
# docker compose -p $user down
END
        ;;
esac
}

configuredocker(){
read -p "Input User: " user
echo 1. Stop
echo 2. Start
echo 3. Restart
read -r -p "Choose: " response
case "$restart" in
    1) 
echo Are the file is using Docker or Docker Memory Limit?
echo 1. Docker
echo 2. Docker Memory Limit
read -r -p "Choose: " response
case "$response" in
    1) 
cd /home/c9users
        ;;
    *)
cd /home/c9usersmemlimit
        ;;
esac
docker container stop $user
# OPTIONAL: Remove user setup
# docker compose -p $user down
        ;;
    2) 
echo Are the file is using Docker or Docker Memory Limit?
echo 1. Docker
echo 2. Docker Memory Limit
read -r -p "Choose: " response
case "$response" in
    1) 
cd /home/c9users
        ;;
    *)
cd /home/c9usersmemlimit
        ;;
esac
docker container start $user
        ;;
    *)
echo Are the file is using Docker or Docker Memory Limit?
echo 1. Docker
echo 2. Docker Memory Limit
read -r -p "Choose: " response
case "$response" in
    1) 
cd /home/c9users
        ;;
    *)
cd /home/c9usersmemlimit
        ;;
esac
docker container stop $user
docker container start $user
# OPTIONAL: Remove user setup
# docker compose -p $user down
# docker compose -p $user up -d
        ;;
esac
}

restartdocker(){
while getopts "u:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

containers=$(docker ps --format "{{.Names}}")
echo "Container lists:"
echo "$containers" | sed 's/^c9-//'

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

container_name="c9-$user"

if echo "$containers" | grep -qw "$container_name"; then
    docker restart "$container_name"

    if [ $? -eq 0 ]; then
        echo "Container '$container_name' restarted successfully."
    else
        echo "Container restart '$container_name' failed."
    fi
else
    echo "Container name '$container_name' invalid. Make sure the name is correct."
fi
}

restartdockerall(){
docker restart $(docker ps -q)
}

resetdocker(){
while getopts "u:t:" opt; do
  case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

if [[ -z "$user" ]]; then
  read -p "Input User: " user
fi

if [[ -z "$type" ]]; then
  echo "Are the file is using Docker or Docker Memory Limit?"
  echo "1. Docker"
  echo "2. Docker Memory Limit"
  read -r -p "Choose: " response
else
  response="$type"
fi

case "$response" in
    1)
cd /home/c9users
        ;;
    *)
cd /home/c9usersmemlimit
        ;;
esac
docker compose -p $user down
docker compose -p $user up -d
}

backups(){
    while getopts "n:h:f:s:" opt; do
        case $opt in
            n) name="$OPTARG" ;;
            h) hour="$OPTARG" ;;
            f) cloud_folder="$OPTARG" ;;
            s) service="$OPTARG" ;;
            \?) echo "Invalid option: -$OPTARG" >&2 ;;
        esac
    done

    echo "Scheduled Backup - WARNING: This script currently only supports backup for c9users and c9usersmemlimit docker containers"
    echo "Make sure you have set up an rclone config file using command: rclone config"
    echo "If your storage is bucket type, then name the rclone config name same as your bucket name"
    echo ""
    if [[ -z "$name" ]]; then
      read -p "If all has been set up correctly, then input your rclone remote name: " name
    fi
    if [[ -z "$hour" ]]; then
      read -p "Enter the time for backup (hour 0-23): " hour
    fi
    if [[ -z "$cloud_folder" ]]; then
      read -p "Define the backup folder name on the cloud: " cloud_folder
    fi
    if [[ -z "$service" ]]; then
      echo ""
      echo "Choose the backup service provider"
      echo "1. Google Drive"
      echo "2. Storj"
      echo "3. Backblaze B2"
      echo "4. pCloud"
      echo "5. Jottacloud"
      read -r -p "Choose: " response
    else
      response="$service"
    fi
    case "$response" in
      1) backup_path="$cloud_folder"; list_path="$cloud_folder"; use_purge=false ;;
      2) backup_path="$cloud_folder"; list_path="$cloud_folder"; use_purge=true ;;
      3) backup_path="$cloud_folder"; list_path="$cloud_folder"; use_purge=true ;;
      4) backup_path="$cloud_folder"; list_path="$cloud_folder"; use_purge=false ;;
      5) backup_path="$cloud_folder"; list_path="$cloud_folder"; use_purge=false ;;
      *) echo "Invalid option"; exit 1 ;;
    esac

    cat > /home/backup-$name.sh << EOF
#!/bin/bash
date=\$(date +%Y%m%d)
log_file="/home/backup-$name.log"

log_message() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$log_file"
}

verify_backup() {
    local folder="\$1"
    local user="\$2"
    local new_file="\$folder-\$user-\$date.zip"
    local retry_count=3
    local retry_delay=5
    
    for ((i=1; i<=retry_count; i++)); do
        log_message "Verification attempt \$i of \$retry_count for \$new_file"
        
        if rclone lsf "$name:$backup_path/\$new_file" &>/dev/null; then
            log_message "File \$new_file verified in remote"
            return 0
        fi
        
        log_message "WARNING: \$new_file not found in remote"
        if [ \$i -lt \$retry_count ]; then
            log_message "Retrying in \$retry_delay seconds..."
            sleep \$retry_delay
        fi
    done
    
    return 1
}

cleanup_old_backup() {
    local folder="\$1"
    local user="\$2"
    
    log_message "Checking for old backup files for \$folder-\$user"
    
    backup_files=\$(rclone lsf "$name:$backup_path" --include "\$folder-\$user-*.zip" | sort -r)
    
    backup_count=\$(echo "\$backup_files" | wc -l)
    
    if [ "\$backup_count" -gt 2 ]; then
        log_message "Keeping last 2 backups for \$folder-\$user"
        files_to_delete=\$(echo "\$backup_files" | tail -n +3)
        
        while IFS= read -r file; do
            if [ ! -z "\$file" ]; then
                log_message "Deleting old backup: \$file"
                rclone delete "$name:$backup_path/\$file" >> "\$log_file" 2>&1
            fi
        done <<< "\$files_to_delete"
    else
        log_message "Less than or equal to 2 backups found for \$folder-\$user, no cleanup needed"
    fi
}

log_message "Starting backup process"

cd /home
mkdir -p /home/backup

for folder in c9users c9usersmemlimit; do
    if [ -d "\$folder" ]; then
        log_message "Processing \$folder"
        cd "\$folder"
        for user_folder in */; do
            user=\${user_folder%/}
            log_message "Backing up \$user from \$folder"
            
            if ! zip -r "/home/backup/\$folder-\$user-\$date.zip" "\$user_folder" -x "*/\.c9/*" "\$user_folder.c9/*" >> "\$log_file" 2>&1; then
                log_message "ERROR: Failed to create zip for \$user in \$folder"
                continue
            fi

            log_message "Uploading backup for \$folder-\$user"
            max_retries=3
            retry_count=0
            upload_success=false

            while [ \$retry_count -lt \$max_retries ]; do
                log_message "Upload attempt \$((retry_count + 1)) of \$max_retries"
                
                if rclone copy "/home/backup/\$folder-\$user-\$date.zip" "$name:$backup_path/" >> "\$log_file" 2>&1; then
                    if verify_backup "\$folder" "\$user"; then
                        upload_success=true
                        break
                    fi
                fi
                
                retry_count=\$((retry_count + 1))
                if [ \$retry_count -lt \$max_retries ]; then
                    log_message "Retry in 30 seconds..."
                    sleep 30
                fi
            done

            if [ "\$upload_success" = true ]; then
                log_message "Backup successfully uploaded for \$folder-\$user"
                cleanup_old_backup "\$folder" "\$user"
            else
                log_message "ERROR: Backup failed for \$folder-\$user after \$max_retries attempts"
            fi

            log_message "Removing local backup file for \$folder-\$user"
            rm -f "/home/backup/\$folder-\$user-\$date.zip"
        done
        cd /home
    else
        log_message "Folder \$folder not found, skipping"
    fi
done

log_message "Removing local backup directory"
rm -rf /home/backup >> "\$log_file" 2>&1

log_message "Backup process completed"
EOF

    chmod +x /home/backup-$name.sh
    echo ""
    echo "Backup command created"

    crontab -l > current_cron
    echo "0 $hour * * * /home/backup-$name.sh > /home/backup-$name.log 2>&1" >> current_cron
    crontab current_cron
    rm current_cron

    echo ""
    echo "Cron job created"
    echo ""
    echo "Make sure it's included in your cron list:"
    crontab -l
    echo "Backup rule successfully added"
}

portlist(){
lsof -i -P -n | grep LISTEN
}

updates() {
    echo "Checking for updates..."
    
    REPO_URL="https://hostingjaya.ninja/api/c9cli"
    SCRIPT_PATH="/usr/local/bin/c9cli"
    BACKUP_PATH="/usr/local/bin/c9cli.backup"
    TEMP_PATH="/tmp/c9cli.tmp"

    if ! latest_info=$(curl -s --connect-timeout 10 "$REPO_URL/c9cli"); then
        echo "Failed to check for updates. Please check your internet connection."
        return 1
    fi

    latest_version=$(echo "$latest_info" | grep -o 'VERSION="[0-9]*\.[0-9]*"' | cut -d '"' -f 2)
    
    if [ -z "$latest_version" ]; then
        echo "Could not determine latest version."
        return 1
    fi

    echo "Current version: $VERSION"
    echo "Latest version: $latest_version"

    if [ "$VERSION" = "$latest_version" ]; then
        echo "You are already running the latest version!"
        return 0
    fi

    read -p "Would you like to update to version $latest_version? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        return 0
    fi

    echo "Downloading update..."
    
    if ! curl -fsSL "$REPO_URL/c9cli" -o "$TEMP_PATH"; then
        echo "Failed to download update."
        return 1
    fi

    if ! grep -q "VERSION=\"$latest_version\"" "$TEMP_PATH"; then
        echo "Downloaded file verification failed."
        rm -f "$TEMP_PATH"
        return 1
    fi

    echo "Creating backup..."
    if ! cp "$SCRIPT_PATH" "$BACKUP_PATH"; then
        echo "Failed to create backup."
        rm -f "$TEMP_PATH"
        return 1
    fi

    echo "Installing update..."
    if ! mv "$TEMP_PATH" "$SCRIPT_PATH"; then
        echo "Failed to install update."
        echo "Restoring from backup..."
        mv "$BACKUP_PATH" "$SCRIPT_PATH"
        return 1
    fi

    chmod +x "$SCRIPT_PATH"

    rm -f "$BACKUP_PATH"

    echo "Successfully updated to version $latest_version!"
    echo "Please restart your shell or run 'source $SCRIPT_PATH'"
}

quickcreatec9() {
    echo -e "Starting Quick C9 Installation..."

    ipvpsmu=$(curl -s ifconfig.me)
    echo "Server IP: $ipvpsmu"

    WORKSPACE_DIR="/root/workspace"
    mkdir -p "$WORKSPACE_DIR"

    echo "Downloading C9 SDK..."
    if [ ! -d "/root/c9sdk" ]; then
        git clone https://github.com/c9/core.git /root/c9sdk
    fi
    
    cd /root/c9sdk
    ./scripts/install-sdk.sh

    echo "Starting C9 Server..."
    echo "Access Cloud9 IDE at: http://$ipvpsmu:8080"
    node server.js \
        -l "$ipvpsmu:8080" \
        -p 8080 \
        --listen 0.0.0.0 \
        -w "$WORKSPACE_DIR" &

    echo -e "Quick C9 Installation Complete!"
    echo -e "Access Cloud9 IDE at: http://$ipvpsmu:8080"
}

restartquickcreate() {
    echo -e "Restarting C9 Server..."
    
    echo "Stopping existing C9 server..."
    pkill -f "node.*server.js"
    sleep 3
    
    ipvpsmu=$(curl -s ifconfig.me)
    echo "Server IP: $ipvpsmu"

    cd /root/c9sdk || {
        echo "C9 SDK directory not found!"
        exit 1
    }

    echo "Starting C9 Server..."
    node server.js \
        -l "$ipvpsmu:8080" \
        -p 8080 \
        --listen 0.0.0.0 \
        -w "/root/workspace" &

    echo -e "C9 Server Successfully Restarted!"
    echo -e "Access Cloud9 IDE at: http://$ipvpsmu:8080"
}

fixquickcreate() {
    echo "Fixing C9..."

    echo "Stopping existing C9 server..."
    pkill -f "node.*server.js"
    sleep 3

    cd /root/c9sdk || {
        echo "C9 SDK directory not found!"
        exit 1
    }
    
    git reset --hard
    git fetch origin && git reset origin/HEAD --hard
    
    ./scripts/install-sdk.sh
    
    ipvpsmu=$(curl -s ifconfig.me)
    
    echo "Starting C9 Server..."
    node server.js \
        -l "$ipvpsmu:8080" \
        -p 8080 \
        --listen 0.0.0.0 \
        -w "/root/workspace" &

    echo -e "C9 Fix Complete!"
    echo -e "Access Cloud9 IDE at: http://$ipvpsmu:8080"
}

# BASIC MENUS

helps(){
banner
bantuan
}

versions(){
banner
about
}

# MENU

case $1 in
  quickcreate)
    case $2 in
        restart)
          restartquickcreate
          ;;
        fix)
          fixquickcreate
          ;;
        *)
          echo "Command not found, type c9cli help for help"
          ;;
    esac
    ;;

  create)
    case $2 in
      systemd)
        createnewsystemd "${@:3}"
        ;;
      systemdlimit)
        createnewsystemdlimit "${@:3}"
        ;;
      docker)
        createnewdocker "${@:3}"
        ;;
      dockerlimit)
        createnewdockermemlimit "${@:3}"
        ;;
      *)
        echo "Command not found, type c9cli help for help"
        ;;
    esac
    ;;
    
  manage)
    case $2 in
      systemd)
        case $3 in
          stop)
            stopsystemd "${@:4}"
            ;;
          start)
            startsystemd "${@:4}"
            ;;
          delete)
            deletesystemd "${@:4}"
            ;;
          status)
            statussystemd "${@:4}"
            ;;
          restart)
            restartsystemd "${@:4}"
            ;;
          password)
            changepasswordsystemd "${@:4}"
            ;;
          schedule)
            schedulesystemd
            ;;
          scheduled)
            scheduledatq
            ;;
          convert)
            convertsystemd
            ;;
          *)
            echo "Command not found, type c9cli help for help"
            ;;
        esac
        ;;
        
      docker)
        case $3 in
          stop)
            stopdocker "${@:4}"
            ;;
          start)
            startdocker "${@:4}"
            ;;
          delete)
            deletedocker "${@:4}"
            ;;
          list)
            listdocker
            ;;
          status)
            statusdocker
            ;;
          password)
            changepassworddocker "${@:4}"
            ;;
          schedule)
            scheduledocker
            ;;
          scheduled)
            scheduledatq
            ;;
          configure)
            configuredocker
            ;;
          restart)
            restartdocker "${@:4}"
            ;;
          restartall)
            restartdockerall
            ;;
          reset)
            resetdocker "${@:4}"
            ;;
          *)
            echo "Command not found, type c9cli help for help"
            ;;
        esac
        ;;
      *)
        echo "Command not found, type c9cli help for help"
        ;;
    esac
    ;;
  
  port)
    portlist
    ;;
  
  update)
    updates
    ;;
  
  backup)
    backups "${@:2}"
    ;;
  
  daemon)
    dockerdaemon
    ;;
  
  help)
    helps
    ;;
  
  version)
    versions
    ;;
    
  *)
    echo "Command not found, type c9cli help for help"
    ;;
esac