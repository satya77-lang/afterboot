#!/usr/bin/env bash

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
      cmd_check "OBS Studio" "obs-studio" && return ## if available then stops the function
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
