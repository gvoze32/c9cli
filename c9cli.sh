#!/bin/bash
VERSION="5.32"

UPDATE_URL="https://jayanode.com/api/mirror/c9cli/c9cli?raw=true"
INSTALL_PATH="/usr/local/bin/c9cli"
STATE_DIR="/var/lib/c9cli"
LAST_CHECK_FILE="$STATE_DIR/last_check"
CHECK_INTERVAL=86400

DOCKER_DIR_PLAIN="/home/c9users"
DOCKER_DIR_LIMIT="/home/c9usersmemlimit"
DEFAULT_IMAGE="gvoze32/cloud9:jammy"
BACKUP_SCRIPT_DIR="/home"

QUICK_SDK_DIR="/root/c9sdk"
QUICK_WORKSPACE="/root/workspace"
QUICK_PORT=8080
QUICK_LOG="/var/log/c9cli-quickcreate.log"

TIME_FORMATS='
Format Example for Time:

10:00 AM 6/22/2015
10:00 AM July 25
10:00 AM
10:00 AM Sun
10:00 AM next month
10:00 AM tomorrow
now + 1 hour
now + 30 minutes
now + 1 week
now + 1 year
midnight
'

# ============================ GENERIC HELPERS ============================ #

err() {
  echo "$*" >&2
}

# parse_args <getopts-spec> <args...>
# Stores every option value in OPT_<letter>; "-a" is repeatable and collected
# in the OPT_A array. Returns 2 on an invalid option, a missing value or a
# stray positional argument.
parse_args() {
  local spec="$1" opt v
  shift
  for v in ${!OPT_@}; do unset "$v"; done
  OPT_A=()
  OPTIND=1
  while getopts ":$spec" opt; do
    case "$opt" in
    :)
      err "Option -$OPTARG requires an argument"
      return 2
      ;;
    \?)
      err "Invalid option: -$OPTARG"
      return 2
      ;;
    a)
      if [[ -z "$OPTARG" || "$OPTARG" == -* ]]; then
        err "Invalid additional folder/file path"
        return 2
      fi
      OPT_A+=("$OPTARG")
      ;;
    *) printf -v "OPT_$opt" '%s' "$OPTARG" ;;
    esac
  done
  if ((OPTIND <= $#)); then
    err "Unexpected argument: ${!OPTIND}"
    return 2
  fi
  return 0
}

# opt <letter>: value of a parsed option (empty when not given)
opt() {
  local v="OPT_$1"
  printf '%s' "${!v:-}"
}

# ask <letter> <prompt> [secret]: prompt for an option that was not given.
# A closed stdin (the agent runs with stdin ignored) yields an empty value
# which the callers' validation then rejects instead of hanging.
ask() {
  local key="$1" prompt="$2" secret="${3:-}" value=""
  [[ -n "$(opt "$key")" ]] && return 0
  if [[ -n "$secret" ]]; then
    read -rsp "$prompt" value || true
    echo
  else
    read -rp "$prompt" value || true
  fi
  printf -v "OPT_$key" '%s' "$value"
}

# check <message> <command...>: run a validator, print message on failure
check() {
  local message="$1"
  shift
  "$@" && return 0
  err "$message"
  return 1
}

valid_user() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; }
valid_port() { [[ "$1" =~ ^[0-9]+$ ]] && ((10#$1 >= 1 && 10#$1 <= 65535)); }
valid_password() { [[ -n "$1" && "$1" != *"'"* && "$1" != *$'\n'* && "$1" != *$'\r'* ]]; }
valid_docker_mem() { [[ "$1" =~ ^[0-9]+[bBkKmMgG]?$ ]]; }
valid_docker_cpu() { [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; }
valid_systemd_mem() { [[ "$1" =~ ^[0-9]+[KkMmGgTt]?$ || "$1" =~ ^[0-9]+%$ ]]; }
valid_systemd_cpu() { [[ "$1" =~ ^[0-9]+(\.[0-9]+)?%?$ ]]; }
valid_image() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._/:@-]*$ ]]; }
valid_remote_name() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; }
valid_backup_hour() { [[ "$1" =~ ^([0-9]|1[0-9]|2[0-3])$ ]]; }

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }

# docker compose project names must be lowercase
project_name() { lower "$1"; }
container_name() { echo "c9-$1"; }

# choose_image <letter> [fallback-image]
# Sets OPT_<letter> to the chosen image: keeps a provided one, otherwise asks
# (menu) or uses the fallback.
choose_image() {
  local key="$1" fallback="${2:-}" choice="" image
  image="$(opt "$key")"
  if [[ -n "$image" ]]; then
    echo "Using provided image: $image"
    return 0
  fi
  if [[ -n "$fallback" ]]; then
    printf -v "OPT_$key" '%s' "$fallback"
    return 0
  fi
  echo "Select image (Docker container base):"
  echo "1. Ubuntu 20.04"
  echo "2. Ubuntu 22.04"
  echo "3. Ubuntu 24.04"
  echo "4. Custom image"
  echo "5. Ubuntu 26.04"
  read -rp "Enter image option (1-5): " choice || true
  case "$choice" in
  1) image="gvoze32/cloud9:focal" ;;
  2) image="gvoze32/cloud9:jammy" ;;
  3) image="gvoze32/cloud9:noble" ;;
  5) image="gvoze32/cloud9:resolute" ;;
  4)
    read -rp "Enter custom Docker image (e.g., repo/image:tag): " image || true
    if [[ -z "$image" ]]; then
      echo "No image entered, using default image."
      image="$DEFAULT_IMAGE"
    fi
    ;;
  *)
    echo "Invalid option, using default image."
    image="$DEFAULT_IMAGE"
    ;;
  esac
  printf -v "OPT_$key" '%s' "$image"
}

