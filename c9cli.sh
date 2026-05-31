#!/bin/bash
VERSION="5.30"

if [ "$(id -u)" != "0" ]; then
  echo "c9cli must be run as root!" 1>&2
  exit 1
fi

ubuntu_version=$(lsb_release -r | awk '{print $2}')

parse_quota_limit() {
  local raw="$1"
  raw="$(echo "$raw" | tr -d ' ')"

  if [[ -z "$raw" ]]; then
    echo ""
    return 1
  fi

  if [[ "$raw" == "0" ]]; then
    echo "0"
    return 0
  fi

  if [[ "$raw" =~ ^([0-9]+)([MmGg])$ ]]; then
    local num="${BASH_REMATCH[1]}"
    local unit="${BASH_REMATCH[2]}"
    case "$unit" in
      M|m) echo $(( num * 1024 )) ;;
      G|g) echo $(( num * 1024 * 1024 )) ;;
      *) echo "" ; return 1 ;;
    esac
    return 0
  fi

  echo ""
  return 1
}

ensure_ext4_usrquota_ready_for_path() {
  local target_path="$1"

  if ! command -v quotacheck >/dev/null 2>&1 || ! command -v quotaon >/dev/null 2>&1 || ! command -v setquota >/dev/null 2>&1; then
    echo "WARN! quota tools not found (quotacheck/quotaon/setquota). Install 'quota' package to enable storage limits."
    return 1
  fi

  local mountpoint
  mountpoint="$(df -P "$target_path" 2>/dev/null | awk 'NR==2{print $6}')"
  if [[ -z "$mountpoint" ]]; then
    echo "WARN! Unable to determine mount point for $target_path. Storage limit skipped."
    return 1
  fi

  local fstype
  fstype="$(df -T -P "$target_path" 2>/dev/null | awk 'NR==2{print $2}')"
  if [[ "$fstype" != "ext4" ]]; then
    echo "WARN! Filesystem for $target_path is '$fstype' (not ext4). Storage limit skipped."
    return 1
  fi

  if ! mount | awk -v mp="$mountpoint" '$3==mp{print $0}' | grep -q 'usrquota'; then
    echo "WARN! usrquota is not enabled on mount point '$mountpoint'."
    echo "      Enable it in /etc/fstab (add 'usrquota') then reboot, or remount with usrquota."
    echo "      Storage limit skipped."
    return 1
  fi

  if [[ ! -f "$mountpoint/aquota.user" ]]; then
    echo "Initializing quota files on $mountpoint ..."
    quotacheck -cum "$mountpoint" >/dev/null 2>&1 || true
  fi

  quotaon -u "$mountpoint" >/dev/null 2>&1 || true

  return 0
}

set_user_storage_quota_for_path() {
  local q_user="$1"
  local limit_str="$2"
  local ws_path="$3"

  if [[ -z "$q_user" || -z "$limit_str" || -z "$ws_path" ]]; then
    echo "WARN! Missing args for storage limit; skipped."
    return 1
  fi

  local kb
  kb="$(parse_quota_limit "$limit_str")"
  if [[ -z "$kb" ]]; then
    echo "WARN! Invalid storage limit '$limit_str' (use e.g. 10G, 500M, 0). Skipped."
    return 1
  fi

  if ! ensure_ext4_usrquota_ready_for_path "$ws_path"; then
    return 1
  fi

  local mountpoint
  mountpoint="$(df -P "$ws_path" 2>/dev/null | awk 'NR==2{print $6}')"
  if [[ -z "$mountpoint" ]]; then
    echo "WARN! Unable to determine mount point for $ws_path. Storage limit skipped."
    return 1
  fi

  if [[ "$kb" == "0" ]]; then
    echo "Setting storage limit: unlimited (quota cleared) for user '$q_user' on $mountpoint"
    setquota -u "$q_user" 0 0 0 0 "$mountpoint" >/dev/null 2>&1 || true
    return 0
  fi

  echo "Setting storage limit: $limit_str for user '$q_user' on $mountpoint"
  setquota -u "$q_user" "$kb" "$kb" 0 0 "$mountpoint" >/dev/null 2>&1 || true
  return 0
}

