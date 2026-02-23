#!/usr/bin/env bash

set -euo pipefail

printf "Hello, %s\n" "$USER"

# shellcheck disable=SC1091
# shellcheck source=/etc/os-release
source /etc/os-release

if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "${ID_LIKE:-}" == *"debian"* || "${ID_LIKE:-}" == *"ubuntu"* ]]; then
  # shellcheck disable=SC2153
  printf "Supported: %s %s\n" "$NAME" "$VERSION"
else
  printf "This script is made for ubuntu and debian based distro\n"
  exit 1
fi

if [[ "$(whoami)" = "root" ]]; then
  SUDO=""
else
  SUDO="sudo"
  sudo -v
  while true; do
    sudo -n true
    sleep 300
  done & # & = run this loop in the BACKGROUND
  trap 'kill $! 2>/dev/null' EXIT
fi

# Add Charm repo(required for gum)

function customGum {
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | $SUDO tee /etc/apt/sources.list.d/charm.list
  $SUDO apt update && $SUDO apt install -y gum
}

# Check if the command exists
dependencies=("gum")

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

#Install the Required dependencies

function updateSystem {
  gum style --foreground 212 --bold "⬆ Updating the system..."
  $SUDO apt update -y
  $SUDO apt upgrade -y

}

updateSystem # calling the function

# ZSH Setup

# ZSH setup
printf "%s %s\n" "$(gum style --foreground 212 --bold '🔍 Detected Shell:')" "$(gum style --foreground 118 --bold "$SHELL")"

function zsh_setup {

  apt_install "ZSH SHELL" "zsh"

  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  gum spin --spinner meter --title 'Installing zsh-autosuggestions' -- git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  gum spin --spinner meter --title 'Installing zsh-syntax-highlighting' -- git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

  # Configure plugins in .zshrc
  sed -i 's/^plugins=(git)$/plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
  gum style --foreground 118 --bold "✅ Plugins configured in .zshrc"

  # Installing the starship
  gum spin --spinner meter --title "Installing Starship" -- bash -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'

  # Add starship init to .zshrc
  # shellcheck disable=SC2016
  echo 'eval "$(starship init zsh)"' >>"$HOME/.zshrc"
  gum style --foreground 118 --bold "✅ Starship configured in .zshrc"

  # Give clear instructions to the users to change the shell in the ubuntu terminal settings
  if gum confirm "Would you like to change your default shell to ZSH now?"; then
    chsh -s "$(which zsh)"
    gum style --foreground 118 --bold "✅ Default shell changed to ZSH (takes effect on next login)"
  else
    gum style --foreground 212 --bold "⚠ Shell not changed. You can do it later with: chsh -s \$(which zsh)"
  fi

  gum style \
    --border rounded \
    --border-foreground 99 \
    --padding "1 2" \
    --foreground 229 \
    --bold \
    "🖥  Terminal-Specific Instructions" \
    "" \
    "If chsh doesn't affect your terminal, configure it manually:" \
    "" \
    "GNOME Terminal:" \
    "  ➜ Preferences → Profiles → Command tab" \
    "  ➜ Check 'Run a custom command instead of my shell'" \
    "  ➜ Enter: /usr/bin/zsh" \
    "" \
    "Ptyxis (GNOME 46+):" \
    "  ➜ Uses your login shell automatically" \
    "  ➜ Just run: chsh -s \$(which zsh)" \
    "" \
    "Konsole (KDE):" \
    "  ➜ Settings → Edit Current Profile → General tab" \
    "  ➜ Change Command to: /usr/bin/zsh" \
    "" \
    "Then close and reopen your terminal 🚀"

}

if gum confirm "Do you want to Switch to ZSH Shell"; then
  zsh_setup
else
  gum style --foreground 212 --bold "⚠ Skipping ZSH setup."
fi


install_chrome() {
  if command -v google-chrome &>/dev/null; then
    printf "Chrome is already installed.\n"
    return
  fi

  local deb_file="/tmp/google-chrome.deb"

  gum spin --spinner points --title 'Downloading Chrome' -- \
    wget -qO "$deb_file" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

  gum spin --spinner meter --title 'Installing Chrome' -- \
    $SUDO apt install -y "$deb_file"

  # Clean up
  rm -f "$deb_file"

  printf "Chrome installed successfully.\n"
}