# select_docker_base [type]: asks when type is empty. Sets DOCKER_TYPE (1|2)
# and DOCKER_BASE (the directory that holds docker-compose.yml and .env).
select_docker_base() {
  local type="${1:-}"
  if [[ -z "$type" ]]; then
    echo "Is this workspace using Docker or Docker Memory Limit?"
    echo "1. Docker"
    echo "2. Docker Memory Limit"
    read -rp "Choose: " type || true
  fi
  case "$type" in
  1)
    DOCKER_TYPE=1
    DOCKER_BASE="$DOCKER_DIR_PLAIN"
    ;;
  2)
    DOCKER_TYPE=2
    DOCKER_BASE="$DOCKER_DIR_LIMIT"
    ;;
  *)
    err "Invalid workspace type '$type' (use 1 for Docker, 2 for Docker Memory Limit)"
    return 2
    ;;
  esac
}

# docker_compose <base-dir> <user> <compose args...>
docker_compose() {
  local base="$1" user="$2"
  shift 2
  (cd "$base" && docker compose -p "$(project_name "$user")" "$@")
}

# with_base_lock <base-dir> <command...>
# The compose file of a base dir is shared by all its users and reads the
# shared .env, so writers must not interleave.
with_base_lock() {
  local base="$1"
  shift
  (
    exec 9>"$base/.c9cli.lock" || exit 1
    flock -w 300 9 || {
      err "Timed out waiting for the lock on $base"
      exit 1
    }
    "$@"
  )
}

# write_env_file <user> <password> <port> <image> [memory cpu]  (into cwd)
# Compose reads .env with interpolation; single quotes keep $ and # literal.
write_env_file() {
  local tmp
  tmp="$(mktemp .env.XXXXXX)" || return 1
  {
    printf 'NAMA_PELANGGAN=%s\n' "$1"
    printf "PASSWORD_PELANGGAN='%s'\n" "$2"
    printf 'PORT=%s\n' "$3"
    printf 'DOCKER_IMAGE=%s\n' "$4"
    if [[ -n "${5:-}" ]]; then
      printf 'MEMORY=%s\nCPU_LIMIT=%s\n' "$5" "${6:-}"
    fi
  } >"$tmp"
  if ! mv -f "$tmp" .env; then
    rm -f "$tmp"
    return 1
  fi
}

# docker_up_locked <base> <recreate:0|1> <user> <password> <port> <image> [memory cpu]
# Runs under with_base_lock. Variables are also exported so compose never
# depends on whatever user wrote .env last.
docker_up_locked() {
  local base="$1" recreate="$2" user="$3" pw="$4" port="$5" image="$6" mem="${7:-}" cpu="${8:-}"
  cd "$base" || return 1
  write_env_file "$user" "$pw" "$port" "$image" "$mem" "$cpu" || return 1
  export NAMA_PELANGGAN="$user" PASSWORD_PELANGGAN="$pw" PORT="$port" DOCKER_IMAGE="$image"
  if [[ -n "$mem" ]]; then
    export MEMORY="$mem" CPU_LIMIT="$cpu"
  fi
  if [[ "$recreate" == 1 ]]; then
    docker compose -p "$(project_name "$user")" down || return 1
  fi
  docker compose -p "$(project_name "$user")" up -d
}

# ============================ STORAGE QUOTA ============================ #

