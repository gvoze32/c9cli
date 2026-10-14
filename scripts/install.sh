#!/bin/bash
# c9cli all-in installer: dependencies, Docker, rclone, workspace host users
# and the docker-compose templates used by `c9cli create docker[limit]`.
# Idempotent: safe to run again on a host that is already provisioned.
#
# Everything lives in main(), called on the last line, so that a command
# reading stdin can never swallow the rest of the script when it is piped
# into bash.

CURL_SECURE=(curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --connect-timeout 15)
APT_OPTS=(-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o DPkg::Lock::Timeout=300)

PYTHON2_VERSION="2.7.18"
PYTHON2_SHA256="da3080e3b488f648a3d7a4560ddee895284c3380b11d6de75edb986526b9a814"

WORK_DIR=""

log() {
  echo "$*"
}

warn() {
  echo "WARN: $*" >&2
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

cleanup() {
  [ -n "$WORK_DIR" ] && rm -rf "$WORK_DIR"
}

# apt_get <args...>: non-interactive apt-get that waits for the dpkg lock
apt_get() {
  DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" "$@" </dev/null
}

load_os_release() {
  OS_ID="unknown"
  OS_VERSION=""
  OS_CODENAME=""
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    eval "$(. /etc/os-release && printf 'OS_ID=%q OS_VERSION=%q OS_CODENAME=%q' \
      "${ID:-unknown}" "${VERSION_ID:-}" "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"
  fi
}

check_supported_os() {
  case "$OS_ID:$OS_VERSION" in
  ubuntu:18.04 | ubuntu:20.04 | ubuntu:22.04 | ubuntu:24.04 | ubuntu:26.04) ;;
  ubuntu:* | debian:*) warn "$OS_ID $OS_VERSION is untested; continuing." ;;
  *) die "Unsupported OS '$OS_ID $OS_VERSION' (Ubuntu or Debian required)." ;;
  esac
}

# Stop needrestart from prompting during apt runs (Ubuntu 22.04+ only).
configure_needrestart() {
  local conf=/etc/needrestart/needrestart.conf
  [ -f "$conf" ] || return 0
  sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" "$conf"
  sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" "$conf"
}

update_packages() {
  apt_get update || die "apt-get update failed"
  apt_get upgrade || die "apt-get upgrade failed"
  apt_get update || die "apt-get update failed"
}

# NodeSource nodejs bundles npm and conflicts with the distro npm package;
# a conflict aborts the whole apt transaction, so only add what is missing.
install_base_deps() {
  local packages=(curl git build-essential python3 zip unzip)
  command -v node >/dev/null 2>&1 || packages+=(nodejs)
  command -v npm >/dev/null 2>&1 || packages+=(npm)
  apt_get install "${packages[@]}" || die "Failed to install dependencies: ${packages[*]}"
}

# quota is required for storage limits; pythonpy was dropped from newer
# releases, so it must not fail the whole transaction.
install_second_deps() {
  apt_get install apt-transport-https ca-certificates gnupg-agent software-properties-common quota ||
    die "Failed to install apt-transport-https/ca-certificates/gnupg-agent/software-properties-common/quota"
  apt_get install pythonpy || warn "pythonpy is not available; skipping."
}

install_atd() {
  log "Installing at package and enabling atd.service..."
  apt_get install at || die "Failed to install the at package."
  systemctl enable --now atd.service || die "Failed to enable atd.service."
}

