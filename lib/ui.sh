#!/usr/bin/env bash

function customGum {
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | $SUDO tee /etc/apt/sources.list.d/charm.list
  $SUDO apt update && $SUDO apt install -y gum
}

# Check if the command exists
dependencies=("gum")

# Add Charm repo(required for gum)
for dep in "${dependencies[@]}"; do
  if command -v "$dep" &>/dev/null; then
    # Already installed skip
    printf "%s is already installed.\n" "$dep"
  elif apt-cache show "$dep" &>/dev/null; then
    # Not Installed, but availabe in apt
    printf "Installing %s via apt...\n" "$dep"
    $SUDO apt install -y "$dep"
  else
    # Not Installed , not in apt - needs custom install
    printf "Installing %s via custom method...\n" "$dep"
    customGum
  fi
done
