#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck source=/etc/os-release

check_os() {
  source /etc/os-release

if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "${ID_LIKE:-}" == *"debian"* || "${ID_LIKE:-}" == *"ubuntu"* ]]; then
  # shellcheck disable=SC2153
  printf "Supported: %s %s\n" "$NAME" "$VERSION"
else
  printf "This script is made for ubuntu and debian based distro\n"
  exit 1
fi
}


check_root() {
  if [[ "$(whoami)" = "root" ]]; then
  export SUDO=""
else
  export SUDO="sudo"
  sudo -v
  while true; do
    sudo -n true
    sleep 300
  done & # & = run this loop in the BACKGROUND
fi

}


install_dependencies() {
  #Installing the dependencies
gum spin --spinner dot --title "Installing Dependencies" -- $SUDO apt install -y git
}


