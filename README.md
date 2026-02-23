<div align="center">

# 🚀 AfterBoot

### **Your Linux Setup, Automated.**

A single script to transform a fresh Ubuntu/Debian install into a fully configured workstation — with a beautiful interactive UI powered by [Gum](https://github.com/charmbracelet/gum).

[![Shell Script](https://img.shields.io/badge/Shell-Bash-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian%20%7C%20Mint-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

---

**One command. That's all it takes.**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/satya77-lang/afterboot/main/install.sh)
```

</div>

---

## ✨ Features

| Category | What's Included |
|:---|:---|
| 🔄 **System Update** | Full system update & upgrade on first run |
| 🐚 **ZSH Shell Setup** | ZSH + Oh My Zsh + autosuggestions + syntax highlighting |
| 🚀 **Starship Prompt** | Beautiful, fast, cross-shell prompt — auto-configured |
| 🌐 **Browsers** | Chrome, Brave, Chromium, Zen Browser (Flatpak/AppImage/Tarball) |
| 🎬 **Multimedia** | VLC, MPV, GNOME Videos, Blender, GIMP, OBS, Audacity |
| 🎨 **Interactive UI** | Spinners, confirmations & styled outputs via [Gum](https://github.com/charmbracelet/gum) |

---

## 📦 Quick Start

### One-Liner Install (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/satya77-lang/afterboot/main/install.sh)
```

### Manual Install

```bash
git clone https://github.com/satya77-lang/afterboot.git
cd afterboot
chmod +x install.sh
./install.sh
```

---

## 🛠️ What Happens When You Run It?

The script walks you through each step interactively — you choose what to install:

```
1. 🔄 System Update & Upgrade
2. 🐚 ZSH Setup (with Oh My Zsh, plugins & Starship prompt)
3. 🌐 Browser Selection (pick one or more)
4. 🎬 Multimedia Tools (pick one or more)
```

> **No surprises** — every major installation step asks for your confirmation first.

---

## 🌐 Supported Browsers

| Browser | Install Method |
|:---|:---|
| Google Chrome | `.deb` package |
| Brave | Official APT repository |
| Chromium | System package manager |
| Zen Browser | Flatpak / AppImage / Official Script |

---

## 🐚 ZSH Setup Includes

| Component | Description |
|:---|:---|
| [Oh My Zsh](https://ohmyz.sh/) | ZSH framework with community plugins |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like command suggestions |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Syntax highlighting in your terminal |
| [Starship](https://starship.rs/) | Minimal, blazing-fast prompt |
| **Pre-configured plugins** | `git`, `sudo`, `history`, `encode64`, `copypath` |

---

## 💻 Supported Distros

- ✅ Ubuntu (22.04+)
- ✅ Linux Mint
- ✅ Debian (11+)
- ✅ Pop!_OS
- ✅ Any Debian/Ubuntu-based distribution

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

1. Fork the repository
2. Create your branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">

**Made with ❤️ for the Linux community**

⭐ Star this repo if you found it useful!

</div>
