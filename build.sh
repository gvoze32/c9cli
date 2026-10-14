#!/bin/bash
# c9cli bootstrap: runs the all-in installer, then installs the c9cli binary.
#   curl -fsSL https://jayanode.com/api/mirror/c9cli/build?raw=true | sudo bash

BASE_URL="https://jayanode.com/api/mirror/c9cli"
INSTALL_PATH="/usr/local/bin/c9cli"
tmp_dir="" # global: the EXIT trap runs after main() has returned

banner() {
  cat <<'EOF'

=================================================
             ____ ___   ____ _     ___               
            / ___/ _ \ / ___| |   |_ _|              
           | |  | (_) | |   | |    | |               
           | |___\__, | |___| |___ | |               
  ___ _   _ \____|_/_/ \____|_____|___|  _____ ____  
 |_ _| \ | / ___|_   _|/ \  | |   | |   | ____|  _ \ 
  | ||  \| \___ \ | | / _ \ | |   | |   |  _| | |_) |
  | || |\  |___) || |/ ___ \| |___| |___| |___|  _ < 
 |___|_| \_|____/ |_/_/   \_\_____|_____|_____|_| \_\
                                                     
==================================================

EOF
}

fail() {
  echo -e "\e[31m$1\e[0m" >&2
  exit 1
}

# fetch <url> <destination>
fetch() {
  curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --connect-timeout 15 "$1" -o "$2"
}

main() {
  local sudo_cmd=""
  if [ "$(id -u)" != "0" ]; then
    sudo_cmd="sudo"
  fi

  banner

  tmp_dir="$(mktemp -d)" || fail "Cannot create a temporary directory."
  trap '[ -n "$tmp_dir" ] && rm -rf "$tmp_dir"' EXIT

  fetch "$BASE_URL/install?raw=true" "$tmp_dir/install.sh" || fail "Installation script could not be downloaded."
  $sudo_cmd bash "$tmp_dir/install.sh" || fail "Installation script failed."

  fetch "$BASE_URL/c9cli?raw=true" "$tmp_dir/c9cli" || fail "c9cli installation failed."
  if ! bash -n "$tmp_dir/c9cli" || ! grep -q '^VERSION=' "$tmp_dir/c9cli"; then
    fail "c9cli installation failed (downloaded file is invalid)."
  fi
  $sudo_cmd install -m 0755 "$tmp_dir/c9cli" "$INSTALL_PATH" || fail "c9cli installation failed."

  echo "c9cli installation successful!"
  $sudo_cmd c9cli version
  echo "Type 'sudo c9cli help' to see the available commands."
}

main "$@"