check_update() {
  echo "Checking for available updates..."

  REPO_URL="https://jayanode.com/api/mirror/c9cli/c9cli?raw=true"
  max_attempts=3
  attempt=1

  while [ $attempt -le $max_attempts ]; do
    if latest_info=$(curl -s --connect-timeout 10 "$REPO_URL/c9cli"); then
      latest_version=$(echo "$latest_info" | grep -o 'VERSION="[0-9]*\.[0-9]*"' | cut -d '"' -f 2)

      if [ -n "$latest_version" ]; then
        if [ "$latest_version" != "$VERSION" ]; then
          echo "New version available: v$latest_version (current: v$VERSION)"
          echo "Run 'c9cli update' to update."
        else
          echo "You are using the latest version (v$VERSION)."
        fi
        return 0
      else
        echo "Failed to extract version information."
      fi
    else
      echo "Failed to connect to update server on attempt $attempt of $max_attempts."
    fi

    attempt=$((attempt + 1))
    [ $attempt -le $max_attempts ] && {
      echo "Retrying in 2 seconds..."
      sleep 2
    }
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
    echo "$current_time" >"$LAST_CHECK_FILE"
  fi
else
  echo "$current_time" >"$LAST_CHECK_FILE"
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
  echo "  status            : Show status of quick created C9"
  echo "  stop              : Stop quick created C9"
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
  echo "-q                  : Storage limit for workspace (ext4 quota, e.g., 10G / 500M; 0=unlimited)"
  echo "-n                  : Rclone remote name"
  echo "-h                  : Backup hour"
  echo "-f                  : Backup folder name"
  echo "-s                  : Backup service provider"
  echo
  echo "Copyright (c) 2024 c9cli (under AGPL-3.0 License)"
  echo "Built with love♡ by gvoze32"
}

# CREATE SYSTEMD

createnewsystemd() {
  OPTIND=1
  while getopts "u:p:o:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    p) pw="$OPTARG" ;;
    o) port="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Username: " user
  fi
  if [[ -z "$pw" ]]; then
    read -rp "Password: " pw
  fi
  if [[ -z "$port" ]]; then
    read -rp "Port: " port
  fi
  echo
  echo "Creating workspace:"
  echo "Username: $user"
  echo "Password: $pw"
  echo "Port: $port"

  apt-get update -y
  apt-get upgrade -y

  adduser --disabled-password --gecos "" "$user"

  case $ubuntu_version in
  24.04 | 22.04 | 20.04)
    echo "$user:$pw" | chpasswd
    mkdir -p /home/"$user"/my-projects /home/"$user"/c9sdk
    chown -R "$user":"$user" /home/"$user"
    chmod 700 /home/"$user"
    sudo -u "$user" git clone --depth=5 https://github.com/c9/core.git /home/"$user"/c9sdk
    sudo -u "$user" bash -c "cd /home/$user/c9sdk && scripts/install-sdk.sh"
    ;;
  18.04)
    echo -e "$pw\n$pw" | passwd "$user"
    mkdir -p /home/"$user"/my-projects /home/"$user"/c9sdk
    chown -R "$user":"$user" /home/"$user"
    chmod 700 /home/"$user"
    sudo -u "$user" git clone --depth=5 https://github.com/c9/core.git /home/"$user"/c9sdk
    sudo -u "$user" -H sh -c "cd /home/$user/c9sdk; scripts/install-sdk.sh"
    ;;
  esac

  cat >"/lib/systemd/system/c9-$user.service" <<EOF
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
  systemctl enable "c9-$user.service"
  systemctl restart "c9-$user.service"
  sleep 10
  systemctl status "c9-$user.service"
}

