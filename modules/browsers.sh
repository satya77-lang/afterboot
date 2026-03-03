#!/usr/bin/env bash

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
  wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | $SUDO tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null

  # 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3
  #gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'

  # Next, add the Mozilla APT repository to your sources.list
  cat <<EOF | $SUDO tee /etc/apt/sources.list.d/mozilla.sources
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
' | $SUDO tee /etc/apt/preferences.d/mozilla

  # Update your package list
  $SUDO apt update

  # Install Firefox
  $SUDO apt install -y firefox

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