install_brave() {
  if command -v brave-browser &>/dev/null; then
    printf "Brave is already installed.\n"
    return
  fi

  # Download the Brave keyring
  gum spin --spinner points --title 'Adding Brave repository' -- \
    $SUDO curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

  # Add the Brave sources list
  $SUDO curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

  # Update apt to recognize the new repo
  gum spin --spinner points --title 'Downloading Brave' -- $SUDO apt update

  # Install Brave
  gum spin --spinner meter --title 'Installing Brave' -- $SUDO apt install -y brave-browser

  printf "Brave installed successfully.\n"
}

install_zen() {
  if command -v zen-browser &>/dev/null || (command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "io.github.zen_browser.zen"); then
    printf "Zen Browser is already installed.\n"
    return
  fi

  # Let the user pick the install method
  local method
  method=$(
    gum choose --header "How would you like to install Zen Browser?" \
      "Flatpak (Recommended)" \
      "AppImage (no auto updates)" \
      "Official Script (Tarball installation)"
  )

  case "$method" in
    "Flatpak"*)
      # Ensure flatpak is available
      if ! command -v flatpak &>/dev/null; then
        gum spin --spinner meter --title 'Installing Flatpak' -- $SUDO apt install -y flatpak
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      fi
      gum spin --spinner meter --title 'Installing Zen Browser via Flatpak' -- \
        flatpak install -y flathub app.zen_browser.zen
      ;;
    "AppImage"*)
      gum spin --spinner meter --title 'Installing Zen Browser AppImage' -- \
        bash <(curl -s https://updates.zen-browser.app/appimage.sh)
      ;;
    "Official Script"*)
      gum spin --spinner meter --title 'Installing Zen Browser' -- \
        bash <(curl -fsSL https://github.com/zen-browser/updates-server/raw/refs/heads/main/install.sh)
      ;;
  esac

  printf "Zen Browser installed successfully.\n"

}

function Browsers {
  local selected

  selected=$(gum choose --no-limit --header "Select the Browsers for installation" 'Chrome' 'Brave' 'Chromium' 'Zen Browser')
  gum style --border double --border-foreground 212 --padding "2 4" "You selected:" "$selected"
  # Loop through each selected browser, line by line
  while IFS= read -r browser; do
    case "$browser" in
      "Chrome")
        install_chrome
        ;;
      "Brave")
        install_brave
        ;;
      "Chromium")
        if command -v chromium &>/dev/null; then
          printf "Chromium is already installed.\n"
        else
          gum spin --spinner points --title 'Installing Chromium' -- \
            $SUDO apt install -y chromium
        fi
        ;;
      "Zen Browser")
        install_zen
        ;;
    esac
  done <<<"$selected"

}

apt_install() {
  local name="$1"        # display name
  local pkg="$2"         # package name for apt
  local cmd="${3:-$pkg}" #if no 2nd argument , use the 1st

  if command -v "$cmd" &>/dev/null; then
    gum style --foreground 10 "$name" "is already installed"
  else
    gum spin --spinner points --title "Installing $name..." -- $SUDO apt install -y "$pkg"
    gum style --foreground 10 "$name" "installed successfully"
  fi
}

Browsers # Calls the Browsers installation function

install_blender() {
  if command -v blender &>/dev/null; then
    gum style --foreground 10 "Blender is already installed"
    return
  fi

  # Give user the choices
  local method
  method=$(
    gum choose --header "How would you like to install Blender?" \
      "System Package Manager(Recommended)" \
      "Snap (For Ubuntu Distro)" \
      "Flatpak"
  )
  case $method in
    "System Package"*)
      gum spin --spinner meter --title "Installing Blender via apt" -- $SUDO apt install -y blender
      ;;
    "Snap"*)
      gum spin --spinner meter --title "Installing Blender via snap" -- $SUDO snap install blender --classic
      ;;
    "Flatpak"*)
      gum spin --spinner meter --title "Installing Blender via Flatpak" -- flatpak install --user -y flathub org.blender.Blender
      ;;
  esac
  printf "Blender installed successfully..\n"
}

function MultimediaTools {
  local selected
  selected=$(gum choose --header 'Select the MultimediaTools for installation' --no-limit 'VLC' 'Gnome Video Player' 'MPV Player' 'Blender' 'GIMP' 'OBS' 'Audacity')

  while IFS= read -r media; do
    case "$media" in
      "VLC")
        apt_install VLC vlc
        ;;
      "Gnome Video Player")
        apt_install "Gnome Video Player" "showtime"
        ;;
      "mpv Player")
        apt_install "MPV Player" "mpv"
        ;;
      "Blender")
        install_blender
        ;;
    esac
  done <<<"$selected"
}
