#!/usr/bin/env bash

set -euo pipefail
trap 'printf "\n❌ Script failed at line %d (exit code %d)\n" "$LINENO" "$?" >&2' ERR

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

updateSystem # calling the function'

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

#Installing the dependencies
gum spin --spinner dot --title "Installing Dependencies" -- $SUDO apt install -y git

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

    if ! command -v flatpak &>/dev/null; then
      gum spin --spinner meter --title 'Installing Flatpak' -- $SUDO apt install -y flatpak
    fi
    $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    FLATHUB_READY=true
  fi

  gum spin --spinner meter --title "Installing $name via Flatpak" -- \
    $SUDO flatpak install -y flathub "$package"
  gum style --foreground 10 "$name installed via Flatpak"
}

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

function deb_install {
  local name="$1"
  local cmd="$2"
  local link="$3"

  if command -v "$cmd" &>/dev/null; then
    printf "%s is already installed.\n" "$cmd"
    return
  fi

  local deb_file="/tmp/$cmd.deb"

  gum spin --spinner points --title 'Downloading Chrome' -- \
    wget -qO "$deb_file" "$link"

  gum spin --spinner meter --title 'Installing Chrome' -- \
    $SUDO apt install -y "$deb_file"

  # Clean up
  rm -f "$deb_file"

  printf "%s installed successfully.\n" "$name"
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
      flatpak_install "Zen Browser" "app.zen_browser.zen"
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

install_firefox() {
  #Create a directory to store APT repository keys if it doesn't exist
  $SUDO install -d -m 0755 /etc/apt/keyrings

  # Import the Mozilla APT repository signing key
  wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null

  # 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3
  #gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'

  # Next, add the Mozilla APT repository to your sources.list
  cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.sources
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF

  # Configure APT to prioritize packages from the Mozilla repository
  echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

  # Update your package list
  $SUDO apt update

  # Install Firefox
  $SUDO apt install firefox

}

function Browsers {
  local selected

  selected=$(gum choose --no-limit --header "Select the Browsers for installation" 'Firefox' 'Chrome' 'Brave' 'Chromium' 'Zen Browser')
  gum style --border double --border-foreground 212 --padding "2 4" "You selected:" "$selected"
  # Loop through each selected browser, line by line
  while IFS= read -r browser <&3; do # read uses door 3 (custom pipe)
    case "$browser" in
      "Firefox")
        install_firefox
        ;;
      "Chrome")
        install_chrome # # gum choose uses door 0 (stdin) — no conflict!
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
  done 3<<<"$selected" # $selected is fed through door 3

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
      "System Package Manager(Recommended/Maybe not latest)" \
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
      gum spin --spinner meter --title "Installing Blender via Flatpak" -- $SUDO flatpak install -y flathub org.blender.Blender
      ;;
  esac
  printf "Blender installed successfully..\n"
}

install_gimp() {
  if command -v gimp &>/dev/null; then
    gum style --foreground 10 "GIMP is already installed"
    return
  fi

  #Give user the choices
  local method
  method=$(
    gum choose --header "How would you like to install GIMP" \
      "System Package Manager(Recommended)" \
      "Flatpak"
  )
  case $method in
    "System Package"*)
      apt_install "GIMP" "gimp"

      ;;
    "Flatpak")
      flatpak_install "GIMP" "org.gimp.GIMP"
      ;;
  esac
  printf "GIMP installed successfully...\n"
}

cmd_check() {
  local name=$1
  local cmd=$2

  if command -v "$cmd" &>/dev/null; then
    gum style --foreground 10 "$name is already installed"
    return
  fi

}

cmd_flatpak() {
  local name=$1
  local flatPackage=$2
  if command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "$flatPackage"; then
    gum style --foreground 10 "$name is already installed via flatpak"
    return
  fi

}

install_obs() {
  local method
  method=$(
    gum choose --header "How would you like to install the OBS Studio" \
      'System Package(Maybe not be latest)' \
      "PPA (For Ubuntu based Distro - latest version)" \
      "Flatpak (Works on all distro)"
  )

  case "$method" in
    "PPA"*)
      cmd_check "OBS Studio" "obs-studio"
      if command -v add-apt-repository &>/dev/null; then
        gum spin --spinner dot --title 'Adding the OBS to System Package Manager' -- $SUDO add-apt-repository -y ppa:obsproject/obs-studio
        if $SUDO apt update 2>&1 | grep -q "does not have a Release file"; then
          gum style --foreground 212 --bold "⚠️ PPA doesn't support $VERSION_CODENAME yet. Installing via apt instead..."
          # Remove the PPA REPO
          $SUDO add-apt-repository -y --remove ppa:obsproject/obs-studio
          gum spin --spinner moon --title 'Updating the Packages' -- $SUDO apt update
          gum spin --spinner meter --title 'Installing OBS Studio' -- $SUDO apt install -y obs-studio
        else
          gum spin --spinner meter --title 'Installing OBS Studio via PPA' -- $SUDO apt install -y obs-studio
        fi
      else
        gum style --foreground 212 --bold "⚠️ PPA is not supported on this distro($NAME). Installing via apt instead..."
        gum spin --spinner meter --title 'Installing OBS Studio via apt' -- $SUDO apt install -y obs-studio
      fi
      ;;
    "System Package"*)
      gum spin --spinner meter --title 'Installing OBS Studio via apt' -- $SUDO apt install -y obs-studio
      ;;
    "Flatpak"*)
      cmd_flatpak "OBS Studio" "com.obsproject.Studio"
      flatpak_install "OBS Studio" "com.obsproject.Studio"
      ;;
  esac

  gum style --foreground 10 "OBS Studio installed successfully"

}

