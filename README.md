# my zsh config

**Repo:** [github.com/aganet/zsh](https://github.com/aganet/zsh) — the whole config lives there. Clone it, fork it, or copy whatever bits look useful. The rest of this post is what's in the repo plus how I actually use it day-to-day.

This is the zsh setup I use on every machine — Arch at home, macOS when I'm on the laptop, Ubuntu, and whatever distro a work VM happens to be running. Same files, same aliases, same prompt everywhere.

It's built on **Oh My Zsh + Powerlevel10k**, with modern CLI replacements wired in (`eza`, `bat`, `fd`, `zoxide`, `direnv`, `fzf-tab`) and a curated set of DevOps aliases for the tools I touch daily: `kubectl`, `docker`, `terraform`, `helm`, `kind`, `aws`, `az`, `uv`, `gh`.

The config **auto-detects the OS** (macOS / Arch / Fedora / generic Linux) and only loads plugins for tools that are actually installed — so I can drop the same files on any box and they just work.

## Why I split it into four files

It started as a single 200-line `.zshrc` that grew organically over years. Eventually it got unwieldy — adding a new alias meant scrolling past plugin configuration, history settings, and OS-detection logic.

So I split it, inspired by [radleylewis/dotfiles](https://github.com/radleylewis/dotfiles/tree/master/.config/zsh):

- `pluginrc` for OMZ + the plugin list
- `optionrc` for `setopt` + history
- `aliasrc` for every alias (general / modern CLI / DevOps)
- `local.zsh` for host-specific bits I don't want in git

The main `.zshrc` is now just an orchestrator: prompt → OS detect → PATH → source the modules → tool integrations → p10k → host overrides.

## Layout

```text
~/.zshenv               # sets XDG_* + ZDOTDIR — only file in $HOME
~/.config/zsh/
├── .zshrc              # orchestrator: prompt, OS detect, PATH, tool integrations
├── pluginrc            # OMZ + plugins=(…) (conditional on installed tools)
├── optionrc            # setopt + history settings
├── aliasrc             # all aliases (general + modern CLI + DevOps)
├── local.zsh           # host-specific (Arch update alias, work SSH, …)
└── .p10k.zsh           # Powerlevel10k theme (created by `p10k configure`)
```

Load order: `pluginrc` → `optionrc` → `aliasrc` → tool integrations → p10k → `local.zsh`. Plugins must load first so `compdef` calls in `aliasrc` (e.g. `compdef __start_kubectl k`) resolve.

---

## Install

### Prerequisites

`zsh` ≥ 5.8, `git`, and a [Nerd Font](https://www.nerdfonts.com/font-downloads) in your terminal (recommended: JetBrainsMono Nerd Font) — required for the Powerlevel10k icons.

### 1. Clone the repo + point zsh at it

```bash
git clone https://github.com/aganet/zsh.git ~/.config/zsh
echo 'export ZDOTDIR="$HOME/.config/zsh"' > ~/.zshenv
```

That's the only file that lives in `$HOME` — everything else is under `~/.config/zsh/`.

### 2. Oh My Zsh + Powerlevel10k + custom plugins

```bash
# Oh My Zsh (--keep-zshrc preserves the repo's .zshrc)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

# Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Custom plugins (zsh-autosuggestions, fast-syntax-highlighting, fzf-tab)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions          "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
git clone --depth=1 https://github.com/Aloxaf/fzf-tab                         "$ZSH_CUSTOM/plugins/fzf-tab"
```

### 3. CLI tools (Homebrew everywhere)

Same brew commands work on macOS, Arch, Ubuntu/Debian, Fedora, and WSL. On Linux, install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/main/install.sh)"
```

The `.zshrc` runs `brew shellenv` automatically, so you don't need to edit `~/.profile`.

```bash
# Core CLI + DevOps + Go/Ruby version manager — single brew call
brew install \
  zsh fzf fd bat eza ripgrep zoxide git-delta gh lazygit tldr btop \
  direnv neovim tmux \
  kubectl kubectx helm terraform k9s awscli stern azure-cli kind opentofu \
  go rbenv ruby-build

# fzf keybindings (one-time, after fzf is installed)
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc

# Python (uv) — official installer (or `brew install uv`, or `sudo pacman -S uv`)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Node (NVM) — official installer (the .zshrc expects $NVM_DIR at $HOME/.nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

**Docker** is the one thing brew can't fully install on Linux (it doesn't manage the daemon):

- **macOS** — `brew install --cask docker` (Docker Desktop) or `brew install colima && colima start`
- **Arch** — `sudo pacman -S docker docker-compose && sudo systemctl enable --now docker`
- **Ubuntu / Debian / Fedora** — follow [docker.com/engine/install](https://docs.docker.com/engine/install/)

Missing tools degrade gracefully — every alias in `aliasrc` is `command -v`-gated.

### 4. Set zsh as your login shell

```bash
chsh -s "$(command -v zsh)"
```

Log out, log back in. Run `p10k configure` if the prompt wizard doesn't start automatically.

### 5. (Optional) Wire `delta` into git

```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global merge.conflictstyle "zdiff3"
```

---

## Cheat sheet

| Keys / cmd                  | What                                                |
|-----------------------------|-----------------------------------------------------|
| `Ctrl-T`                    | Fuzzy-pick a file path, insert at cursor            |
| `Alt-C`                     | Fuzzy-pick a dir and `cd` into it                   |
| `Ctrl-R`                    | Fuzzy history search                                |
| `<TAB>`                     | fzf-powered completion menu with bat/eza previews   |
| `z <name>` / `zi`           | Jump to dir via zoxide / interactive picker         |
| `git diff` / `lazygit`      | Delta-colored diff / git TUI                        |
| `tldr <cmd>`                | Quick examples (e.g. `tldr tar`)                    |
| `btop`                      | System monitor                                      |
| `.envrc` + `direnv allow`   | Per-directory env vars                              |
| `reload`                    | `exec zsh` to apply rc-file edits                   |

---

## DevOps aliases

All in `aliasrc`, each block gated by `command -v <tool>` so missing tools are silent no-ops. Aliases the OMZ `git` / `kubectl` / `docker-compose` / `helm` / `terraform` / `aws` / `azure` plugins already provide are **not** re-defined here — see the [OMZ plugin docs](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins) for those.

### Kubernetes (kubectl / kubectx / stern / k9s / kind)

| Alias    | Runs                                                          |
|----------|---------------------------------------------------------------|
| `k`      | `kubectl` (with completion)                                   |
| `kpf`    | `kubectl port-forward`                                        |
| `kev`    | `kubectl get events --sort-by=.lastTimestamp`                 |
| `kaa`    | `kubectl get all --all-namespaces`                            |
| `ktop`   | `kubectl top`                                                 |
| `kapi`   | `kubectl api-resources`                                       |
| `kdebug` | ephemeral `nicolaka/netshoot` pod for net debugging           |
| `kctx`   | `kubectx` — switch context                                    |
| `kns`    | `kubens` — switch namespace                                   |
| `ks`     | `stern` — multi-pod log tail                                  |
| `k9`     | `k9s` — cluster TUI                                           |
| `kindc`  | `kind create cluster`                                         |
| `kindd`  | `kind delete cluster`                                         |
| `kindg`  | `kind get clusters`                                           |
| `kindl`  | `kind load docker-image` (push local image into cluster)      |

```sh
k get pods -A
kpf svc/myapp 8080:80                       # localhost:8080 → svc:80
kev                                          # what just happened?
kdebug --image=nicolaka/netshoot -- sh       # in-cluster debugging
kctx prod && kns app                         # switch to prod / app namespace
ks 'web-.*'                                  # tail logs from web-* pods
kindc --name dev && kindl myapp:dev --name dev   # local cluster + load image
```

### Docker

| Alias    | Runs                                                          |
|----------|---------------------------------------------------------------|
| `d`      | `docker`                                                      |
| `dps`    | `docker ps`                                                   |
| `dpsa`   | `docker ps -a`                                                |
| `di`     | `docker images`                                               |
| `dex`    | `docker exec -it`                                             |
| `dlog`   | `docker logs -f`                                              |
| `drun`   | `docker run --rm -it`                                         |
| `dstats` | `docker stats`                                                |
| `dprune` | `docker system prune -af --volumes`                           |
| `dip`    | print a container's primary IP                                |
| `dc`     | `docker compose` (v2)                                         |
| `dcu`    | `docker compose up -d`                                        |
| `dcd`    | `docker compose down`                                         |
| `dcl`    | `docker compose logs -f`                                      |
| `dcps`   | `docker compose ps`                                           |
| `dcb`    | `docker compose build`                                        |
| `dcr`    | `docker compose restart`                                      |

```sh
dex web bash                        # shell into the "web" container
drun -p 8080:80 nginx               # run nginx, auto-cleanup on exit
dprune                              # nuke unused images/containers/volumes
dcu && dcl                          # bring stack up + tail logs
```

### Terraform / OpenTofu

| Alias  | Runs                              |
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
| `to`   | `tofu`                            |

```sh
tfi && tfp -out=tf.plan && tfa tf.plan
tff && tfv                          # format + validate everything
```

### Helm

| Alias | Runs                            |
|-------|---------------------------------|
| `h`   | `helm`                          |
| `hls` | `helm list`                     |
| `hla` | `helm list --all-namespaces`    |
| `hi`  | `helm install`                  |
| `hu`  | `helm uninstall`                |
| `hup` | `helm upgrade --install`        |
| `hr`  | `helm repo`                     |
| `ht`  | `helm template`                 |

```sh
hr add bitnami https://charts.bitnami.com/bitnami && hr update
hup myapp bitnami/nginx -f values.yaml --namespace web --create-namespace
ht myapp bitnami/nginx > rendered.yaml      # render without installing
```

### AWS CLI

| Alias  | Runs                                          |
|--------|-----------------------------------------------|
| `awsw` | `aws sts get-caller-identity` — who am I?     |
| `awsl` | `aws sso login`                               |
| `awsr` | `aws configure list-profiles`                 |

### Azure CLI

| Alias   | Runs                                                      |
|---------|-----------------------------------------------------------|
| `azl`   | `az login`                                                |
| `azlo`  | `az logout`                                               |
| `azw`   | `az account show` — current subscription                  |
| `azacc` | `az account list --output table`                          |
| `azset` | `az account set --subscription <name-or-id>`              |
| `azg`   | `az group list --output table`                            |
| `azaks` | `az aks get-credentials` — use as `azaks -g <rg> -n <cl>` |

### Python (uv)

[`uv`](https://github.com/astral-sh/uv) — fast Python package + venv + interpreter manager (replaces pip/venv/pyenv/poetry).

| Alias   | Runs                                              |
|---------|---------------------------------------------------|
| `uvi`   | `uv pip install` (into active venv)               |
| `uvr`   | `uv run` (script with deps auto-resolved)         |
| `uvs`   | `uv sync` (install from `uv.lock`)                |
| `uva`   | `uv add <pkg>`                                    |
| `uvrm`  | `uv remove <pkg>`                                 |
| `uvenv` | `uv venv` (creates `.venv`)                       |
| `uvpy`  | `uv python install <ver>`                         |
| `uvx`   | one-shot tool runner (`uvx ruff …`)               |

```sh
uvenv && uva fastapi httpx          # new venv + deps
uvs                                  # install from uv.lock
uvr main.py                          # run with project deps
uvx ruff check .                     # one-shot tool
uvpy 3.12                            # install CPython 3.12
```

### GitHub CLI (gh)

| Alias     | Runs                                                  |
|-----------|-------------------------------------------------------|
| `ghv`     | `gh repo view --web`                                  |
| `ghc`     | `gh repo clone owner/repo`                            |
| `ghf`     | `gh repo fork --clone`                                |
| `ghpr`    | `gh pr create --web`                                  |
| `ghprl`   | `gh pr list`                                          |
| `ghprv`   | `gh pr view --web`                                    |
| `ghprco`  | `gh pr checkout <number>`                             |
| `ghprm`   | `gh pr merge --squash --delete-branch`                |
| `ghprs`   | `gh pr status` (yours + needing review)               |
| `ghi`     | `gh issue create --web`                               |
| `ghil`    | `gh issue list`                                       |
| `ghiv`    | `gh issue view --web <number>`                        |
| `ghrun`   | `gh run list` (workflow runs)                         |
| `ghwatch` | `gh run watch`                                        |
| `gha`     | `gh auth status`                                      |

### Git extras

OMZ's `git` plugin covers the basics (`gst`, `gco`, `gp`, `glo`, …); these are extras:

| Alias    | Runs                                                              |
|----------|-------------------------------------------------------------------|
| `gpr`    | `git pull --rebase`                                               |
| `gprune` | fetch + delete local branches whose remote is gone                |

### Networking & system

| Alias       | What                                                       |
|-------------|------------------------------------------------------------|
| `myip`      | public IP (via api.ipify.org)                              |
| `localip`   | LAN IPv4 address(es)                                       |
| `ports`     | `ss -tulpn` — all sockets                                  |
| `listening` | `ss -tlpn` — listening TCP only                            |
| `psg`       | fuzzy `ps aux \| grep` (e.g. `psg nginx`)                  |
| `mem`       | top 10 RAM consumers                                       |
| `cpu`       | top 10 CPU consumers                                       |
| `weather`   | one-line `wttr.in` forecast                                |
| `path`      | print `$PATH` one entry per line                           |
| `reload`    | `exec zsh`                                                 |

---

## Tool tips

### `eza` (replaces `ls`)

Aliases: `ls`, `ll`, `la`, `tree`.

```sh
ll                          # long listing, icons, git status
la                          # + dotfiles
tree -L 2                   # tree, two levels deep
eza -lh --total-size        # real directory sizes
eza -l --sort=size -r       # biggest files first
\ls                          # escape the alias
```

### `bat` (replaces `cat`)

Aliased to `bat --paging=never`; also wired as `$MANPAGER`.

```sh
cat file.py                 # syntax-highlighted
bat -n file.py              # line numbers
bat -r 40:80 file.py        # lines 40–80
\cat file                   # escape the alias
echo hi | bat -l md         # force markdown highlighting
```

### `zoxide` (smart `cd`)

```sh
cd ~/work/api               # use cd once — zoxide records it
z api                       # jump back from anywhere
z work api                  # AND-match multiple terms
zi                          # fzf picker
zoxide remove ~/old/path    # forget
```

Database lives at `$XDG_DATA_HOME/zoxide/db.zo` — delete to reset.

### `direnv` (per-directory env vars)

```sh
cd ~/proj
echo 'export AWS_PROFILE=dev' > .envrc
direnv allow                # one-time approval
```

Useful in `.envrc`:

```sh
layout python python3.12    # auto-create + activate venv
layout node                 # add ./node_modules/.bin to PATH
PATH_add ./bin
dotenv                      # load a .env file
```

### `fzf-tab` (`<TAB>` menu)

```text
cd <Tab>            # dirs with bat/eza preview
ssh <Tab>           # hosts from ~/.ssh/config + known_hosts
git checkout <Tab>  # branches with last-commit preview
```

Inside the menu: type to filter, `↑`/`↓` to move, `,` / `.` to switch groups, `Tab` to accept, `Esc` to cancel.

### NVM (Node)

```sh
nvm install --lts
nvm use 20
nvm alias default 20
```

`.nvmrc` pins the version per-project — pair with direnv's `use_nvm` or run `nvm use` manually.

---

## Troubleshooting

- **Garbled prompt / boxes** — install a Nerd Font and configure your terminal to use it.
- **fzf-tab inactive** — must come *before* `zsh-autosuggestions` and `fast-syntax-highlighting` in `plugins=(…)`. Already correct in `pluginrc`.
- **`compinit: insecure directories`** — `compaudit | xargs chmod g-w,o-w`.
- **Slow startup** — profile with `zsh -xv 2>&1 | head -50`. NVM is usually the culprit; see [lazy-nvm](https://github.com/lukechilds/zsh-nvm).
- **Per-OS plugin not loading** — check `echo $CURRENT_OS` (`arch` / `fedora` / `linux` / `macos`) matches what you expect.

---

## Not in this config (on purpose)

- **No `atuin`** — sticking with zsh-native history + fzf's `Ctrl-R`.
- **No `zsh-vi-mode`** — emacs-style line editing only.
- **No `starship`** — Powerlevel10k already handles the prompt.
