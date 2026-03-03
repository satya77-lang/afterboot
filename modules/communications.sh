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
      "Slack")
        apt_install "Slack" "slack"
        ;;
    esac
  done 3<<<"$selected"

}

Communications
