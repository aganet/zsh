# zsh config

A cross-platform zsh setup built on Oh My Zsh + Powerlevel10k, with sensible defaults for fzf, fd, eza, bat, delta, zoxide, direnv, and fzf-tab, plus a curated set of DevOps aliases (kubectl / docker / terraform / helm / aws).

Auto-detects the host OS (macOS / Fedora / Arch / generic Linux) and only loads plugins / paths that exist on the machine, so the same files work on every box.

The config is split into four files (inspired by [radleylewis/dotfiles](https://github.com/radleylewis/dotfiles/tree/master/.config/zsh)):

- `.zshrc` — orchestrator: instant-prompt, OS detection, PATH, tool integrations
- `pluginrc` — Oh My Zsh setup + the `plugins=(…)` array (with conditional appends)
- `optionrc` — `setopt` block + history settings
- `aliasrc` — every alias, including the DevOps shortcuts
- `local.zsh` — host-specific tweaks (Arch update alias, work SSH, Nix, etc.)

---

## Quick start (TL;DR)

```bash
# 1. tell zsh where the config lives
echo 'export ZDOTDIR="$HOME/.config/zsh"' > ~/.zshenv

# 2. clone this repo into ~/.config/zsh
mkdir -p ~/.config && cd ~/.config
git clone https://github.com/aganet/zsh.git

# 3. install Oh My Zsh + Powerlevel10k + required plugins (see Install §3-5)
# 4. install the CLI tools for your platform (see Install §6)
# 5. set zsh as your login shell
chsh -s "$(command -v zsh)"
```

Full step-by-step below.

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
- Conditional on tool presence: `docker`, `docker-compose`, `kubectl`, `helm`, `terraform`, `aws`, `azure`, `bundler`, `rake`, `rbenv`, `ruby`
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
mkdir -p ~/.config
cd ~/.config
git clone https://github.com/aganet/zsh.git
```

Because the repo is named `zsh`, it clones straight into `~/.config/zsh/` — no rename needed.

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

The `.zshrc` references three custom plugins: `zsh-autosuggestions`, `fast-syntax-highlighting`, and `fzf-tab`. Use the git-clone method on every OS — it's the [upstream-recommended path for Oh-My-Zsh](https://github.com/zdharma-continuum/fast-syntax-highlighting#oh-my-zsh) and avoids the symlink dance you'd need with distro packages:

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

Everything below uses **Homebrew** — works the same on macOS, Linux (Linuxbrew), and WSL. Every package is referenced somewhere in the config; missing tools degrade gracefully thanks to the `command -v` guards in `aliasrc` and `.zshrc`.

#### TL;DR — install everything

After Homebrew is on the box (see [next subsection](#install-homebrew-one-time-linux-only) for Linux), three commands give you the whole toolchain:

```bash
# 1. Core CLI + DevOps + language runtimes (single brew call)
brew install \
  zsh fzf fd bat eza ripgrep zoxide git-delta gh lazygit tldr btop \
  direnv neovim tmux \
  kubectl kubectx helm terraform k9s awscli stern azure-cli kind opentofu \
  go rbenv ruby-build

# 2. fzf keybindings (one-time, after fzf is installed)
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc

# 3. Python (uv) + Node (NVM) — official installers, not brew
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

Docker is the only thing brew can't fully handle on Linux (no daemon); install via your distro (`sudo pacman -S docker docker-compose` on Arch, or follow [docker.com/engine/install](https://docs.docker.com/engine/install/)). On macOS use `brew install --cask docker` or `brew install colima`.

Skip anything you don't want — every alias in `aliasrc` is `command -v`-gated, so the shell stays clean even with partial installs.

Below: each category broken out separately if you'd rather pick-and-choose.

#### Install Homebrew (one-time, Linux only)

macOS users skip this — brew is the default. On Arch / Ubuntu / Debian / Fedora / WSL:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/main/install.sh)"
```

The installer prints two lines to add brew to your shell — the `.zshrc` in this repo already runs `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` automatically, so you don't need to add anything to `~/.profile`.

#### Core packages (shell + modern CLI)

```bash
brew install zsh fzf fd bat eza ripgrep zoxide \
  git-delta gh lazygit tldr btop direnv neovim tmux

# fzf key-bindings & completion (one-time, after `brew install fzf`)
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
```

#### Installing `uv` (Python)

The official installer from Astral works on every Linux distro, macOS, and WSL — single command, no package manager needed:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

It drops `uv` into `~/.local/bin` (already on `$PATH` via the `.zshrc`).

If you'd rather use your distro's package manager:

```bash
sudo pacman -S uv          # Arch / Manjaro (in `extra`)
sudo dnf install -y uv     # Fedora 40+
brew install uv            # macOS (or via Homebrew on Linux)
```

#### DevOps packages

Powers the aliases in `aliasrc`. Install only the ones you actually use — missing tools just disable their aliases.

```bash
brew install kubectl kubectx helm terraform k9s awscli stern azure-cli kind opentofu
# kubectx provides both `kubectx` and `kubens`

# Docker:
# • macOS — Docker Desktop or colima:
brew install --cask docker         # GUI app
# or:
brew install colima && colima start  # lightweight, no Docker Desktop

# • Linux — install via the distro instead (brew won't manage the daemon):
#   Arch:           sudo pacman -S docker docker-compose
#   Ubuntu/Debian:  https://docs.docker.com/engine/install/ubuntu/
#   Fedora:         https://docs.docker.com/engine/install/fedora/
```

#### Optional — Language runtimes

The `.zshrc` wires in NVM (Node), `go`, and conditionally the OMZ `rbenv` plugin. None are required.

```bash
brew install go rbenv ruby-build      # Go + Ruby version manager

# NVM — brew has it but it's officially recommended to use the curl installer
# so $NVM_DIR ends up at $HOME/.nvm (which is what the .zshrc expects):
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
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

## DevOps aliases

All defined in `aliasrc`. Each block is gated by `command -v <tool>`, so missing tools are silent no-ops. Aliases that the upstream OMZ plugin already provides (e.g. the long list under `kubectl`, `docker-compose`) are **not** redefined here — see the [OMZ plugin docs](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins) for those.

### Kubernetes (`kubectl`)

| Alias    | Expands to                                                            |
|----------|-----------------------------------------------------------------------|
| `k`      | `kubectl` (with completion)                                           |
| `kpf`    | `kubectl port-forward`                                                |
| `kev`    | `kubectl get events --sort-by=.lastTimestamp`                         |
| `kaa`    | `kubectl get all --all-namespaces`                                    |
| `ktop`   | `kubectl top`                                                         |
| `kapi`   | `kubectl api-resources`                                               |
| `kdebug` | ephemeral `nicolaka/netshoot` pod for in-cluster network debugging    |
| `kctx`   | `kubectx` (if installed)                                              |
| `kns`    | `kubens` (if installed)                                               |
| `ks`     | `stern` — multi-pod log tailing (if installed)                        |
| `k9`     | `k9s` — cluster TUI (if installed)                                    |
| `kindc`  | `kind create cluster` — bootstrap a local cluster                     |
| `kindd`  | `kind delete cluster`                                                 |
| `kindg`  | `kind get clusters`                                                   |
| `kindl`  | `kind load docker-image` — push a local image into the cluster        |

### Docker

| Alias     | Expands to                                                                 |
|-----------|----------------------------------------------------------------------------|
| `d`       | `docker`                                                                   |
| `dps`     | `docker ps`                                                                |
| `dpsa`    | `docker ps -a`                                                             |
| `di`      | `docker images`                                                            |
| `dex`     | `docker exec -it`                                                          |
| `dlog`    | `docker logs -f`                                                           |
| `drun`    | `docker run --rm -it`                                                      |
| `dstats`  | `docker stats`                                                             |
| `dprune`  | `docker system prune -af --volumes`                                        |
| `dip`     | prints a container's primary IP (`docker inspect -f …`)                    |
| `dc`      | `docker compose` (v2 — only if `docker compose` is available)              |
| `dcu`     | `docker compose up -d`                                                     |
| `dcd`     | `docker compose down`                                                      |
| `dcl`     | `docker compose logs -f`                                                   |
| `dcps`    | `docker compose ps`                                                        |
| `dcb`     | `docker compose build`                                                     |
| `dcr`     | `docker compose restart`                                                   |

### Terraform / OpenTofu

| Alias  | Expands to                        |
|--------|-----------------------------------|
| `tf`   | `terraform`                       |
| `tfi`  | `terraform init`                  |
| `tfp`  | `terraform plan`                  |
| `tfa`  | `terraform apply`                 |
| `tfaa` | `terraform apply -auto-approve`   |
| `tfd`  | `terraform destroy`               |
| `tfo`  | `terraform output`                |
| `tfs`  | `terraform state`                 |
| `tff`  | `terraform fmt -recursive`        |
| `tfv`  | `terraform validate`              |
| `tfw`  | `terraform workspace`             |
| `to`   | `tofu` (if installed)             |

### Helm

| Alias | Expands to                   |
|-------|------------------------------|
| `h`   | `helm`                       |
| `hls` | `helm list`                  |
| `hla` | `helm list --all-namespaces` |
| `hi`  | `helm install`               |
| `hu`  | `helm uninstall`             |
| `hup` | `helm upgrade --install`     |
| `hr`  | `helm repo`                  |
| `ht`  | `helm template`              |

### AWS CLI

| Alias  | Expands to                                |
|--------|-------------------------------------------|
| `awsw` | `aws sts get-caller-identity` (who am I?) |
| `awsl` | `aws sso login`                           |
| `awsr` | `aws configure list-profiles`             |

### Azure CLI

| Alias    | Expands to                                                |
|----------|-----------------------------------------------------------|
| `azl`    | `az login`                                                |
| `azlo`   | `az logout`                                               |
| `azw`    | `az account show` (current subscription)                  |
| `azacc`  | `az account list --output table`                          |
| `azset`  | `az account set --subscription <name-or-id>`              |
| `azg`    | `az group list --output table`                            |
| `azaks`  | `az aks get-credentials` (use as `azaks -g <rg> -n <cl>`) |

### Python (`uv`)

[`uv`](https://github.com/astral-sh/uv) — fast Python package + venv + interpreter manager (replaces pip/venv/pyenv/poetry for most flows).

| Alias    | Expands to                                              |
|----------|---------------------------------------------------------|
| `uvi`    | `uv pip install` (into active venv)                     |
| `uvr`    | `uv run` (run script with deps auto-resolved)           |
| `uvs`    | `uv sync` (install project deps from `uv.lock`)         |
| `uva`    | `uv add <pkg>` (add dep to `pyproject.toml`)            |
| `uvrm`   | `uv remove <pkg>`                                       |
| `uvenv`  | `uv venv` (creates `.venv` in cwd)                      |
| `uvpy`   | `uv python install <ver>` (install a CPython version)   |
| `uvx`    | one-shot tool runner — like `pipx run` (`uvx ruff …`)   |

### GitHub CLI (`gh`)

| Alias     | Expands to                                                |
|-----------|-----------------------------------------------------------|
| `ghv`     | `gh repo view --web` (open this repo in browser)          |
| `ghc`     | `gh repo clone owner/repo`                                |
| `ghf`     | `gh repo fork --clone`                                    |
| `ghpr`    | `gh pr create --web` (PR-creation page in browser)        |
| `ghprl`   | `gh pr list`                                              |
| `ghprv`   | `gh pr view --web` (view current branch's PR)             |
| `ghprco`  | `gh pr checkout <number>`                                 |
| `ghprm`   | `gh pr merge --squash --delete-branch`                    |
| `ghprs`   | `gh pr status` (yours + needing review)                   |
| `ghi`     | `gh issue create --web`                                   |
| `ghil`    | `gh issue list`                                           |
| `ghiv`    | `gh issue view --web <number>`                            |
| `ghrun`   | `gh run list` (recent workflow runs)                      |
| `ghwatch` | `gh run watch` (live-watch a run)                         |
| `gha`     | `gh auth status`                                          |

### Git extras

OMZ's `git` plugin covers the basics (`gst`, `gco`, `gp`, `glo`, etc.); these are extras:

| Alias    | Expands to                                                             |
|----------|------------------------------------------------------------------------|
| `gpr`    | `git pull --rebase`                                                    |
| `gprune` | fetch + delete local branches whose remote is gone                     |

### Networking & system

| Alias       | What it does                                          |
|-------------|-------------------------------------------------------|
| `myip`      | public IP via `https://api.ipify.org`                 |
| `localip`   | LAN IPv4 address(es)                                  |
| `ports`     | `ss -tulpn` (or `netstat -tulpn` fallback)            |
| `listening` | `ss -tlpn` — listening TCP sockets                    |
| `weather`   | one-line `wttr.in` forecast                           |
| `psg`       | fuzzy `ps aux \| grep` (e.g. `psg nginx`)             |
| `mem`       | top 10 memory consumers                               |
| `cpu`       | top 10 CPU consumers                                  |
| `path`      | print `$PATH` one entry per line                      |
| `reload`    | `exec zsh` — pick up zshrc changes without re-login   |

---

## What's NOT in this config (by design)

- **No `atuin`** — uses zsh-native history file. `Ctrl-R` falls through to the `fzf` plugin's incremental search.
- **No `zsh-vi-mode`** — emacs-style line editing only.
- **No `starship`** — Powerlevel10k handles the prompt.

---

## File layout

```
~/.config/zsh/
├── .zshrc          # orchestrator — sources the three modules below
├── pluginrc        # OMZ + plugins=(…) array (conditional on installed tools)
├── optionrc        # setopt block + history config
├── aliasrc         # all aliases (general + DevOps + modern CLI)
├── local.zsh       # host-specific tweaks (not portable)
├── .p10k.zsh       # Powerlevel10k theme (created by `p10k configure`)
├── README.md
└── .zcompdump-*    # zsh completion cache (regenerated; safe to delete)

~/.zshenv           # sets XDG_* and ZDOTDIR=$HOME/.config/zsh
```

Load order from `.zshrc`: `pluginrc` → `optionrc` → `aliasrc` → tool integrations → p10k → `local.zsh`. Plugins must load first so `compdef` calls in `aliasrc` (e.g. `compdef __start_kubectl k`) resolve.

---

## Troubleshooting

**Prompt looks like garbage / boxes** — install a Nerd Font and set your terminal to use it.

**`fzf-tab` doesn't activate** — make sure it's listed in the `plugins=(...)` array *before* `zsh-autosuggestions` and `fast-syntax-highlighting`.

**`compinit: insecure directories`** — run `compaudit | xargs chmod g-w,o-w`.

**Slow startup** — run `zsh -xv 2>&1 | head -50` to see what's loading; the usual suspect is NVM. Use [lazy-nvm](https://github.com/lukechilds/zsh-nvm) if it bothers you.

**Per-OS plugin not loading** — the script auto-detects via `/etc/fedora-release`, `/etc/arch-release`, or `uname -s`. Check `echo $CURRENT_OS` matches what you expect.

---

## Tool tips

Real-world usage for the tools the config wires in. Everything below assumes you ran the install command in §6.

### `eza` (replaces `ls`)

Aliases set by `.zshrc`: `ls`, `ll`, `la`, `tree`.

```sh
ll                          # long listing, icons, git status
la                          # same + dotfiles
tree -L 2                   # tree, two levels deep
eza -lh --total-size        # show real directory sizes
eza -l --sort=size --reverse  # biggest files first
eza -l --git-ignore         # hide files matched by .gitignore
\ls                         # plain GNU ls (escape the alias)
```

### `bat` (replaces `cat`)

Aliased to `bat --paging=never` so output still pipes cleanly. Also wired as `$MANPAGER` so `man <cmd>` is colorized.

```sh
cat file.py                 # syntax-highlighted, no pager
bat -n file.py              # show line numbers
bat -A config.ini           # show whitespace / non-printable chars
bat -r 40:80 file.py        # only lines 40–80
bat --list-themes           # pick a theme
\cat file                   # plain GNU cat (escape the alias)
echo "hello" | bat -l md    # force markdown highlighting on stdin
```

### `zoxide` (smart `cd`)

Learns the directories you visit and lets you jump back by partial name. Hooked in by `.zshrc`.

```sh
cd ~/work/projects/api      # use cd once — zoxide records it
z api                       # jump back from anywhere
z work api                  # match multiple terms (AND)
zi                          # interactive picker (fzf-powered)
z -                         # previous dir (like `cd -`)
zoxide query api            # print the path z would jump to
zoxide remove ~/old/path    # forget a directory
```

Database lives at `$XDG_DATA_HOME/zoxide/db.zo`. Delete it to reset.

### `direnv` (per-directory env vars)

Put a `.envrc` at the root of a project; vars load on `cd` in, unload on `cd` out.

```sh
cd ~/work/myproject
echo 'export AWS_PROFILE=dev'         > .envrc
echo 'export DATABASE_URL=postgres://…' >> .envrc
direnv allow                # one-time approval (re-run after edits)
```

Useful built-in layouts (put inside `.envrc`):

```sh
layout python python3.12    # auto-create + activate venv
layout node                 # add ./node_modules/.bin to PATH
PATH_add ./bin              # prepend ./bin to PATH for this dir
dotenv                      # load a .env file as env vars
```

Add `.envrc` to your `.gitignore` if it contains secrets — or commit a `.envrc.example` and have each dev `cp` it.

### `fzf-tab` (fuzzy `<TAB>` completion)

Replaces zsh's default menu with a live-filtered fzf UI plus previews.

```text
cd <Tab>            # fzf list of dirs; bat/eza previews on the right
ssh <Tab>           # fuzzy pick a host from ~/.ssh/config + known_hosts
kill <Tab>          # fuzzy pick a process
git checkout <Tab>  # fuzzy pick a branch (with last-commit preview)
```

Inside the fzf menu:

| Key       | Action                                       |
|-----------|----------------------------------------------|
| chars     | live filter                                  |
| `↑` / `↓` | move                                         |
| `,` / `.` | switch completion group (e.g. files vs dirs) |
| `Tab`     | accept                                       |
| `Esc`     | cancel                                       |

### `fzf` standalone (the `Ctrl-` keybinds)

| Key      | Action                                                       |
|----------|--------------------------------------------------------------|
| `Ctrl-T` | Insert path of a fuzzy-picked file at the cursor             |
| `Alt-C`  | `cd` to a fuzzy-picked subdirectory                          |
| `Ctrl-R` | Fuzzy-search shell history (incremental)                     |

`.zshrc` points `FZF_DEFAULT_COMMAND` at `fd`, so these all respect `.gitignore` and skip `.git/`.

### NVM (Node)

```sh
nvm install --lts           # install latest LTS
nvm use 20                  # switch to v20.x for this shell
nvm alias default 20        # default Node for new shells
```

A `.nvmrc` file in a project pins the version — combine with direnv's `use_nvm` or just run `nvm use` manually.

### `uv` (Python)

The Python equivalent of NVM + pip + venv + poetry. Aliases live in `aliasrc` (`uvi`, `uvr`, `uvs`, `uva`, `uvrm`, `uvenv`, `uvpy`, `uvx`).

```sh
# Start a project
uvenv                                     # creates .venv
uva fastapi httpx                         # add deps (writes to pyproject.toml + uv.lock)
uvs                                       # install everything from the lockfile
uvr main.py                               # run a script using the project venv

# Ad-hoc / no project
uvi requests pandas                       # install into current venv
uvr --with httpx -- python -c '...'       # one-off run with extra deps

# Manage Python versions
uvpy 3.12                                 # install CPython 3.12
uv python list                            # see what's available
uv python pin 3.12                        # write .python-version for this dir

# One-shot tools (replaces `pipx run`)
uvx ruff check .                          # run ruff without installing globally
uvx black src/                            # same for black
```

A `.python-version` file pins the interpreter version; combine with direnv (`layout uv` via [direnv community](https://github.com/direnv/direnv/wiki/Python#uv)) for full per-project isolation.

### DevOps aliases — usage

The full alias list lives in the [DevOps aliases](#devops-aliases) tables above; this section shows real-world workflows.

#### Using the Kubernetes aliases

```sh
# `k` is `kubectl` with completion — the OMZ kubectl plugin gives you ~100 more
k get pods -A                       # all pods across all namespaces
kpf svc/myapp 8080:80               # port-forward localhost:8080 → svc:80
kev                                 # cluster events sorted by time (debug "what just happened")
kaa                                 # everything, everywhere
ktop pods                           # live CPU/mem per pod
kdebug --image=busybox -- sh        # netshoot pod for in-cluster net debugging
                                    # `--rm -it --restart=Never` is already baked in

# Context / namespace switching (kubectx / kubens)
kctx                                # list contexts; pick one
kctx prod                           # switch to "prod" context
kns kube-system                     # switch default namespace

# Multi-pod log tailing (stern)
ks myapp                            # tail logs from all pods matching "myapp"
ks -n prod 'web-.*'                 # regex match in a specific namespace

# Cluster TUI
k9                                  # launches k9s

# Local dev clusters (kind)
kindc                               # create a single-node cluster called "kind"
kindc --name dev --config kind.yml  # custom multi-node cluster
kindg                               # list clusters
kindl myapp:dev                     # push a local image into the cluster
                                    # (much faster than docker push → pull)
kindd --name dev                    # tear it down
```

#### Using the Docker aliases

```sh
dps                                 # running containers
dpsa                                # all containers (incl. stopped)
di                                  # images
dex web bash                        # shell into the "web" container
dlog web                            # follow logs of "web"
drun -p 8080:80 nginx               # run nginx, expose 8080, auto-cleanup
dprune                              # nuke unused images/containers/volumes
dip my-container                    # print the container's IP

# Compose v2
dc up -d                            # = docker compose up -d  (or just `dcu`)
dcl                                 # docker compose logs -f
dcb web                             # rebuild a specific service
dcd                                 # tear down the stack
```

#### Using the Terraform / OpenTofu aliases

```sh
tfi                                 # terraform init
tfp -out=tf.plan                    # plan to a file
tfa tf.plan                         # apply that plan
tfaa                                # apply without confirmation (CI / scripts)
tff                                 # format everything in repo
tfv                                 # validate config
tfw list                            # workspaces
tfs list                            # state contents
tfo db_url                          # output a single value
to plan                             # same workflow on OpenTofu
```

#### Using the GitHub CLI aliases

```sh
# Repo / clone / browser
ghv                                 # open current repo's GitHub page
ghc anthropics/claude-code          # clone owner/repo
ghf rust-lang/rust                  # fork + clone in one step

# Pull requests
ghpr                                # open PR-create page for current branch
ghprs                               # mine + needing review
ghprl --state=open --author=@me     # open PRs I authored
ghprv                               # view current branch's PR in browser
ghprco 1234                         # checkout PR #1234 locally
ghprm                               # squash-merge + delete branch

# Issues
ghi                                 # create issue in browser
ghil --label bug                    # filter by label
ghiv 42                             # view issue #42 in browser

# CI / Actions
ghrun                               # last 20 workflow runs
ghwatch                             # watch the latest run live
gh run view --log-failed            # logs from failed jobs (no alias — too niche)

# Auth
gha                                 # who am I logged in as?
```

#### Using the Helm aliases

```sh
hr add bitnami https://charts.bitnami.com/bitnami
hr update
hi myapp bitnami/nginx --namespace web --create-namespace
hup myapp bitnami/nginx -f values.yaml      # install-or-upgrade idempotently
hls                                          # releases in current namespace
hla                                          # releases everywhere
ht myapp bitnami/nginx > rendered.yaml       # render without installing
```

#### AWS / Azure

```sh
# AWS
awsl                                # SSO login
awsw                                # who am I? (sts get-caller-identity)
awsr                                # list configured profiles

# Azure
azl                                 # browser-based login
azw                                 # current subscription
azacc                               # list all subscriptions (table)
azset "My Sub"                      # switch to that subscription
azg                                 # list resource groups
azaks -g myrg -n mycluster          # pull kubeconfig for an AKS cluster
```

#### Networking & system

```sh
myip                                # public IP
localip                             # LAN IP(s)
ports                               # all listening + connected sockets w/ PIDs
listening                           # only listening TCP sockets
psg nginx                           # find nginx processes
mem                                 # top 10 RAM hogs
cpu                                 # top 10 CPU hogs
weather                             # one-line forecast for your geo
reload                              # `exec zsh` — apply zshrc edits in place
path                                # print $PATH one entry per line
```
