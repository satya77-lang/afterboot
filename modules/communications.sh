#!/usr/bin/env bash

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
      "Telegram")
        flatpak_install "Telegram" "org.telegram.desktop"
        ;;
      "Signal")
        flatpak_install "Signal" "org.signal.Signal"
        ;;
      "Slack")
        flatpak_install "Slack" "com.slack.Slack"
        ;;
      "Thunderbird")
        apt_install "Thunderbird" "thunderbird"
        ;;
      "Zoom")
        deb_install "Zoom" "zoom" "https://zoom.us/client/latest/zoom_amd64.deb"
        ;;
    esac
  done 3<<<"$selected"

}

Communications