install_audacity() {
  local method
  method=$(
    gum choose --header 'How would you like to install Audacity?' \
      "System Package Manager(stable) - Maybe not latest" \
      "Flatpak (Community Maintained)" \
      "Snap" \
      "AppImage (From audacity website)"
  )

  case "$method" in
    "System Package"*)
      apt_install "Audacity" "audacity"
      ;;
    "Flatpak"*)
      flatpak_install "Audacity" "org.audacityteam.Audacity"
      ;;
    "Snap")
      gum spin --spinner meter --title 'Installing Audacity via snap' -- $SUDO snap install audacity
      ;;
    "AppImage"*)
      local appImageURL=https://github.com/audacity/audacity/releases/download/Audacity-3.7.7/audacity-linux-3.7.7-x64-22.04.AppImage

      if [[ -z "$appImageURL" ]]; then
        gum style --foreground 196 --bold "❌ Could not find the AppImage URL . Try another method"
        return
      fi

      local appImage_dir="$HOME/Applications"
      mkdir -p "$appImage_dir"

      gum spin --spinner points --title 'Downloading Audacity AppImage' -- wget -qO "$appImage_dir/Audacity.AppImage" "$appImageURL"

      chmod +x "$appImage_dir/Audacity.AppImage"

      if gum confirm 'Create a desktop entry for easy access?'; then
        if gum confirm 'Install for all users? (Yes = system-wide, No = only you)'; then
          # System-wide desktop entry
          $SUDO tee /usr/share/applications/audacity.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Audacity
Exec=$appImage_dir/Audacity.AppImage
Icon=audacity
Type=Application
Categories=AudioVideo;Audio;
Comment=Audio editor and recorder
EOF
          gum style --foreground 118 --bold "✅ Desktop entry created for all users"
        else
          # User-only desktop entry
          mkdir -p "$HOME/.local/share/applications"
          tee "$HOME/.local/share/applications/audacity.desktop" >/dev/null <<EOF
[Desktop Entry]
Name=Audacity
Exec=$appImage_dir/Audacity.AppImage
Icon=audacity
Type=Application
Categories=AudioVideo;Audio;
Comment=Audio editor and recorder
EOF
          gum style --foreground 118 --bold "✅ Desktop entry created for your user"
        fi
      fi

      gum style --foreground 118 --bold "✅ AppImage saved to $appImage_dir/Audacity.AppImage"
      ;;
  esac

  gum style --foreground 10 "Audacity installed successfully"
}

function MultimediaTools {
  local selected
  selected=$(gum choose --header 'Select the MultimediaTools for installation' --no-limit 'VLC' 'Gnome Video Player' 'MPV Player' 'Blender' 'GIMP' 'OBS' 'Audacity')
  gum style --border double --border-foreground 212 --padding "2 4" "You selected:" "$selected"

  while IFS= read -r media <&3; do
    case "$media" in
      "VLC")
        apt_install VLC vlc
        ;;
      "Gnome Video Player")
        if apt-cache show showtime &>/dev/null; then
          apt_install "Gnome Video Player" "showtime"
        elif apt-cache show totem &>/dev/null; then
          apt_install "Gnome Video Player" "totem"
        else
          flatpak_install "Gnome Video Player" "org.gnome.Showtime"
        fi
        ;;
      "mpv Player")
        apt_install "MPV Player" "mpv"
        ;;
      "Blender")
        install_blender
        ;;
      "GIMP")
        install_gimp
        ;;
      "OBS")
        install_obs
        ;;
      "Audacity")
        install_audacity
        ;;
    esac
  done 3<<<"$selected"
  # The <<< operator is called a here string
  #  It feeds a string directly into a command's stdin (standard input).
  #   # Instead of:
  # echo "hello" | grep "h"

  # # You can write:
  # grep "h" <<< "hello"
}

MultimediaTools

## Communications

function Communications {
  local selected
  selected=$(gum choose --header 'Select the Communications for installation' --no-limit 'Discord' 'Telegram' 'Signal' 'Slack' 'Thunderbird' 'Zoom')
  gum style --border double --border-foreground 212 --padding "2 4" "You selected:" "$selected"

  while IFS= read -r talk <&3; do
    case "$talk" in
      "Discord") 
      deb_install "Discord" "discord" "https://discord.com/api/download?platform=linux&format=deb"
      ;;
    esac
  done <<<3"$selected"

}

Communications


if gum confirm --affirmative "Reboot Now ⚡" --negative "Later" --default=false --prompt.foreground 212 --selected.foreground 118 "Restart to apply changes"; then
  $SUDO reboot
else
  exit 0
fi