install_python2_from_source() {
  local src_dir=/usr/src
  local tarball="Python-${PYTHON2_VERSION}.tgz"
  local source_path="${src_dir}/Python-${PYTHON2_VERSION}"

  apt_get install build-essential libncurses-dev libssl-dev libsqlite3-dev tk-dev \
    libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev || return 1

  mkdir -p "$src_dir"
  rm -rf "$source_path"
  if [ -f "${src_dir}/${tarball}" ] && ! echo "${PYTHON2_SHA256}  ${src_dir}/${tarball}" | sha256sum -c --quiet -; then
    rm -f "${src_dir}/${tarball}"
  fi
  if [ ! -f "${src_dir}/${tarball}" ]; then
    "${CURL_SECURE[@]}" -o "${src_dir}/${tarball}" \
      "https://www.python.org/ftp/python/${PYTHON2_VERSION}/${tarball}" || return 1
    if ! echo "${PYTHON2_SHA256}  ${src_dir}/${tarball}" | sha256sum -c --quiet -; then
      warn "Checksum mismatch for ${tarball}."
      rm -f "${src_dir}/${tarball}"
      return 1
    fi
  fi

  tar -xzf "${src_dir}/${tarball}" -C "$src_dir" || return 1
  (
    cd "$source_path" &&
      ./configure --enable-optimizations &&
      make -j"$(nproc)" &&
      make altinstall
  ) || return 1

  if [ -x /usr/local/bin/python2.7 ]; then
    ln -sf /usr/local/bin/python2.7 /usr/local/bin/python2
  fi

  command -v python2 >/dev/null 2>&1
}

ensure_python2() {
  if command -v python2 >/dev/null 2>&1; then
    log "Python2 already installed."
    return 0
  fi
  # python2 is gone from Ubuntu 24.04+; apt fails fast there and the source
  # build takes over.
  if apt_get install python2 || apt_get install python2-minimal; then
    return 0
  fi
  log "Python2 is not available via apt; building it from source."
  if install_python2_from_source; then
    return 0
  fi
  warn "Failed to install Python2; skipping Python2 dependencies."
  return 1
}

pip_install() {
  local python="$1"
  shift
  local flags=()
  # PEP 668 distros need --break-system-packages, older pip does not know it.
  if "$python" -m pip install --help 2>/dev/null | grep -q -- --break-system-packages; then
    flags+=(--break-system-packages --ignore-installed)
  fi
  "$python" -m pip install "${flags[@]}" "$@"
}

pip_dep() {
  local pip_packages=(requests selenium colorama bs4 wget pyfiglet)
  apt_get install python3-pip || die "Failed to install python3-pip"
  pip_install python3 "${pip_packages[@]}" || warn "Failed to install Python3 packages."

  if ensure_python2; then
    local get_pip="$WORK_DIR/get-pip.py"
    if "${CURL_SECURE[@]}" -o "$get_pip" https://bootstrap.pypa.io/pip/2.7/get-pip.py &&
      python2 "$get_pip"; then
      python2 -m pip install "${pip_packages[@]}" || warn "Failed to install Python2 packages."
    else
      warn "Failed to install pip for Python2."
    fi
  fi
}

install_rclone() {
  if command -v rclone >/dev/null 2>&1; then
    log "rclone already installed."
    return 0
  fi
  "${CURL_SECURE[@]}" -o "$WORK_DIR/rclone-install.sh" https://rclone.org/install.sh &&
    bash "$WORK_DIR/rclone-install.sh" </dev/null
  command -v rclone >/dev/null 2>&1 || die "rclone installation failed"
}

install_docker_app() {
  local distro="$OS_ID" codename="$OS_CODENAME"
  [ -n "$codename" ] || die "Cannot determine the distribution codename for the Docker repository."

  install -m 0755 -d /etc/apt/keyrings
  "${CURL_SECURE[@]}" -o /etc/apt/keyrings/docker.asc "https://download.docker.com/linux/${distro}/gpg" ||
    die "Failed to download the Docker repository key"
  chmod a+r /etc/apt/keyrings/docker.asc

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${distro} ${codename} stable" \
    >/etc/apt/sources.list.d/docker.list

  apt_get update || die "apt-get update failed after adding the Docker repository"
  apt_get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin ||
    die "Failed to install Docker"
}

create_host_user() {
  local user="$1"
  if id -u "$user" >/dev/null 2>&1; then
    log "User $user already exists."
    return 0
  fi
  adduser --disabled-password --gecos "" "$user" || die "Failed to create user $user"
}

