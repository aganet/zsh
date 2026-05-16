# zsh config

A single-file, cross-platform `.zshrc` built on Oh My Zsh + Powerlevel10k, with sensible defaults for fzf, fd, eza, bat, delta, zoxide, direnv, and fzf-tab.

Auto-detects the host OS (macOS / Fedora / Arch / generic Linux) and only loads plugins / paths that exist on the machine, so the same file works on every box.

---

## What this config gives you

**Prompt & shell**
- Powerlevel10k prompt with instant-prompt
- Oh My Zsh as the plugin loader
- `share_history` + 1M-line history at `$XDG_DATA_HOME/zsh/.zhistory`
- Quality-of-life `setopt`s: `correct`, `autocd`, `extendedglob`, `nocaseglob`, `numericglobsort`, `nobeep`, etc.

**Plugins (OMZ)**
- `git`, `fzf`, `fzf-tab`, `dotenv`, `vscode`, `cp`, `colorize`, `encode64`
- `zsh-autosuggestions`, `fast-syntax-highlighting`
- Conditional on tool presence: `docker`, `docker-compose`, `kubectl`, `minikube`, `bundler`, `rake`, `rbenv`, `ruby`
- Conditional on OS: `macos`, `brew`

**Modern CLI replacements** (config auto-detects and uses them if installed)
- `eza` for `ls` / `ll` / `la` / `tree` (icons + git status)
- `bat` for `cat` and as `MANPAGER` (syntax highlighting)
- `fd` powering `fzf` (faster, respects `.gitignore`)
- `delta` for `git diff` (side-by-side, syntax-highlighted) — configured globally in `~/.gitconfig`

**Productivity tools** (config wires them in if present)
- `zoxide` — smarter `cd` (`z`, `zi`)
- `direnv` — per-directory env via `.envrc`
- `fzf-tab` — tab completion → fzf fuzzy menu with bat/eza previews
- `nvm` — Node version manager

---

## Prerequisites

Required everywhere:

- `zsh` (5.8+)
- `git`
- A **Nerd Font** (for Powerlevel10k icons) — recommended: [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads)

---

## Install

### 1. Clone this repo into `$XDG_CONFIG_HOME/zsh`

```bash
# fresh setup
git clone <your-repo-url> ~/.config/zsh
```

If you're putting this folder *inside* an existing dotfiles repo, just symlink or copy `.zshrc` into `~/.config/zsh/`.

### 2. Tell zsh to use `~/.config/zsh` as `$ZDOTDIR`

Put a tiny `~/.zshenv` in your home directory:

```sh
export ZDOTDIR="$HOME/.config/zsh"
```

That's the only file that needs to live in `$HOME`. Everything else lives under `~/.config/zsh/`.

### 3. Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
```

`--keep-zshrc` prevents it from overwriting your config.

### 4. Install Powerlevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

### 5. Install required custom OMZ plugins

```bash
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"

git clone --depth=1 https://github.com/Aloxaf/fzf-tab \
  "$ZSH_CUSTOM/plugins/fzf-tab"
```

### 6. Install the CLI tools

Pick your platform — every tool is optional, but the config really shines with the full set.

#### Fedora

```bash
sudo dnf install -y zsh git fzf fd-find bat eza ripgrep zoxide \
  git-delta gh lazygit tldr btop direnv neovim tmux

# lazygit may need a copr:
sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit
```

#### Arch / Manjaro

```bash
sudo pacman -S --needed zsh git fzf fd bat eza ripgrep zoxide \
  git-delta github-cli lazygit tealdeer btop direnv neovim tmux
```

#### macOS (Homebrew)

```bash
brew install zsh fzf fd bat eza ripgrep zoxide \
  git-delta gh lazygit tldr btop direnv neovim tmux

# install fzf key-bindings & completion
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
```

#### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y zsh git fzf fd-find bat ripgrep zoxide \
  tldr direnv neovim tmux

# bat is installed as `batcat`; eza, delta, gh, lazygit, btop need extra steps:
mkdir -p ~/.local/bin && ln -sf "$(command -v batcat)" ~/.local/bin/bat

# eza
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  | sudo tee /etc/apt/sources.list.d/gierens.list
sudo apt update && sudo apt install -y eza

# gh
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update && sudo apt install -y gh

# delta, lazygit, btop — grab latest .deb / binary from their GitHub releases.
```

### 7. Set zsh as your login shell

```bash
chsh -s "$(command -v zsh)"
```

Log out / log back in.

### 8. Configure git to use `delta` (one-time)

```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global delta.syntax-theme "Dracula"
git config --global merge.conflictstyle "zdiff3"
git config --global diff.colorMoved "default"
```

### 9. First-run Powerlevel10k wizard (optional)

If `~/.config/zsh/.p10k.zsh` isn't present, p10k will start its config wizard the first time you open a shell. Otherwise just run:

```bash
p10k configure
```

---

## Cheat sheet

| Action                | Keys / cmd                                |
|-----------------------|-------------------------------------------|
| Fuzzy file search     | `Ctrl-T`                                  |
| Fuzzy `cd`            | `Alt-C`                                   |
| Fuzzy history search  | `Ctrl-R`                                  |
| Tab completion menu   | `<TAB>` (fzf-powered, with previews)      |
| Jump to dir           | `z <part-of-name>`                        |
| Pick a dir from list  | `zi`                                      |
| Pretty `git diff`     | `git diff` (uses delta)                   |
| Git TUI               | `lazygit`                                 |
| GitHub from terminal  | `gh pr list`, `gh repo clone`, etc.       |
| Cheat-sheet for cmd   | `tldr <cmd>` (e.g. `tldr tar`)            |
| System monitor        | `btop`                                    |
| Per-dir env vars      | put in `.envrc`, then `direnv allow`      |

---

## What's NOT in this config (by design)

- **No `atuin`** — uses zsh-native history file. `Ctrl-R` falls through to the `fzf` plugin's incremental search.
- **No modular `aliasrc` / `optionrc` / `pluginrc`** — everything is one `.zshrc` for easy auditing.
- **No `zsh-vi-mode`** — emacs-style line editing only.
- **No `starship`** — Powerlevel10k handles the prompt.

---

## File layout

```
~/.config/zsh/
├── .zshrc          # the whole config
├── .p10k.zsh       # Powerlevel10k theme settings (created by `p10k configure`)
├── README.md
└── .zcompdump-*    # zsh completion cache (regenerated; safe to delete)

~/.zshenv           # one line: export ZDOTDIR="$HOME/.config/zsh"
```

---

## Troubleshooting

**Prompt looks like garbage / boxes** — install a Nerd Font and set your terminal to use it.

**`fzf-tab` doesn't activate** — make sure it's listed in the `plugins=(...)` array *before* `zsh-autosuggestions` and `fast-syntax-highlighting`.

**`compinit: insecure directories`** — run `compaudit | xargs chmod g-w,o-w`.

**Slow startup** — run `zsh -xv 2>&1 | head -50` to see what's loading; the usual suspect is NVM. Use [lazy-nvm](https://github.com/lukechilds/zsh-nvm) if it bothers you.

**Per-OS plugin not loading** — the script auto-detects via `/etc/fedora-release`, `/etc/arch-release`, or `uname -s`. Check `echo $CURRENT_OS` matches what you expect.