# prints the limit in KB ("0" = unlimited)
parse_quota_limit() {
  local raw="${1// /}"
  if [[ "$raw" == "0" ]]; then
    echo 0
    return 0
  fi
  if [[ "$raw" =~ ^([0-9]+)([MmGg])$ ]]; then
    local num="${BASH_REMATCH[1]}" unit="${BASH_REMATCH[2]}"
    case "$unit" in
    M | m) echo $((10#$num * 1024)) ;;
    *) echo $((10#$num * 1024 * 1024)) ;;
    esac
    return 0
  fi
  return 1
}

# quota_mount_info <path>: prints "<mountpoint> <fstype> <options>"
quota_mount_info() {
  findmnt -n -o TARGET,FSTYPE,OPTIONS --target "$1" 2>/dev/null
}

ensure_ext4_usrquota_ready_for_path() {
  local target_path="$1" mountpoint fstype options

  if ! command -v quotacheck >/dev/null 2>&1 || ! command -v quotaon >/dev/null 2>&1 || ! command -v setquota >/dev/null 2>&1; then
    echo "WARN! quota tools not found (quotacheck/quotaon/setquota). Install 'quota' package to enable storage limits."
    return 1
  fi

  read -r mountpoint fstype options < <(quota_mount_info "$target_path")
  if [[ -z "$mountpoint" ]]; then
    echo "WARN! Unable to determine mount point for $target_path. Storage limit skipped."
    return 1
  fi

  if [[ "$fstype" != "ext4" ]]; then
    echo "WARN! Filesystem for $target_path is '$fstype' (not ext4). Storage limit skipped."
    return 1
  fi

  # usrjquota= is the journaled-quota spelling of usrquota
  if [[ ",$options," != *,usrquota,* && "$options" != *usrjquota=* ]]; then
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
  local q_user="$1" limit_str="$2" ws_path="$3" kb mountpoint fstype options out

  if [[ -z "$q_user" || -z "$limit_str" || -z "$ws_path" ]]; then
    echo "WARN! Missing args for storage limit; skipped."
    return 1
  fi

  if ! kb="$(parse_quota_limit "$limit_str")"; then
    echo "WARN! Invalid storage limit '$limit_str' (use e.g. 10G, 500M, 0). Skipped."
    return 1
  fi

  ensure_ext4_usrquota_ready_for_path "$ws_path" || return 1
  read -r mountpoint fstype options < <(quota_mount_info "$ws_path")

  if [[ "$kb" == "0" ]]; then
    echo "Setting storage limit: unlimited (quota cleared) for user '$q_user' on $mountpoint"
    out="$(setquota -u "$q_user" 0 0 0 0 "$mountpoint" 2>&1)" || echo "WARN! setquota failed: $out"
    return 0
  fi

  echo "Setting storage limit: $limit_str for user '$q_user' on $mountpoint"
  out="$(setquota -u "$q_user" "$kb" "$kb" 0 0 "$mountpoint" 2>&1)" || echo "WARN! setquota failed: $out"
  return 0
}

# ============================ UPDATES ============================ #

# prints the latest published version, returns 1 when it cannot be read
fetch_remote_version() {
  local version
  version="$(curl -fsS --connect-timeout 10 --max-time 30 "$UPDATE_URL" 2>/dev/null |
    grep -o 'VERSION="[0-9]*\.[0-9]*"' | head -n 1 | cut -d '"' -f 2)"
  [[ -n "$version" ]] || return 1
  echo "$version"
}

# version_gt <a> <b>: true when a is newer than b
version_gt() {
  [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" == "$1" ]]
}

check_update() {
  local latest
  echo "Checking for available updates..."
  if ! latest="$(fetch_remote_version)"; then
    echo "Could not check for updates (update server unreachable)."
    return 1
  fi
  if version_gt "$latest" "$VERSION"; then
    echo "New version available: v$latest (current: v$VERSION)"
    echo "Run 'c9cli update' to update."
  else
    echo "You are using the latest version (v$VERSION)."
  fi
}

# Daily, interactive sessions only: scripted callers (the agent, cron) never
# wait for or parse the update check.
check_update_if_due() {
  local now last=0
  [[ -t 1 ]] || return 0
  now="$(date +%s)"
  [[ -r "$LAST_CHECK_FILE" ]] && last="$(<"$LAST_CHECK_FILE")"
  [[ "$last" =~ ^[0-9]+$ ]] || last=0
  ((now - last > CHECK_INTERVAL)) || return 0
  install -d -m 700 "$STATE_DIR" 2>/dev/null && echo "$now" >"$LAST_CHECK_FILE"
  check_update
}

updates() {
  local attempt latest tmp
  echo "Checking for updates..."
  for attempt in 1 2 3; do
    if latest="$(fetch_remote_version)"; then
      if ! version_gt "$latest" "$VERSION"; then
        echo "You are already using the latest version ($VERSION)."
        return 0
      fi
      echo "Updating to version $latest..."
      tmp="$(mktemp "$(dirname "$INSTALL_PATH")/.c9cli-update.XXXXXX")" || {
        err "Cannot create a temporary file next to $INSTALL_PATH."
        return 1
      }
      if curl -fsSL --connect-timeout 10 --max-time 120 "$UPDATE_URL" -o "$tmp" &&
        [[ -s "$tmp" ]] && grep -q "^VERSION=\"$latest\"" "$tmp" && bash -n "$tmp"; then
        if chmod 755 "$tmp" && mv -f "$tmp" "$INSTALL_PATH"; then
          echo "Successfully updated to version $latest!"
          return 0
        fi
        err "Failed to install the update. Please check permissions and try again."
      else
        err "Downloaded file appears to be invalid. Update aborted."
      fi
      rm -f "$tmp"
    fi
    ((attempt < 3)) && sleep 2
  done
  err "Failed to update after 3 attempts."
  return 1
}

# ============================ INFO ============================ #

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
  echo "    - Debian  : Ubuntu 18.04, 20.04, 22.04, 24.04, 26.04"
  echo
  echo "Built with love♡ by gvoze32"
}

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
  echo "-c                  : CPU limit (e.g., 1.0 for Docker; 10% or 1.0 for SystemD)"
  echo "-i                  : Image (e.g., gvoze32/cloud9:jammy)"
  echo "-t                  : Type (e.g., 1 for Docker, 2 for Docker Memory Limit)"
  echo "-q                  : Storage limit for workspace (ext4 quota, e.g., 10G / 500M; 0=unlimited)"
  echo "-n                  : Rclone remote name"
  echo "-h                  : Backup hour"
  echo "-f                  : Backup folder name"
  echo "-s                  : Backup service provider"
  echo "-a                  : Additional folder/file (repeatable)"
  echo
  echo "Copyright (c) 2024 c9cli (under AGPL-3.0 License)"
  echo "Built with love♡ by gvoze32"
}

helps() {
  banner
  bantuan
}

versions() {
  banner
  about
}

# ============================ SYSTEMD WORKSPACES ============================ #

systemd_unit_path() {
  echo "/lib/systemd/system/c9-$1.service"
}

# systemd_quote <string>: one double-quoted ExecStart word. systemd expands
# %specifiers and $VARIABLES inside unit files, so both must be doubled.
systemd_quote() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//%/%%}"
  s="${s//\$/\$\$}"
  printf '"%s"' "$s"
}

systemd_exec_start() {
  local user="$1" pw="$2"
  printf '/usr/bin/node /home/%s/c9sdk/server.js -a %s --listen 0.0.0.0 --packed -w /home/%s/my-projects' \
    "$user" "$(systemd_quote "$user:$pw")" "$user"
}

# write_systemd_unit <user> <password> <port> [memory cpu-quota]
write_systemd_unit() {
  local user="$1" pw="$2" port="$3" mem="${4:-}" cpu="${5:-}" unit
  unit="$(systemd_unit_path "$user")"
  (
    umask 077 # the unit holds the password
    {
      echo "[Unit]"
      echo "Description=c9 for $user"
      echo "After=network.target"
      echo
      echo "[Service]"
      echo "Type=simple"
      echo "ExecStart=$(systemd_exec_start "$user" "$pw")"
      echo "Environment=NODE_ENV=production PORT=$port"
      echo "User=$user"
      echo "Group=$user"
      echo "UMask=0002"
      if [[ -n "$mem" ]]; then
        echo "MemoryMax=$mem"
        echo "CPUQuota=$cpu"
      fi
      echo "Restart=on-failure"
      echo "StandardOutput=journal"
      echo "StandardError=journal"
      echo "SyslogIdentifier=c9-$user"
      echo
      echo "[Install]"
      echo "WantedBy=multi-user.target"
    } >"$unit"
  )
}

