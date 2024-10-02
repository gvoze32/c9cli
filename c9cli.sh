#!/bin/bash
VERSION="4.8"

if [ "$(id -u)" != "0" ]; then
    echo "c9cli must be run as root!" 1>&2
    exit 1
fi

ubuntu_version=$(lsb_release -r | awk '{print $2}')

check_update() {
    repo_url="https://hostingjaya.ninja/api/c9cli/c9cli"
    latest_version=$(curl -s "$repo_url" | grep -o 'VERSION="[0-9]*\.[0-9]*"' | cut -d '"' -f 2)

    if [ -n "$latest_version" ]; then
        if [ "$latest_version" != "$VERSION" ]; then
            echo "A new version ($latest_version) is available. Run 'c9cli update' to update."
        fi
    else
        echo "Failed to check for updates. Please check your internet connection."
    fi
}

LAST_CHECK_FILE="/tmp/c9cli_last_check"

if [ -f "$LAST_CHECK_FILE" ]; then
    last_check=$(cat "$LAST_CHECK_FILE")
    current_time=$(date +%s)
    time_diff=$((current_time - last_check))

    if [ $time_diff -gt 86400 ]; then
        check_update
        echo "$current_time" > "$LAST_CHECK_FILE"
    fi
else
    echo "0" > "$LAST_CHECK_FILE"
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
    echo "create"
    echo "  systemd           : Create a new SystemD workspace"
    echo "  systemdlimit      : Create a new SystemD workspace with limited RAM"
    echo "  docker            : Create a new Docker container"
    echo "  dockerlimit       : Create a new Docker container with limited RAM"
    echo "manage"
    echo "  systemd"
    echo "    delete          : Delete workspace"
    echo "    status          : Show workspace status"
    echo "    restart         : Restart workspace"
    echo "    password        : Change user password"
    echo "    schedule        : Schedule workspace deletion"
    echo "    scheduled       : Show scheduled workspace deletion"
    echo "    convert         : Convert user to superuser"
    echo "  docker"
    echo "    delete          : Delete Docker container"
    echo "    status          : Show container status"
    echo "    restart         : Restart running containers"
    echo "    restartall      : Restart (all) running containers"
    echo "    password        : Change user password, port & update limited RAM for dockerlimit"
    echo "    schedule        : Schedule container deletion"
    echo "    scheduled       : Show scheduled container deletion"
    echo "    list            : Show Docker container lists"
    echo "    configure       : Stop, start or restart running container"
    echo "    start           : Start Docker daemon service"
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
    echo
    echo "-t                  : Type (e.g., 1 for Docker, 2 for Docker Memory Limit)"
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
echo
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
ExecStart=/usr/bin/node /home/${user}/c9sdk/server.js -a $user:$pw --listen 0.0.0.0 -w /home/$user/my-projects
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
echo
if [[ -z "$port" ]]; then
  read -p "Port: " port
fi
echo
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
ExecStart=/usr/bin/node /home/${user}/c9sdk/server.js -a $user:$pw --listen 0.0.0.0 -w /home/$user/my-projects
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
echo
if [[ -z "$port" ]]; then
  read -p "Port: " port
fi
echo
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
echo
if [[ -z "$port" ]]; then
  read -p "Port: " port
fi
echo
if [[ -z "$limit" ]]; then
  read -p "Memory Limit (e.g., 1024m): " limit
fi
if [[ -z "$cpu_limit" ]]; then
  read -p "CPU Limit (e.g., 1.0 for 1 core): " cpu_limit
fi
echo
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
rm -rf /home/$user
}

statussystemd(){
read -p "Input User: " user
systemctl status c9-$user.service
}

restartsystemd(){
read -p "Input User: " user
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
sleep 3
killall -u $user
sleep 3
userdel $user
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
rm -rf $user
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
      echo "Memory and CPU limits updated for user $user"
    fi
    
    echo "Password, port, and .env updated for user $user"
    
    docker compose -p $user down
    docker compose -p $user up -d
    echo "Docker container restarted for user $user"
    
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
docker compose -p $user down
END
        ;;
    *)
at $waktu <<END
cd /home/c9usersmemlimit
docker compose -p $user down
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
        ;;
esac
}

