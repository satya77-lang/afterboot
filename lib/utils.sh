#!/usr/bin/env bash

apt_install() {
  local name="$1"        # display name
  local pkg="$2"         # package name for apt
  local cmd="${3:-$pkg}" #if no 2nd argument , use the 1st

  if command -v "$cmd" &>/dev/null; then
    gum style --foreground 10 "$name" "is already installed"
  else
    gum spin --spinner points --title "Installing $name... via apt" -- $SUDO apt install -y "$pkg"
    gum style --foreground 10 "$name" "installed successfully"
  fi
}

function flatpak_install {
  local name="$1"
  local package="$2"

  # Skip if already installed via Flatpak
  if command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "$package"; then
    gum style --foreground 10 "$name is already installed via Flatpak"
    return
  fi

  gum style --foreground 212 "$name not available via apt, installing via Flatpak..."

  # Setup flatpak + flathub only once
  if [[ "${FLATHUB_READY:-}" != "true" ]]; then
    # shellcheck disable=SC2086
    if ! command -v flatpak &>/dev/null; then
      gum spin --spinner meter --title 'Installing Flatpak' -- $SUDO apt install -y flatpak
    fi
    $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    FLATHUB_READY=true
  fi
  # shellcheck disable=SC2086
  gum spin --spinner meter --title "Installing $name via Flatpak" -- \
    $SUDO flatpak install -y flathub $package
  gum style --foreground 10 "$name installed via Flatpak"
}

function deb_install {
  local name="$1"
  local cmd="$2"
  local link="$3"

  if command -v "$cmd" &>/dev/null; then
    printf "%s is already installed.\n" "$cmd"
    return
  fi

  local deb_file="/tmp/$cmd.deb"

  gum spin --spinner points --title "Downloading $name" -- \
    wget -qO "$deb_file" "$link"

  gum spin --spinner meter --title "Installing $name" -- \
    $SUDO apt install -y "$deb_file"

  # Clean up
  rm -f "$deb_file"

  printf "%s installed successfully.\n" "$name"
}