# systemd_restart_and_show <user>
systemd_restart_and_show() {
  local service="c9-$1.service"
  systemctl daemon-reload
  systemctl enable "$service"
  systemctl restart "$service"
  sleep 10
  systemctl status --no-pager "$service"
  systemctl is-active --quiet "$service"
}

# create_systemd_workspace <plain|limit> <args...>
create_systemd_workspace() {
  local kind="$1" spec="u:p:o:" title="workspace"
  shift
  if [[ "$kind" == limit ]]; then
    spec="u:p:o:l:c:"
    title="workspace with memory limit"
  fi
  parse_args "$spec" "$@" || return 2

  ask u "Username: "
  ask p "Password: " secret
  ask o "Port: "
  if [[ "$kind" == limit ]]; then
    ask l "Memory Limit (e.g., 1024m): "
    ask c "CPU Limit (e.g., 10%): "
  fi

  local user pw port mem="" cpu=""
  user="$(opt u)"
  pw="$(opt p)"
  port="$(opt o)"
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  check "Invalid password (empty, or contains a single quote/newline)" valid_password "$pw" || return 2
  check "Invalid port" valid_port "$port" || return 2
  if [[ "$kind" == limit ]]; then
    mem="$(opt l)"
    cpu="$(opt c)"
    check "Invalid memory limit (e.g., 1024m, 2G, 50%)" valid_systemd_mem "$mem" || return 2
    check "Invalid CPU limit (e.g., 10% or 1.0)" valid_systemd_cpu "$cpu" || return 2
    # systemd only understands upper-case size suffixes and a percent CPU quota
    mem="$(upper "$mem")"
    if [[ "$cpu" != *% ]]; then
      cpu="$(awk -v c="$cpu" 'BEGIN { printf "%d%%", c * 100 }')"
    fi
  fi
  if id -u "$user" >/dev/null 2>&1; then
    err "User '$user' already exists."
    return 1
  fi

  echo
  echo "Creating $title:"
  echo "Username: $user"
  echo "Password: ********"
  echo "Port: $port"
  if [[ "$kind" == limit ]]; then
    echo "Memory Limit: $mem"
    echo "CPU Limit: $cpu"
  fi

  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y -o DPkg::Lock::Timeout=300
  apt-get upgrade -y -o DPkg::Lock::Timeout=300 -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold

  adduser --disabled-password --gecos "" "$user" || return 1
  echo "$user:$pw" | chpasswd || return 1
  mkdir -p "/home/$user/my-projects" "/home/$user/c9sdk" || return 1
  chown -R "$user:$user" "/home/$user"
  chmod 700 "/home/$user"
  sudo -H -u "$user" git clone --depth=5 https://github.com/c9/core.git "/home/$user/c9sdk" || return 1
  sudo -H -u "$user" bash -c 'cd "$1" && scripts/install-sdk.sh' _ "/home/$user/c9sdk" || return 1

  write_systemd_unit "$user" "$pw" "$port" "$mem" "$cpu" || return 1
  systemd_restart_and_show "$user"
}

createnewsystemd() { create_systemd_workspace plain "$@"; }
createnewsystemdlimit() { create_systemd_workspace limit "$@"; }

# systemd_user_arg <args...>: parse -u (prompt when missing), validate; sets SYSTEMD_USER
systemd_user_arg() {
  parse_args "u:" "$@" || return 2
  ask u "Input User: "
  SYSTEMD_USER="$(opt u)"
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$SYSTEMD_USER" || return 2
}

stopsystemd() {
  systemd_user_arg "$@" || return
  sleep 3
  systemctl stop "c9-$SYSTEMD_USER.service"
}

startsystemd() {
  systemd_user_arg "$@" || return
  sleep 3
  systemctl start "c9-$SYSTEMD_USER.service"
}

deletesystemd() {
  systemd_user_arg "$@" || return
  sleep 3
  systemctl stop "c9-$SYSTEMD_USER.service"
  sleep 3
  pkill -u "$SYSTEMD_USER" || true
  sleep 3
  userdel "$SYSTEMD_USER"
  # OPTIONAL: Remove user directory
  # rm -rf /home/$SYSTEMD_USER
}

statussystemd() {
  systemd_user_arg "$@" || return
  systemctl status "c9-$SYSTEMD_USER.service"
}

restartsystemd() {
  systemd_user_arg "$@" || return
  systemd_restart_and_show "$SYSTEMD_USER"
}

changepasswordsystemd() {
  parse_args "u:p:o:" "$@" || return 2
  ask u "Input User: "
  ask p "Input New Password: " secret
  ask o "Input New Port: "

  local user pw port unit tmp line
  user="$(opt u)"
  pw="$(opt p)"
  port="$(opt o)"
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  check "Invalid password (empty, or contains a single quote/newline)" valid_password "$pw" || return 2
  check "Invalid port" valid_port "$port" || return 2
  unit="$(systemd_unit_path "$user")"
  [[ -f "$unit" ]] || {
    err "Workspace unit $unit not found."
    return 1
  }

  # Rewrite only the ExecStart and PORT lines; sed would mangle passwords
  # containing '/', '&' or '\'.
  tmp="$(mktemp "$unit.XXXXXX")" || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
    ExecStart=*) line="ExecStart=$(systemd_exec_start "$user" "$pw")" ;;
    Environment=*PORT=*) line="Environment=NODE_ENV=production PORT=$port" ;;
    esac
    printf '%s\n' "$line"
  done <"$unit" >"$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$unit" || return 1

  systemctl daemon-reload
  systemctl restart "c9-$user.service"
  sleep 10
  systemctl status --no-pager "c9-$user.service"
  systemctl is-active --quiet "c9-$user.service"
}

schedulesystemd() {
  local user when
  read -rp "Input User: " user || true
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  echo "$TIME_FORMATS"
  read -rp "Time: " when || true
  at "$when" <<END
sleep 3
systemctl stop "c9-$user.service"
# OPTIONAL: Remove user directory
# sleep 3
# pkill -u "$user"
# sleep 3
# userdel "$user"
END
}

scheduledatq() {
  atq
}