# write_compose_file <host-user> <limited:0|1>
# Both templates are kept verbatim; the limited one adds the resource limits.
write_compose_file() {
  local user="$1" limited="$2" dir="/home/$1"
  {
    cat <<EOF
services:
  cloud9:
    image: \${DOCKER_IMAGE}
    container_name: c9-\${NAMA_PELANGGAN}
    environment:
      - TZ=Asia/Jakarta
      - USERNAME=\${NAMA_PELANGGAN}
      - PASSWORD=\${PASSWORD_PELANGGAN}
    volumes:
      - ${dir}/\${NAMA_PELANGGAN}:/workspace
    ports:
      - \${PORT}:8000
    restart: always
EOF
    if [ "$limited" = 1 ]; then
      cat <<'EOF'
    deploy:
      resources:
        limits:
          memory: ${MEMORY}
          cpus: ${CPU_LIMIT}
EOF
    fi
  } >"$dir/docker-compose.yml" || die "Failed to write $dir/docker-compose.yml"
}

# An existing .env holds the settings of the last workspace; never truncate it.
ensure_env_file() {
  local file="/home/$1/.env"
  [ -f "$file" ] || install -m 600 /dev/null "$file"
}

setup_workspace_hosts() {
  create_host_user c9users
  write_compose_file c9users 0
  create_host_user c9usersmemlimit
  write_compose_file c9usersmemlimit 1
  ensure_env_file c9users
  ensure_env_file c9usersmemlimit
}

# Adds default-address-pools without clobbering an operator's daemon.json and
# restarts Docker (which bounces every container) only when it changed.
configure_docker_address_pools() {
  local cfg=/etc/docker/daemon.json status=0
  log "Setting custom Docker default address pools"
  mkdir -p /etc/docker
  python3 - "$cfg" <<'PY' || status=$?
import json, os, sys

path = sys.argv[1]
data = {}
if os.path.exists(path) and os.path.getsize(path):
    with open(path) as handle:
        data = json.load(handle)
if "default-address-pools" in data:
    sys.exit(3)
data["default-address-pools"] = [{"base": "10.10.0.0/16", "size": 24}]
tmp = path + ".tmp"
with open(tmp, "w") as handle:
    json.dump(data, handle, indent=4)
    handle.write("\n")
os.replace(tmp, path)
PY
  case "$status" in
  0)
    systemctl restart docker || die "Failed to restart Docker"
    log "Docker default address pools set to 10.10.0.0/16 with size 24"
    ;;
  3) log "Docker default address pools already configured; leaving $cfg untouched." ;;
  *) warn "Could not update $cfg (invalid JSON?); default address pools not set." ;;
  esac
}

verify_install() {
  local failed=0 item
  for item in docker rclone; do
    command -v "$item" >/dev/null 2>&1 || {
      warn "$item is missing after installation."
      failed=1
    }
  done
  docker compose version >/dev/null 2>&1 || {
    warn "docker compose plugin is missing after installation."
    failed=1
  }
  for item in c9users c9usersmemlimit; do
    id -u "$item" >/dev/null 2>&1 || {
      warn "user $item is missing after installation."
      failed=1
    }
  done
  [ "$failed" = 0 ] || die "Installation incomplete."
}

main() {
  [ "$(id -u)" = 0 ] || die "The installer must be run as root."

  load_os_release
  echo "Checking OS version.."
  echo "OS is $OS_ID $OS_VERSION"
  check_supported_os
  echo "Installing dependencies.."

  WORK_DIR="$(mktemp -d)" || die "Cannot create a temporary directory"
  trap cleanup EXIT

  export DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 NEEDRESTART_MODE=l
  configure_needrestart

  update_packages
  install_base_deps
  pip_dep
  install_atd
  install_second_deps
  install_rclone
  install_docker_app
  setup_workspace_hosts
  configure_docker_address_pools
  verify_install
  log "Installation finished."
}

main "$@"