createnewsystemdlimit() {
  OPTIND=1
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
    read -rp "Username: " user
  fi
  if [[ -z "$pw" ]]; then
    read -rp "Password: " pw
  fi
  if [[ -z "$port" ]]; then
    read -rp "Port: " port
  fi
  if [[ -z "$limit" ]]; then
    read -rp "Memory Limit (e.g., 1024m): " limit
  fi
  if [[ -z "$cpu_limit" ]]; then
    read -rp "CPU Limit (e.g., 10%): " cpu_limit
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

  adduser --disabled-password --gecos "" "$user"

  case $ubuntu_version in
  24.04 | 22.04 | 20.04)
    echo "$user:$pw" | chpasswd
    mkdir -p /home/"$user"/my-projects /home/"$user"/c9sdk
    chown -R "$user":"$user" /home/"$user"
    chmod 700 /home/"$user"
    sudo -u "$user" git clone --depth=5 https://github.com/c9/core.git /home/"$user"/c9sdk
    sudo -u "$user" bash -c "cd /home/$user/c9sdk && scripts/install-sdk.sh"
    ;;
  18.04)
    echo -e "$pw\n$pw" | passwd "$user"
    mkdir -p /home/"$user"/my-projects /home/"$user"/c9sdk
    chown -R "$user":"$user" /home/"$user"
    chmod 700 /home/"$user"
    sudo -u "$user" git clone --depth=5 https://github.com/c9/core.git /home/"$user"/c9sdk
    sudo -u "$user" -H sh -c "cd /home/$user/c9sdk; scripts/install-sdk.sh"
    ;;
  esac

  cat >"/lib/systemd/system/c9-$user.service" <<EOF
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
  systemctl enable "c9-$user.service"
  systemctl restart "c9-$user.service"
  sleep 10
  systemctl status "c9-$user.service"
}

createnewdocker() {
  OPTIND=1
  while getopts "u:p:o:i:q:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    p) pw="$OPTARG" ;;
    o) port="$OPTARG" ;;
    i) image="$OPTARG" ;;
    q) storage_limit="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Username: " user
  fi
  if [[ -z "$pw" ]]; then
    read -rp "Password: " pw
  fi
  if [[ -z "$port" ]]; then
    read -rp "Port: " port
  fi
  if [[ -z "$image" ]]; then
    echo "Select image:"
    echo "1. Ubuntu 20.04"
    echo "2. Ubuntu 22.04"
    echo "3. Ubuntu 24.04"
    echo "4. Custom image"
    read -rp "Enter image option (1-4): " image_choice
    case "$image_choice" in
    1)
      image="gvoze32/cloud9:focal"
      ;;
    2)
      image="gvoze32/cloud9:jammy"
      ;;
    3)
      image="gvoze32/cloud9:noble"
      ;;
    4)
      read -rp "Enter custom Docker image (e.g., repo/image:tag): " image
      if [[ -z "$image" ]]; then
        echo "No image entered, using default image."
        image="gvoze32/cloud9:jammy"
      fi
      ;;
    *)
      echo "Invalid option, using default image."
      image="gvoze32/cloud9:jammy"
      ;;
    esac
  else
    echo "Using provided image: $image"
  fi

  if [[ -z "$storage_limit" ]]; then
    read -rp "Storage Limit (ext4 quota, e.g., 10G; 0=unlimited, blank=skip): " storage_limit
  fi
  echo
  echo "Creating docker container:"
  echo "Username: $user"
  echo "Password: $pw"
  echo "Port: $port"
  echo "Image: $image"
  if [[ -n "$storage_limit" ]]; then
    echo "Storage Limit: $storage_limit"
  fi

  cd /home/c9users || return 1
  rm -f .env
  cat >/home/c9users/.env <<EOF
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
PORT=$port
DOCKER_IMAGE=$image
EOF
  docker compose -p "$user" up -d
  if [ -d "/home/c9users/$user" ]; then
    if [[ -n "$storage_limit" ]]; then
      set_user_storage_quota_for_path "$user" "$storage_limit" "/home/c9users/$user" || true
    fi

    cd /home/c9users/"$user" || return 1

    ### Your custom default bundling files goes here, it's recommended to put it on resources directory
    ### START

    ### END

    cd ~ || true
  else
    echo -e "\033[33mWARN! Workspace directory not found - Ignore this message if you are not adding default bundling files\033[0m"
  fi
}