convertsystemd() {
  local user
  read -rp "Input User: " user || true
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  echo "Input user password"
  passwd "$user" || return 1
  echo "Warning, C9 will be restart!"
  usermod -aG sudo "$user" || return 1
  systemd_restart_and_show "$user"
}

# ============================ DOCKER WORKSPACES ============================ #

# create_docker_workspace <plain|limit> <args...>
create_docker_workspace() {
  local kind="$1" spec="u:p:o:i:q:" title="docker container"
  shift
  if [[ "$kind" == limit ]]; then
    spec="u:p:o:l:c:i:q:"
    title="docker container with memory limit"
  fi
  parse_args "$spec" "$@" || return 2

  ask u "Username: "
  ask p "Password: " secret
  ask o "Port: "
  if [[ "$kind" == limit ]]; then
    ask l "Memory Limit (e.g., 1024m): "
    ask c "CPU Limit (e.g., 1.0 for 1 core): "
  fi
  choose_image i
  ask q "Storage Limit (ext4 quota, e.g., 10G; 0=unlimited, blank=skip): "

  local user pw port mem="" cpu="" image storage
  user="$(opt u)"
  pw="$(opt p)"
  port="$(opt o)"
  image="$(opt i)"
  storage="$(opt q)"
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  check "Invalid password (empty, or contains a single quote/newline)" valid_password "$pw" || return 2
  check "Invalid port" valid_port "$port" || return 2
  check "Invalid image '$image'" valid_image "$image" || return 2
  if [[ "$kind" == limit ]]; then
    mem="$(opt l)"
    cpu="$(opt c)"
    check "Invalid memory limit (e.g., 1024m, 2g)" valid_docker_mem "$mem" || return 2
    check "Invalid CPU limit (e.g., 0.5 or 1.0)" valid_docker_cpu "$cpu" || return 2
  fi

  local base="$DOCKER_DIR_PLAIN"
  [[ "$kind" == limit ]] && base="$DOCKER_DIR_LIMIT"
  if [[ ! -d "$base" ]]; then
    err "$base not found. Run the c9cli installer first."
    return 1
  fi

  echo
  echo "Creating $title:"
  echo "Username: $user"
  echo "Password: ********"
  echo "Port: $port"
  if [[ "$kind" == limit ]]; then
    echo "Memory Limit: $mem"
    echo "CPU Limit: $cpu"
  fi
  echo "Image: $image"
  [[ -n "$storage" ]] && echo "Storage Limit: $storage"

  local rc=0
  with_base_lock "$base" docker_up_locked "$base" 0 "$user" "$pw" "$port" "$image" "$mem" "$cpu" || rc=$?

  if [[ -d "$base/$user" ]]; then
    if [[ -n "$storage" ]]; then
      set_user_storage_quota_for_path "$user" "$storage" "$base/$user" || true
    fi
  elif ((rc == 0)); then
    echo -e "\033[33mWARN! Workspace directory not found: $base/$user\033[0m"
  fi
  return "$rc"
}

createnewdocker() { create_docker_workspace plain "$@"; }
createnewdockermemlimit() { create_docker_workspace limit "$@"; }

# docker_user_type_args <args...>: parse -u/-t, prompt, validate.
# Sets DOCKER_USER, DOCKER_BASE, DOCKER_TYPE.
docker_user_type_args() {
  parse_args "u:t:" "$@" || return 2
  ask u "Input User: "
  DOCKER_USER="$(opt u)"
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$DOCKER_USER" || return 2
  select_docker_base "$(opt t)"
}

# docker_lifecycle <compose-subcommand> <args...>
docker_lifecycle() {
  local action="$1"
  shift
  docker_user_type_args "$@" || return
  docker_compose "$DOCKER_BASE" "$DOCKER_USER" "$action"
}

stopdocker() { docker_lifecycle stop "$@"; }
startdocker() { docker_lifecycle start "$@"; }
deletedocker() { docker_lifecycle down "$@"; }

listdocker() {
  docker ps
}

statusdocker() {
  docker stats
}

changepassworddocker() {
  parse_args "u:p:t:o:l:c:i:" "$@" || return 2
  ask u "Input Username: "
  ask p "Input New Password: " secret
  ask o "Input Port: "

  local user pw port mem="" cpu="" image=""
  user="$(opt u)"
  pw="$(opt p)"
  port="$(opt o)"
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  check "Invalid password (empty, or contains a single quote/newline)" valid_password "$pw" || return 2
  check "Invalid port" valid_port "$port" || return 2
  select_docker_base "$(opt t)" || return
  if [[ "$DOCKER_TYPE" == 2 ]]; then
    ask l "Memory Limit (e.g., 1024m): "
    ask c "CPU Limit (e.g., 1.0 for 1 core): "
    mem="$(opt l)"
    cpu="$(opt c)"
    check "Invalid memory limit (e.g., 1024m, 2g)" valid_docker_mem "$mem" || return 2
    check "Invalid CPU limit (e.g., 0.5 or 1.0)" valid_docker_cpu "$cpu" || return 2
  fi

  if [[ ! -d "$DOCKER_BASE/$user" ]]; then
    err "User $user does not exist or workspace directory not found"
    return 1
  fi

  # Keep the image of the running container unless a new one was requested.
  if [[ -z "$(opt i)" ]]; then
    image="$(docker inspect --format '{{.Config.Image}}' "$(container_name "$user")" 2>/dev/null)" || image=""
  fi
  choose_image i "$image"
  image="$(opt i)"
  check "Invalid image '$image'" valid_image "$image" || return 2

  with_base_lock "$DOCKER_BASE" docker_up_locked "$DOCKER_BASE" 1 "$user" "$pw" "$port" "$image" "$mem" "$cpu" || return
  echo "Password, port and .env updated for user $user"
  echo "Docker container recreated for user $user"
}

