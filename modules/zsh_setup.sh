#!/usr/bin/env bash

# ZSH Setup

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
  gum spin --spinner meter --title "Installing Starship" -- bash -c "curl -sS https://starship.rs/install.sh | $SUDO sh -s -- -y"

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