# CREATE DOCKERLIMIT
createnewdockermemlimit() {
  OPTIND=1
  while getopts "u:p:o:l:c:i:q:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    p) pw="$OPTARG" ;;
    o) port="$OPTARG" ;;
    l) limit="$OPTARG" ;;
    c) cpu_limit="$OPTARG" ;;
    i) image="$OPTARG" ;;
    q) storage_limit="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Username: " user
  fi
  if [[ -z "$pw" ]]; then
    read -rp "Password: " pw
  fi
  if [[ -z "$port" ]]; then
    read -rp "Port: " port
  fi
  if [[ -z "$limit" ]]; then
    read -rp "Memory Limit (e.g., 1024m): " limit
  fi
  if [[ -z "$cpu_limit" ]]; then
    read -rp "CPU Limit (e.g., 1.0 for 1 core): " cpu_limit
  fi
  if [[ -z "$image" ]]; then
    echo "Select image:"
    echo "1. Ubuntu 20.04"
    echo "2. Ubuntu 22.04"
    echo "3. Ubuntu 24.04"
    echo "4. Custom image"
    read -rp "Enter image option (1-4): " image_choice
    case "$image_choice" in
    1)
      image="gvoze32/cloud9:focal"
      ;;
    2)
      image="gvoze32/cloud9:jammy"
      ;;
    3)
      image="gvoze32/cloud9:noble"
      ;;
    4)
      read -rp "Enter custom Docker image (e.g., repo/image:tag): " image
      if [[ -z "$image" ]]; then
        echo "No image entered, using default image."
        image="gvoze32/cloud9:jammy"
      fi
      ;;
    *)
      echo "Invalid option, using default image."
      image="gvoze32/cloud9:jammy"
      ;;
    esac
  else
    echo "Using provided image: $image"
  fi
  echo
  echo "Creating docker container with memory limit:"
  echo "Username: $user"
  echo "Password: $pw"
  echo "Port: $port"
  if [[ -z "$storage_limit" ]]; then
    read -rp "Storage Limit (ext4 quota, e.g., 10G; 0=unlimited, blank=skip): " storage_limit
  fi

  echo "Memory Limit: $limit"
  echo "CPU Limit: $cpu_limit"
  echo "Image: $image"
  if [[ -n "$storage_limit" ]]; then
    echo "Storage Limit: $storage_limit"
  fi

  cd /home/c9usersmemlimit || return 1
  rm -f .env
  cat >/home/c9usersmemlimit/.env <<EOF
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$pw
PORT=$port
MEMORY=$limit
CPU_LIMIT=$cpu_limit
DOCKER_IMAGE=$image
EOF
  docker compose -p "$user" up -d
  if [ -d "/home/c9usersmemlimit/$user" ]; then
    if [[ -n "$storage_limit" ]]; then
      set_user_storage_quota_for_path "$user" "$storage_limit" "/home/c9usersmemlimit/$user" || true
    fi

    cd /home/c9usersmemlimit/"$user" || return 1

    ### Your custom default bundling files goes here, it's recommended to put it on resources directory
    ### START

    ### END

    cd ~ || true
  else
    echo -e "\033[33mWARN! Workspace directory not found - Ignore this message if you are not adding default bundling files\033[0m"
  fi
}

# MANAGE SYSTEMD

stopsystemd() {
  OPTIND=1
  while getopts "u:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  sleep 3
  systemctl stop "c9-$user.service"
}

startsystemd() {
  OPTIND=1
  while getopts "u:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  sleep 3
  systemctl start "c9-$user.service"
}

deletesystemd() {
  OPTIND=1
  while getopts "u:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  sleep 3
  systemctl stop "c9-$user.service"
  sleep 3
  killall -u "$user"
  sleep 3
  userdel "$user"
  # OPTIONAL: Remove user directory
  # rm -rf /home/$user
}

statussystemd() {
  OPTIND=1
  while getopts "u:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  systemctl status "c9-$user.service"
}

restartsystemd() {
  OPTIND=1
  while getopts "u:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  systemctl daemon-reload
  systemctl enable "c9-$user.service"
  systemctl restart "c9-$user.service"
  sleep 10
  systemctl status "c9-$user.service"
}