# reset_docker_locked <base> <user>: recreate from the shared .env, which must
# belong to <user> (it holds the settings of whoever was created/updated last).
reset_docker_locked() {
  local base="$1" user="$2"
  if ! grep -qx "NAMA_PELANGGAN=$user" "$base/.env" 2>/dev/null; then
    err "$base/.env does not hold the settings of '$user' (it belongs to another workspace)."
    err "Use 'c9cli manage docker password -u $user ...' to recreate it with explicit settings."
    return 1
  fi
  docker_compose "$base" "$user" down || return 1
  docker_compose "$base" "$user" up -d
}

resetdocker() {
  docker_user_type_args "$@" || return
  with_base_lock "$DOCKER_BASE" reset_docker_locked "$DOCKER_BASE" "$DOCKER_USER"
}

scheduledocker() {
  local user answer when base
  read -rp "Input User: " user || true
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  echo "Is this workspace using docker or dockermemlimit?"
  read -rp "Answer Y if you are using docker and answer N if you are using dockermemlimit [y/N] " answer || true
  case "$answer" in
  [yY][eE][sS] | [yY]) base="$DOCKER_DIR_PLAIN" ;;
  *) base="$DOCKER_DIR_LIMIT" ;;
  esac
  echo "$TIME_FORMATS"
  read -rp "Time: " when || true
  at "$when" <<END
cd $base
docker compose -p "$(project_name "$user")" stop
# OPTIONAL: Remove user setup
# docker compose -p "$(project_name "$user")" down
END
}

configuredocker() {
  local user action container
  read -rp "Input User: " user || true
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  container="$(container_name "$user")"
  echo "1. Stop"
  echo "2. Start"
  echo "3. Restart"
  read -rp "Choose: " action || true
  case "$action" in
  1) docker container stop "$container" ;;
  2) docker container start "$container" ;;
  *) docker container restart "$container" ;;
  esac
}

restartdocker() {
  parse_args "u:" "$@" || return 2
  local containers
  containers="$(docker ps --format "{{.Names}}")"
  echo "Container lists:"
  echo "$containers" | sed 's/^c9-//'

  ask u "Input User: "
  local user container
  user="$(opt u)"
  check "Invalid username (letters, digits, '_' and '-' only)" valid_user "$user" || return 2
  container="$(container_name "$user")"

  if ! echo "$containers" | grep -Fxq "$container"; then
    err "Container name '$container' invalid. Make sure the name is correct."
    return 1
  fi
  if docker restart "$container"; then
    echo "Container '$container' restarted successfully."
  else
    err "Container restart '$container' failed."
    return 1
  fi
}

