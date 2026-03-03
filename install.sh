#!/usr/bin/env bash

set -euo pipefail
trap 'printf "\n❌ Script failed at line %d (exit code %d)\n" "$LINENO" "$?" >&2' ERR

printf "Hello, %s\n" "$USER"

function updateSystem {
  gum style --foreground 212 --bold "⬆ Updating the system..."
  $SUDO apt update -y
  $SUDO apt upgrade -y

}


# Get the directory where THIS script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helper libraries

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/checks.sh"
source "$SCRIPT_DIR/lib/utils.sh"

check_os
check_root
install_dependencies
updateSystem

# Run modules

source "$SCRIPT_DIR/modules/zsh_setup.sh"
source "$SCRIPT_DIR/modules/browsers.sh"
source "$SCRIPT_DIR/modules/multimedia.sh"
source "$SCRIPT_DIR/modules/communications.sh"

if gum confirm --affirmative "Reboot Now ⚡" --negative "Later" --default=false --prompt.foreground 212 --selected.foreground 118 "Restart to apply changes"; then
  $SUDO reboot
else
  exit 0
fi