changepasswordsystemd() {
  OPTIND=1
  while getopts "u:p:o:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    p) password="$OPTARG" ;;
    o) port="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  if [[ -z "$password" ]]; then
    read -rp "Input New Password: " password
  fi

  if [[ -z "$port" ]]; then
    read -rp "Input New Port: " port
  fi

  sed -i "s/-a $user:[^ ]*/-a $user:$password/" "/lib/systemd/system/c9-$user.service"
  sed -i "s/PORT=.*/PORT=$port/" "/lib/systemd/system/c9-$user.service"

  systemctl daemon-reload
  systemctl restart "c9-$user.service"
  sleep 10
  systemctl status "c9-$user.service"
}

schedulesystemd() {
  read -rp "Input User: " user
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
  read -rp "Time: " waktu
  at "$waktu" <<END
sleep 3
systemctl stop "c9-$user.service"
# OPTIONAL: Remove user directory
# sleep 3
# killall -u "$user"
# sleep 3
# userdel "$user"
END
}

scheduledatq() {
  atq
}

convertsystemd() {
  read -rp "Input User: " user
  echo "Input user password"
  passwd "$user"
  echo "Warning, C9 will be restart!"
  usermod -aG sudo "$user"
  systemctl daemon-reload
  systemctl enable "c9-$user.service"
  systemctl restart "c9-$user.service"
  sleep 10
  systemctl status "c9-$user.service"
}

# MANAGE DOCKER

stopdocker() {
  OPTIND=1
  while getopts "u:t:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  if [[ -z "$type" ]]; then
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
  else
    response="$type"
  fi

  case "$response" in
  1)
    cd /home/c9users || return 1
    ;;
  *)
    cd /home/c9usersmemlimit || return 1
    ;;
  esac
  docker compose -p "$user" stop
}

startdocker() {
  OPTIND=1
  while getopts "u:t:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  if [[ -z "$type" ]]; then
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
  else
    response="$type"
  fi

  case "$response" in
  1)
    cd /home/c9users || return 1
    ;;
  *)
    cd /home/c9usersmemlimit || return 1
    ;;
  esac
  docker compose -p "$user" start
}

deletedocker() {
  OPTIND=1
  while getopts "u:t:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  if [[ -z "$type" ]]; then
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
  else
    response="$type"
  fi

  case "$response" in
  1)
    cd /home/c9users || return 1
    ;;
  *)
    cd /home/c9usersmemlimit || return 1
    ;;
  esac
  docker compose -p "$user" down
  # OPTIONAL: Remove user directory
  # rm -rf $user
}

listdocker() {
  docker ps
}

statusdocker() {
  docker stats
}

changepassworddocker() {
  OPTIND=1
  while getopts "u:p:t:o:l:c:i:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    p) newpw="$OPTARG" ;;
    t) type="$OPTARG" ;;
    o) port="$OPTARG" ;;
    l) mem="$OPTARG" ;;
    c) cpu_limit="$OPTARG" ;;
    i) image="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input Username: " user
  fi

  if [[ -z "$newpw" ]]; then
    read -rp "Input New Password: " newpw
  fi

  if [[ -z "$port" ]]; then
    read -rp "Input Port: " port
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
      read -rp "Memory Limit (e.g., 1024m): " mem
    fi
    if [[ -z "$cpu_limit" ]]; then
      read -rp "CPU Limit (e.g., 1.0 for 1 core): " cpu_limit
    fi
    ;;
  *)
    echo "Invalid option"
    return
    ;;
  esac

  if [[ -z "$image" ]] && [ -f "$base_dir/.env" ]; then
    image=$(grep '^DOCKER_IMAGE=' "$base_dir/.env" | cut -d '=' -f2-)
  fi

  if [[ -z "$image" ]]; then
    echo "Select Docker image:"
    echo "1. Ubuntu 20.04"
    echo "2. Ubuntu 22.04"
    echo "3. Ubuntu 24.04"
    echo "4. Custom image"
    read -rp "Enter image option (1-4): " image_choice
    case "$image_choice" in
    1)
      image="gvoze32/cloud9:focal"
      ;;
    2)
      image="gvoze32/cloud9:jammy"
      ;;
    3)
      image="gvoze32/cloud9:noble"
      ;;
    4)
      read -rp "Enter custom Docker image (e.g., repo/image:tag): " image
      if [[ -z "$image" ]]; then
        echo "No image entered, using default image."
        image="gvoze32/cloud9:jammy"
      fi
      ;;
    *)
      echo "Invalid option, using default image."
      image="gvoze32/cloud9:jammy"
      ;;
    esac
  fi

  cd "$base_dir" || return

  cat >.env <<EOF
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$newpw
PORT=$port
DOCKER_IMAGE=$image
EOF

  if [ "$response" = "2" ]; then
    cat >>.env <<EOF