restartdocker(){
containers=$(docker ps --format "{{.Names}}")
echo "Container lists:"
echo "$containers" | sed 's/^c9-//'

read -p "Input User: " user

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

startdocker(){
service docker start
}

backups(){
    echo "Scheduled Backup - WARNING: This script currently only supports backup for c9users and c9usersmemlimit docker containers"
    echo "Make sure you have set up an rclone config file using command: rclone config"
    echo "If your storage is bucket type, then name the rclone config name same as your bucket name"
    echo ""
    read -p "If all has been set up correctly, then input your rclone remote name: " name
    echo ""
    read -p "Enter the time for backup (hour 0-23): " hour
    echo ""
    read -p "Define the backup folder name on the cloud: " cloud_folder
    echo ""
    echo "Choose the backup service provider"
    echo "1. Google Drive"
    echo "2. Storj"
    echo "3. Backblaze B2"
    echo "4. pCloud"
    echo "5. Jottacloud"
    read -r -p "Choose: " response
    case "$response" in
        1) backup_path="$cloud_folder/backup-\$date"; list_path="$cloud_folder"; use_purge=false ;;
        2) backup_path="$cloud_folder/backup-\$date"; list_path="$cloud_folder"; use_purge=true ;;
        3) backup_path="$cloud_folder/backup-\$date"; list_path="$cloud_folder"; use_purge=true ;;
        4) backup_path="$cloud_folder/backup-\$date"; list_path="$cloud_folder"; use_purge=false ;;
        5) backup_path="$cloud_folder/backup-\$date"; list_path="$cloud_folder"; use_purge=false ;;
        *) echo "Invalid option"; exit 1 ;;
    esac

    cat > /home/backup-$name.sh << EOF
#!/bin/bash
date=\$(date +%y-%m-%d)
echo "Creating backup directory: $name:$backup_path" >> /home/backup-$name.log
rclone mkdir "$name:$backup_path" >> /home/backup-$name.log 2>&1

echo "Archiving contents of c9users and c9usersmemlimit folders (excluding .c9 folders)" >> /home/backup-$name.log
cd /home
for folder in c9users c9usersmemlimit; do
    if [ -d "\$folder" ]; then
        echo "Backing up contents of \$folder" >> /home/backup-$name.log
        cd "\$folder"
        for user_folder in */; do
            user=\${user_folder%/}
            echo "Backing up \$user from \$folder" >> /home/backup-$name.log
            zip -r "/home/\$folder-\$user-\$date.zip" "\$user_folder" -x "*/\.c9/*" "\$user_folder.c9/*" >> /home/backup-$name.log 2>&1
        done
        cd /home
    else
        echo "Folder \$folder not found, skipping" >> /home/backup-$name.log
    fi
done

echo "Moving archived files to /home/backup" >> /home/backup-$name.log
mkdir -p /home/backup
mv /home/*.zip /home/backup/ >> /home/backup-$name.log 2>&1

echo "Copying backup to remote" >> /home/backup-$name.log
rclone copy /home/backup/ "$name:$backup_path/" >> /home/backup-$name.log 2>&1

echo "Removing local backup files" >> /home/backup-$name.log
rm -rf /home/backup >> /home/backup-$name.log 2>&1

echo "Checking for old backups" >> /home/backup-$name.log
old_backups=\$(rclone lsf "$name:$list_path" 2>&1 | grep '^backup-' | sort)
backup_count=\$(echo "\$old_backups" | wc -l)

if [ "\$backup_count" -gt 1 ]; then
    echo "Found \$((backup_count - 1)) old backups:" >> /home/backup-$name.log
    echo "\$old_backups" | head -n -1 | while read -r oldbak; do
        full_path="$cloud_folder\$list_path/\$oldbak"
        echo "Removing old backup: $name:\$full_path" >> /home/backup-$name.log

        if [ "$use_purge" = true ]; then
            echo "Using rclone purge for bucket storage" >> /home/backup-$name.log
            rclone purge "$name:\$full_path" >> /home/backup-$name.log 2>&1
        else
            echo "Using rclone delete for non-bucket storage" >> /home/backup-$name.log
            rclone delete "$name:\$full_path" >> /home/backup-$name.log 2>&1
            rclone rmdirs "$name:\$full_path" >> /home/backup-$name.log 2>&1
        fi
    done
else
    echo "No old backups detected (only one backup present), not executing remove command" >> /home/backup-$name.log
fi
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
    repo_url="https://hostingjaya.ninja/api/c9cli/c9cli"
    latest_version=$(curl -s "$repo_url" | grep -o 'VERSION="[0-9]*\.[0-9]*"' | cut -d '"' -f 2)

    if [ -n "$latest_version" ]; then
        if [ "$latest_version" != "$VERSION" ]; then
            echo "Updating to version $latest_version..."
            if sudo curl -fsSL "$repo_url" -o /usr/local/bin/c9cli; then
                sudo chmod +x /usr/local/bin/c9cli
                echo "Update successful! You can now use the updated version."
                exec /usr/local/bin/c9cli "$@"
            else
                echo "Update failed. Please try again later."
            fi
        else
            echo "You are using the latest version ($VERSION)."
        fi
    else
        echo "Failed to check for updates. Please check your internet connection."
    fi
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
          delete)
            deletesystemd "${@:4}"
            ;;
          status)
            statussystemd
            ;;
          restart)
            restartsystemd
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
            restartdocker
            ;;
          restartall)
            restartdockerall
            ;;
          start)
            startdocker
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
    backups
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