restartdockerall() {
  local -a running=()
  local id
  while IFS= read -r id; do
    [[ -n "$id" ]] && running+=("$id")
  done < <(docker ps -q)
  if ((${#running[@]} == 0)); then
    echo "No running containers to restart."
    return 0
  fi
  docker restart "${running[@]}"
}

# ============================ BACKUP ============================ #

# emit_backup_script <rclone-remote-path> <log-file> <lock-file> <additional-paths...>
# Prints the cron script. The values chosen by the user are embedded with
# printf %q so they can never be interpreted as shell code.
emit_backup_script() {
  local remote="$1" log_file="$2" lock_file="$3" path
  shift 3
  printf '#!/bin/bash\n'
  printf 'remote=%q\n' "$remote"
  printf 'log_file=%q\n' "$log_file"
  printf 'lock_file=%q\n' "$lock_file"
  printf 'additional_paths=(\n'
  for path in "$@"; do
    printf '  %q\n' "$path"
  done
  printf ')\n'
  cat <<'BACKUP_BODY'
date=$(date +%Y%m%d)

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

exec 9>"$lock_file"
if ! flock -n 9; then
    log_message "Another backup run is still active, exiting"
    exit 0
fi

resolve_additional_path() {
    local configured_path="$1"
    configured_path="${configured_path//\{folder\}/$folder}"
    configured_path="${configured_path//\{user\}/$user}"
    printf '%s' "$configured_path"
}

should_skip_additional_folder() {
    local candidate="$1"
    local configured_path=""
    local additional_pattern=""

    for configured_path in "${additional_paths[@]}"; do
        additional_pattern="${configured_path//\{folder\}/*}"
        additional_pattern="${additional_pattern//\{user\}/*}"
        # shellcheck disable=SC2053 # the pattern is an intentional glob
        if [[ "$candidate" == $additional_pattern || "$candidate" == ${additional_pattern}/ ]]; then
            return 0
        fi
    done

    return 1
}

verify_backup() {
    local folder="$1"
    local user="$2"
    local new_file="$folder-$user-$date.zip"
    local retry_count=3
    local retry_delay=5
    local i

    for ((i=1; i<=retry_count; i++)); do
        log_message "Verification attempt $i of $retry_count for $new_file"

        if rclone lsf "$remote/$new_file" &>/dev/null; then
            log_message "File $new_file verified in remote"
            return 0
        fi

        log_message "WARNING: $new_file not found in remote"
        if [ "$i" -lt "$retry_count" ]; then
            log_message "Retrying in $retry_delay seconds..."
            sleep "$retry_delay"
        fi
    done

    return 1
}

cleanup_old_backup() {
    local folder="$1"
    local user="$2"
    local backup_files backup_count files_to_delete file

    log_message "Checking for old backup files for $folder-$user"

    backup_files=$(rclone lsf "$remote" --include "$folder-$user-*.zip" | sort -r)
    backup_count=$(echo "$backup_files" | wc -l)

    if [ "$backup_count" -gt 2 ]; then
        log_message "Keeping last 2 backups for $folder-$user"
        files_to_delete=$(echo "$backup_files" | tail -n +3)

        while IFS= read -r file; do
            if [ -n "$file" ]; then
                log_message "Deleting old backup: $file"
                rclone delete "$remote/$file" >> "$log_file" 2>&1
            fi
        done <<< "$files_to_delete"
    else
        log_message "Less than or equal to 2 backups found for $folder-$user, no cleanup needed"
    fi
}

log_message "Starting backup process"

cd /home || exit 1
mkdir -p /home/backup

for folder in c9users c9usersmemlimit; do
    if [ -d "$folder" ]; then
        log_message "Processing $folder"
        cd "$folder" || continue
        for user_folder in */; do
            if [ ! -d "$user_folder" ]; then
                continue
            fi
            if should_skip_additional_folder "$user_folder"; then
                log_message "Skipping additional folder $user_folder"
                continue
            fi

            user=${user_folder%/}
            log_message "Backing up $user from $folder"

            zip_sources=("$user_folder")
            for additional_path in "${additional_paths[@]}"; do
                resolved_path="$(resolve_additional_path "$additional_path")"
                if [ -e "$resolved_path" ]; then
                    zip_sources+=("$resolved_path")
                    log_message "Including additional path $resolved_path"
                else
                    log_message "WARNING: Additional path $resolved_path not found"
                fi
            done

            if ! zip -r "/home/backup/$folder-$user-$date.zip" "${zip_sources[@]}" -x "*/.c9/*" "$user_folder.c9/*" "*/node_modules/*" >> "$log_file" 2>&1; then
                log_message "ERROR: Failed to create zip for $user in $folder"
                rm -f "/home/backup/$folder-$user-$date.zip"
                continue
            fi

            log_message "Uploading backup for $folder-$user"
            max_retries=3
            retry_count=0
            upload_success=false

            while [ "$retry_count" -lt "$max_retries" ]; do
                log_message "Upload attempt $((retry_count + 1)) of $max_retries"

                if rclone copy "/home/backup/$folder-$user-$date.zip" "$remote/" >> "$log_file" 2>&1; then
                    if verify_backup "$folder" "$user"; then
                        upload_success=true
                        break
                    fi
                fi

                retry_count=$((retry_count + 1))
                if [ "$retry_count" -lt "$max_retries" ]; then
                    log_message "Retry in 30 seconds..."
                    sleep 30
                fi
            done

            if [ "$upload_success" = true ]; then
                log_message "Backup successfully uploaded for $folder-$user"
                cleanup_old_backup "$folder" "$user"
            else
                log_message "ERROR: Backup failed for $folder-$user after $max_retries attempts"
            fi

            log_message "Removing local backup file for $folder-$user"
            rm -f "/home/backup/$folder-$user-$date.zip"
        done
        cd /home || exit 1
    else
        log_message "Folder $folder not found, skipping"
    fi
done

log_message "Removing local backup directory"
rm -rf /home/backup >> "$log_file" 2>&1

log_message "Backup process completed"
BACKUP_BODY
}

# add_backup_cron <script> <log-file> <hour>: replaces any previous entry of <script>
add_backup_cron() {
  local script="$1" log_file="$2" hour="$3" current rc=0
  current="$(crontab -l 2>&1)" || rc=$?
  if ((rc != 0)); then
    if [[ "$current" != *"no crontab"* ]]; then
      err "Cannot read the current crontab: $current"
      return 1
    fi
    current=""
  fi
  {
    [[ -n "$current" ]] && { printf '%s\n' "$current" | grep -vF "$script" || true; }
    echo "0 $hour * * * $script >> $log_file 2>&1"
  } | crontab -
}

backups() {
  parse_args "n:h:f:s:a:" "$@" || return 2

  echo "Scheduled Backup - WARNING: This script currently only supports backup for c9users and c9usersmemlimit docker containers"
  echo "Make sure you have set up an rclone config file using command: rclone config"
  echo "If your storage is bucket type, then name the rclone config name same as your bucket name"
  echo ""
  ask n "If all has been set up correctly, then input your rclone remote name: "
  ask h "Enter the time for backup (hour 0-23): "
  ask f "Define the backup folder name on the cloud: "
  if [[ -z "$(opt s)" ]]; then
    echo ""
    echo "Choose the backup service provider"
    echo "1. Google Drive"
    echo "2. Storj"
    echo "3. Backblaze B2"
    echo "4. pCloud"
    echo "5. Jottacloud"
    ask s "Choose: "
  fi

  local name hour cloud_folder script log_file
  name="$(opt n)"
  hour="$(opt h)"
  cloud_folder="$(opt f)"
  check "Invalid rclone remote name" valid_remote_name "$name" || return 2
  check "Invalid backup hour (0-23)" valid_backup_hour "$hour" || return 2
  case "$(opt s)" in
  1 | 2 | 3 | 4 | 5) ;;
  *)
    err "Invalid option"
    return 2
    ;;
  esac
  if [[ "$cloud_folder" == *$'\n'* || "$cloud_folder" == *$'\r'* ]]; then
    err "Invalid backup folder name"
    return 2
  fi

  script="$BACKUP_SCRIPT_DIR/backup-$name.sh"
  log_file="$BACKUP_SCRIPT_DIR/backup-$name.log"
  emit_backup_script "$name:$cloud_folder" "$log_file" "/var/lock/backup-$name.lock" "${OPT_A[@]}" >"$script" || return 1
  chmod +x "$script"
  echo ""
  echo "Backup command created"

  add_backup_cron "$script" "$log_file" "$hour" || return 1

  echo ""
  echo "Cron job created"
  echo ""
  echo "Make sure it's included in your cron list:"
  crontab -l
  echo "Backup rule successfully added"
}

# ============================ MISC ============================ #

portlist() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -i -P -n | grep LISTEN
  else
    ss -tlnp
  fi
}

# ============================ QUICKCREATE ============================ #