MEMORY=$mem
CPU_LIMIT=$cpu_limit
EOF
  fi

  if [ -d "$base_dir/$user" ]; then
    cd "$base_dir/$user" || return
    cat >.env <<EOF
PORT=$port
NAMA_PELANGGAN=$user
PASSWORD_PELANGGAN=$newpw
DOCKER_IMAGE=$image
EOF

    if [ "$response" = "2" ]; then
      cat >>.env <<EOF
MEMORY=$mem
CPU_LIMIT=$cpu_limit
EOF
    fi

    cd "$base_dir" || return 1
    echo "Password, port and .env updated for user $user"
    docker compose -p "$user" down
    docker compose -p "$user" up -d
    echo "Docker container recreated for user $user"
  else
    echo "User $user does not exist or workspace directory not found"
  fi
}

scheduledocker() {
  read -rp "Input User: " user
  echo Is this workspace using docker or dockermemlimit?
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
  read -rp "Time: " waktu
  case "$response" in
  [yY][eE][sS] | [yY])
    at "$waktu" <<END
cd /home/c9users
docker compose -p "$user" stop
# OPTIONAL: Remove user setup
# docker compose -p "$user" down
END
    ;;
  *)
    at "$waktu" <<END
cd /home/c9usersmemlimit
docker compose -p "$user" stop
# OPTIONAL: Remove user setup
# docker compose -p "$user" down
END
    ;;
  esac
}

configuredocker() {
  read -rp "Input User: " user
  echo "1. Stop"
  echo "2. Start"
  echo "3. Restart"
  read -r -p "Choose: " action
  case "$action" in
  1)
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
    case "$response" in
    1)
      cd /home/c9users || return 1
      ;;
    *)
      cd /home/c9usersmemlimit || return 1
      ;;
    esac
    docker container stop "$user"
    # OPTIONAL: Remove user setup
    # docker compose -p "$user" down
    ;;
  2)
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
    case "$response" in
    1)
      cd /home/c9users || return 1
      ;;
    *)
      cd /home/c9usersmemlimit || return 1
      ;;
    esac
    docker container start "$user"
    ;;
  *)
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
    case "$response" in
    1)
      cd /home/c9users || return 1
      ;;
    *)
      cd /home/c9usersmemlimit || return 1
      ;;
    esac
    docker container stop "$user"
    docker container start "$user"
    # OPTIONAL: Remove user setup
    # docker compose -p "$user" down
    # docker compose -p "$user" up -d
    ;;
  esac
}

restartdocker() {
  OPTIND=1
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
    read -rp "Input User: " user
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

restartdockerall() {
  running=$(docker ps -q)
  if [[ -n "$running" ]]; then
    docker restart "$running"
  else
    echo "No running containers to restart."
  fi
}

resetdocker() {
  OPTIND=1
  while getopts "u:t:" opt; do
    case $opt in
    u) user="$OPTARG" ;;
    t) type="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  if [[ -z "$user" ]]; then
    read -rp "Input User: " user
  fi

  if [[ -z "$type" ]]; then
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -r -p "Choose: " response
  else
    response="$type"
  fi

  case "$response" in
  1)
    cd /home/c9users || return 1
    ;;
  *)
    cd /home/c9usersmemlimit || return 1
    ;;
  esac
  docker compose -p "$user" down
  docker compose -p "$user" up -d
}

# MANAGEMENTS