public_ip() {
  curl -fsS --max-time 10 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

# PIDs of the quick-created C9 only. Matching on "node.*server.js" alone would
# also hit the Cloud9 processes of every workspace container and systemd
# workspace, so the working directory has to be the quick SDK directory.
quick_pids() {
  local pid
  for pid in $(pgrep -f 'node.*server\.js'); do
    [[ "$(readlink "/proc/$pid/cwd" 2>/dev/null)" == "$QUICK_SDK_DIR" ]] && echo "$pid"
  done
}

stop_quick_c9() {
  local pids
  pids="$(quick_pids)"
  [[ -n "$pids" ]] || return 1
  # shellcheck disable=SC2086 # one PID per word
  kill $pids
}

start_quick_c9() {
  local ip
  ip="$(public_ip)"
  echo "Starting C9 Server..."
  (
    cd "$QUICK_SDK_DIR" || exit 1
    setsid nohup node server.js \
      -l "$ip:$QUICK_PORT" \
      -p "$QUICK_PORT" \
      --listen 0.0.0.0 \
      -w "$QUICK_WORKSPACE" >>"$QUICK_LOG" 2>&1 &
  ) || return 1
  echo "Server log: $QUICK_LOG"
}

quick_access_hint() {
  echo "Access Cloud9 IDE at: http://$(public_ip):$QUICK_PORT"
}

quickcreatec9() {
  echo "Starting Quick C9 Installation..."
  echo "Server IP: $(public_ip)"

  mkdir -p "$QUICK_WORKSPACE"

  echo "Downloading C9 SDK..."
  if [[ ! -d "$QUICK_SDK_DIR" ]]; then
    git clone https://github.com/c9/core.git "$QUICK_SDK_DIR" || return 1
  fi

  (cd "$QUICK_SDK_DIR" && ./scripts/install-sdk.sh) || {
    err "C9 SDK install failed"
    return 1
  }

  start_quick_c9 || return 1
  echo "Quick C9 Installation Complete!"
  quick_access_hint
}

restartquickcreate() {
  echo "Restarting C9 Server..."
  [[ -d "$QUICK_SDK_DIR" ]] || {
    err "C9 SDK directory not found!"
    return 1
  }

  echo "Stopping existing C9 server..."
  stop_quick_c9 || true
  sleep 3

  start_quick_c9 || return 1
  echo "C9 Server Successfully Restarted!"
  quick_access_hint
}

fixquickcreate() {
  echo "Fixing C9..."
  [[ -d "$QUICK_SDK_DIR" ]] || {
    err "C9 SDK directory not found!"
    return 1
  }

  echo "Stopping existing C9 server..."
  stop_quick_c9 || true
  sleep 3

  (
    cd "$QUICK_SDK_DIR" || exit 1
    git reset --hard &&
      git fetch origin && git reset origin/HEAD --hard &&
      ./scripts/install-sdk.sh
  ) || {
    err "C9 fix failed"
    return 1
  }

  start_quick_c9 || return 1
  echo "C9 Fix Complete!"
  quick_access_hint
}

statusquickcreate() {
  echo "Checking C9 Server Status..."
  local pids
  pids="$(quick_pids)"
  if [[ -z "$pids" ]]; then
    echo "C9 Server is NOT RUNNING"
    return 0
  fi
  echo "C9 Server is RUNNING"
  quick_access_hint
  echo -e "\nProcess details:"
  ps -o pid,args -p "$(echo "$pids" | tr '\n' ',' | sed 's/,$//')"
}

stopquickcreate() {
  echo "Stopping C9 Server..."
  if stop_quick_c9; then
    echo "C9 Server Stopped Successfully"
  else
    echo "C9 Server is not running"
  fi
}

# ============================ MENU ============================ #

not_found() {
  err "Command not found, type c9cli help for help"
  return 1
}

dispatch_create() {
  case "${1:-}" in
  systemd) createnewsystemd "${@:2}" ;;
  systemdlimit) createnewsystemdlimit "${@:2}" ;;
  docker) createnewdocker "${@:2}" ;;
  dockerlimit) createnewdockermemlimit "${@:2}" ;;
  *) not_found ;;
  esac
}

dispatch_manage_systemd() {
  case "${1:-}" in
  stop) stopsystemd "${@:2}" ;;
  start) startsystemd "${@:2}" ;;
  delete) deletesystemd "${@:2}" ;;
  status) statussystemd "${@:2}" ;;
  restart) restartsystemd "${@:2}" ;;
  password) changepasswordsystemd "${@:2}" ;;
  schedule) schedulesystemd ;;
  scheduled) scheduledatq ;;
  convert) convertsystemd ;;
  *) not_found ;;
  esac
}

dispatch_manage_docker() {
  case "${1:-}" in
  stop) stopdocker "${@:2}" ;;
  start) startdocker "${@:2}" ;;
  delete) deletedocker "${@:2}" ;;
  list) listdocker ;;
  status) statusdocker ;;
  password) changepassworddocker "${@:2}" ;;
  schedule) scheduledocker ;;
  scheduled) scheduledatq ;;
  configure) configuredocker ;;
  restart) restartdocker "${@:2}" ;;
  restartall) restartdockerall ;;
  reset) resetdocker "${@:2}" ;;
  *) not_found ;;
  esac
}

dispatch_quickcreate() {
  case "${1:-}" in
  restart) restartquickcreate ;;
  fix) fixquickcreate ;;
  status) statusquickcreate ;;
  stop) stopquickcreate ;;
  "") quickcreatec9 ;;
  *) not_found ;;
  esac
}

main() {
  # help/version work for everyone; everything else manages the system
  case "${1:-}" in
  help | -h | --help | "")
    helps
    return 0
    ;;
  version | -v | --version)
    versions
    return 0
    ;;
  esac

  if [[ "$(id -u)" != "0" ]]; then
    err "c9cli must be run as root!"
    return 1
  fi

  [[ "$1" == update ]] || check_update_if_due

  case "$1" in
  quickcreate) dispatch_quickcreate "${@:2}" ;;
  create) dispatch_create "${@:2}" ;;
  manage)
    case "${2:-}" in
    systemd) dispatch_manage_systemd "${@:3}" ;;
    docker) dispatch_manage_docker "${@:3}" ;;
    *) not_found ;;
    esac
    ;;
  port) portlist ;;
  update) updates ;;
  backup) backups "${@:2}" ;;
  *) not_found ;;
  esac
}

# Run only when executed, so the functions can be sourced for testing.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