backups() {
  OPTIND=1
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
    read -rp "If all has been set up correctly, then input your rclone remote name: " name
  fi
  if [[ -z "$hour" ]]; then
    read -rp "Enter the time for backup (hour 0-23): " hour
  fi
  if [[ -z "$cloud_folder" ]]; then
    read -rp "Define the backup folder name on the cloud: " cloud_folder
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
  1|2|3|4|5)
    backup_path="$cloud_folder"
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
  esac

  cat >/home/backup-"$name".sh <<EOF
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

            if ! zip -r "/home/backup/\$folder-\$user-\$date.zip" "\$user_folder" -x "*/\.c9/*" "\$user_folder.c9/*" "*/node_modules/*" >> "\$log_file" 2>&1; then
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

  chmod +x /home/backup-"$name".sh
  echo ""
  echo "Backup command created"

  crontab -l >current_cron
  echo "0 $hour * * * /home/backup-$name.sh >> /home/backup-$name.log 2>&1" >>current_cron
  crontab current_cron
  rm current_cron

  echo ""
  echo "Cron job created"
  echo ""
  echo "Make sure it's included in your cron list:"
  crontab -l
  echo "Backup rule successfully added"
}

portlist() {
  lsof -i -P -n | grep LISTEN
}

updates() {
  echo "Checking for updates..."

  REPO_URL="https://jayanode.com/api/mirror/c9cli/c9cli?raw=true"
  max_attempts=3
  attempt=1

  while [ $attempt -le $max_attempts ]; do
    if latest_info=$(curl -s --connect-timeout 10 "$REPO_URL/c9cli"); then
      latest_version=$(echo "$latest_info" | grep -o 'VERSION="[0-9]*\.[0-9]*"' | cut -d '"' -f 2)

      if [ -n "$latest_version" ]; then
        if [ "$latest_version" != "$VERSION" ]; then
          echo "Updating to version $latest_version..."

          # Create temporary file
          temp_file=$(mktemp)

          # Download to temporary file first
          if curl -fsSL "$REPO_URL/c9cli" -o "$temp_file"; then
            # Verify file was downloaded correctly
            if [ -s "$temp_file" ] && grep -q "VERSION=\"$latest_version\"" "$temp_file"; then
              # Move temporary file to final location
              if sudo mv "$temp_file" /usr/local/bin/c9cli && sudo chmod +x /usr/local/bin/c9cli; then
                echo "Successfully updated to version $latest_version!"
                echo "Please restart your shell or run 'source /usr/local/bin/c9cli' to use the new version."
                return 0
              else
                echo "Failed to install the update. Please check permissions and try again."
              fi
            else
              echo "Downloaded file appears to be invalid. Update aborted."
            fi
          else
            echo "Failed to download update. Please check your internet connection."
          fi

          # Clean up temporary file if it exists
          [ -f "$temp_file" ] && rm -f "$temp_file"
        else
          echo "You are already using the latest version ($VERSION)."
          return 0
        fi
      fi
    fi

    attempt=$((attempt + 1))
    [ $attempt -le $max_attempts ] && sleep 2
  done

  echo "Failed to check for updates after $max_attempts attempts."
  return 1
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

  cd /root/c9sdk || { echo "C9 SDK not found"; return 1; }
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

statusquickcreate() {
  echo "Checking C9 Server Status..."

  if pgrep -f "node.*server.js" >/dev/null; then
    echo "C9 Server is RUNNING"
    ipvpsmu=$(curl -s ifconfig.me)
    echo "Access Cloud9 IDE at: http://$ipvpsmu:8080"

    # Show process details
    echo -e "\nProcess details:"
    pgrep -af "node.*server.js"
  else
    echo "C9 Server is NOT RUNNING"
  fi
}

stopquickcreate() {
  echo "Stopping C9 Server..."

  if pgrep -f "node.*server.js" >/dev/null; then
    pkill -f "node.*server.js"
    echo "C9 Server Stopped Successfully"
  else
    echo "C9 Server is not running"
  fi
}

# BASIC MENUS

helps() {
  banner
  bantuan
}

versions() {
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
  status)
    statusquickcreate
    ;;
  stop)
    stopquickcreate
    ;;
  "")
    quickcreatec9
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
