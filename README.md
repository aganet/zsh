# My zsh config

**Repo:** [github.com/aganet/zsh](https://github.com/aganet/zsh) — the whole config lives there. Clone it, fork it, copy whatever bits look useful.

This is the zsh setup I use on every machine — Arch at home, Fedora at work, macOS on the laptop, and whatever distro a work VM happens to be running. **Same config everywhere, adapting to what's installed.** The post below explains what's in it, why I made the choices I did, and how I actually use it day-to-day.

It's built on **Oh My Zsh + Powerlevel10k**, with modern CLI replacements wired in (`eza`, `bat`, `fd`, `zoxide`, `direnv`, `fzf-tab`, `delta`) and a curated set of DevOps aliases for the tools I touch daily: `kubectl`, `docker`, `terraform`, `helm`, `kind`, `aws`, `az`, `uv`, `gh`.

The config **auto-detects the OS** (macOS / Arch / Fedora / generic Linux) and only loads plugins for tools that are actually installed — so I can drop the same files on any box and they just work.

## Performance

Real numbers from `time zsh -i -c exit` (5 warm runs, median):

| Host                            | Cold start | Warm start |
|---------------------------------|-----------:|-----------:|
| Fedora 44 laptop (this machine) |     ~3.9 s |     ~1.0 s |
| Arch desktop                    |        TBD |        TBD |
| macOS M-series                  |        TBD |        TBD |

The big cost on Linux is NVM (~600 ms by itself) plus Oh My Zsh's plugin chain. If you don't run Node, drop `[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"` or swap in [`zsh-nvm`](https://github.com/lukechilds/zsh-nvm) to lazy-load it.

To profile your own startup:

```sh
# rough total
time zsh -i -c exit

# per-function breakdown — add `zmodload zsh/zprof` near the top of .zshrc
# and `zprof` at the very bottom, then start a new shell.
```

---

## My principles

A few rules I follow when adding anything to this repo. They keep the config small, fast, and portable.

1. **One repo, one tool.** This repo is *only* zsh. Nvim, tmux, kitty, etc. live in their own repos under `~/.config/<tool>`. No monolithic dotfiles.
2. **The same files on every machine.** No `if hostname == "x"` branches. Anything machine-specific lives in `local.zsh`, which is git-ignored.
3. **Plugins are conditional.** `command -v <tool>` gates every alias and every plugin. No tool installed? No warnings — you just get fewer aliases.
4. **No surprises in `$HOME`.** The only file in `~` is a one-liner `.zshenv` that points zsh at `$XDG_CONFIG_HOME/zsh`. Everything else stays under `~/.config/zsh/`.
5. **Watch startup latency.** I profile with `zprof` when the shell feels slow and treat anything visibly noticeable (~50 ms in the table) as a candidate for lazy-loading or deletion. NVM is the usual offender.

---

## Why I split it into four files

This started as a single 200-line `.zshrc` and slowly turned into a junk drawer. Adding a new alias meant scrolling past plugin configuration, history settings, and OS-detection logic. So I split it, inspired by [radleylewis/dotfiles](https://github.com/radleylewis/dotfiles/tree/master/.config/zsh):

- `pluginrc` — OMZ + the plugin list (conditional on installed tools)
- `optionrc` — `setopt` + history settings
- `aliasrc` — every alias (general / modern CLI / DevOps)
- `local.zsh` — host-specific bits I don't want in git

The main `.zshrc` is an orchestrator: prompt → OS detect → PATH → source the modules → tool integrations → p10k → host overrides. The split is for **human readability, not shell performance** — at runtime everything ends up in one shell with no measurable overhead.

```text
~/.zshenv               # sets XDG_* + ZDOTDIR — the only file in $HOME
~/.config/zsh/
├── .zshrc              # orchestrator: prompt, OS detect, PATH, tool integrations
├── pluginrc            # OMZ + plugins=(…)
├── optionrc            # setopt + history settings
├── aliasrc             # all aliases
├── local.zsh           # host-specific (git-ignored)
└── .p10k.zsh           # Powerlevel10k theme (created by `p10k configure`)
```

Load order: `pluginrc` → `optionrc` → `aliasrc` → tool integrations → p10k → `local.zsh`. Plugins must load first so `compdef` calls in `aliasrc` (e.g. `compdef __start_kubectl k`) resolve against an already-initialized completion system.

---

## What I removed (and why)

### Atuin

I ran [atuin](https://github.com/atuinsh/atuin) for a while. It's a great tool — encrypted, syncable shell history with a TUI search. But:

- I never used the sync feature, and I didn't love an external SQLite database holding every command I'd ever typed.
- Its `precmd` / `preexec` hooks fired on every prompt, adding a small but noticeable latency.
- When I tried to uninstall it, leftover hooks lived on in already-open shells until I `exec zsh`'d. That's not atuin's fault — that's how zsh hooks work — but it nudged me toward keeping fewer "magical" components.

I went back to zsh-native history (`HISTFILE` + `share_history` + `hist_ignore_dups`) and let the OMZ `fzf` plugin handle `Ctrl-R`. Same fuzzy-search experience, zero background daemons, no extra database.

### `zsh-vi-mode`

I edit in vim/neovim — but at the shell prompt I want emacs keybindings (`Ctrl-A`, `Ctrl-E`, `Ctrl-W`). Different muscle memory for different contexts.

### `starship`

I tried it. Powerlevel10k's *instant prompt* feature is too good — the shell becomes interactive while p10k computes the right-hand side asynchronously. With starship I could feel the lag.

---

## How I actually use it (day-to-day workflows)

### Switching Kubernetes contexts

```sh
s                                  # opens fzf picker over all kubeconfigs
                                   # (powered by gardener/kubeswitch)
kctx prod && kns api               # OR explicit: kubectx + kubens
k get pods -A                      # k = kubectl
kev                                # what just happened in this namespace?
ks 'web-.*'                        # tail logs from all web-* pods (stern)
```

### Quick repo nav

```sh
z api                              # jump to ~/work/api from anywhere
z work api                         # AND-match multiple terms
zi                                 # fzf picker over zoxide history
```

I almost never type `cd` anymore. Once a path is in my zoxide DB, two letters are enough.

### Picking a file to edit

```sh
nvim $(fzf)                        # or: <Ctrl-T> at the prompt
```

`<Ctrl-T>` inserts a fzf-picked path right at the cursor, with bat-powered preview. Great for `nvim <Ctrl-T>`, `git add <Ctrl-T>`, `cp <Ctrl-T> .`.

### Project-specific env

```sh
cd ~/work/api
echo 'export AWS_PROFILE=work-dev' > .envrc
echo 'export KUBECONFIG=$PWD/kubeconfig.yaml' >> .envrc
direnv allow                       # one-time approval
```

Now any time I `cd ~/work/api`, my AWS profile and KUBECONFIG are scoped to that project. Leave the directory → they're unset.

### Git diff / PR workflow

```sh
git diff                           # side-by-side, syntax-highlighted (delta)
lazygit                            # TUI for staging hunks, rebasing, etc.
ghpr                               # opens PR creation page in browser
ghprs                              # PRs that need my review
ghprco 1234                        # check out PR #1234 locally
```

I do roughly 80% of my git via `lazygit` + `gh` aliases now. Plain `git` only when I need a script-friendly invocation.

### Quick docker stack

```sh
dcu && dcl                         # docker compose up -d, then tail logs
dex web bash                       # shell into the "web" container
dprune                             # cleanup unused images/containers/volumes
```

### Python project from scratch

```sh
uvenv && uva fastapi httpx         # new .venv, add deps to pyproject.toml
uvr main.py                        # run with project deps
uvx ruff check .                   # run ruff one-shot without installing it
```

`uv` replaced pip, venv, pyenv, and poetry in my workflow. Single binary, ~10× faster than pip.

### Cluster debugging from inside

```sh
kdebug                             # ephemeral netshoot pod with curl/dig/tcpdump
```

Useful when I need to verify DNS, hit a service from inside the cluster mesh, or check if a NetworkPolicy is doing what I expect.

---

## Install

### Prerequisites

`zsh` ≥ 5.8, `git`, and a [Nerd Font](https://www.nerdfonts.com/font-downloads) in your terminal (recommended: JetBrainsMono Nerd Font) — required for the Powerlevel10k icons.

### 1. Clone the repo + point zsh at it

```bash
git clone https://github.com/aganet/zsh.git ~/.config/zsh

# Append the ZDOTDIR line only if it's not already there — never overwrite.
touch ~/.zshenv
grep -qxF 'export ZDOTDIR="$HOME/.config/zsh"' ~/.zshenv || \
  echo 'export ZDOTDIR="$HOME/.config/zsh"' >> ~/.zshenv
```

> If you already have an `~/.zshenv` doing other things, the snippet above appends safely instead of clobbering it. Just `cat ~/.zshenv` afterwards to confirm.

That `~/.zshenv` is the only file that lives in `$HOME` — everything else is under `~/.config/zsh/`.

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

I standardize on **Homebrew across every machine** — including Linux — so the same `brew install …` line bootstraps a new box in one shot. It's a deliberate tradeoff: one command, identical versions across hosts, no per-distro package name juggling. The cost is an extra package manager on Linux and ~30 ms of startup time from `brew shellenv`.

**If you prefer your native package manager**, install equivalent packages via `pacman` / `dnf` / `apt` — every alias in `aliasrc` is `command -v`-gated, so it doesn't matter where the binary came from.

On Linux, install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/main/install.sh)"
```

The `.zshrc` runs `eval "$(brew shellenv)"` automatically (guarded by `command -v brew`), so you don't need to touch `~/.profile`.

```bash
# Core CLI + DevOps + Go/Ruby version manager — single brew call
brew install \
  zsh fzf fd bat eza ripgrep zoxide git-delta gh lazygit tldr btop \
  direnv neovim tmux \
  kubectl kubectx helm terraform k9s awscli stern azure-cli kind opentofu \
  go rbenv ruby-build

# fzf keybindings (one-time, after fzf is installed)
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc

# Python (uv) — official installer (or `brew install uv`)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Node (NVM) — official installer (the .zshrc expects $NVM_DIR at $HOME/.nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

**Docker** is the one thing brew can't fully install on Linux (it doesn't manage the daemon):

- **macOS** — `brew install --cask docker` (Docker Desktop) or `brew install colima && colima start`
- **Arch** — `sudo pacman -S docker docker-buildx docker-compose && sudo systemctl enable --now docker` (the `docker-compose` package on Arch ships Compose v2 as a Docker CLI plugin, so `docker compose …` Just Works)
- **Ubuntu / Debian / Fedora** — follow [docker.com/engine/install](https://docs.docker.com/engine/install/) — the official repo ships Compose v2 as `docker-compose-plugin`

**Gardener `switcher`** (for the `s` alias / k8s context fuzzy picker) — install directly from GitHub; the build in some distros is too old to support shell integration:

```bash
sudo curl -L -o /usr/local/bin/switcher \
  https://github.com/danielfoehrKn/kubeswitch/releases/latest/download/switcher_linux_amd64
sudo chmod +x /usr/local/bin/switcher
```

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
| `s`                         | Kubeconfig context picker (kubeswitch)              |
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
| `s`      | `switcher` (kubeswitch) — fuzzy context picker                |
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
\ls                         # escape the alias
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

## Troubleshooting (from my own scars)

These are the issues I've actually hit on this setup, and what fixed them.

- **Garbled prompt / boxes** — install a Nerd Font and configure your terminal to use it. p10k icons are in the font, not in zsh.
- **fzf-tab inactive** — `fzf-tab` (and any completion-shaping plugin) needs to load **before** `fast-syntax-highlighting`, which should generally be the last plugin in the list because it wraps widgets. `pluginrc` already has the right order; worth double-checking after manual edits.
- **`compinit: insecure directories`** — `compaudit | xargs chmod g-w,o-w`. Usually happens after a fresh OMZ install on a system with default group-writable home dirs.
- **Slow startup** — `zsh -xv 2>&1 | head -50` shows *load order* but not timing. For actual numbers use `time zsh -i -c exit` for a total, or `zmodload zsh/zprof` at the top + `zprof` at the bottom of `.zshrc` for a per-function breakdown. NVM is frequently the biggest offender; `kubectl completion`, heavy OMZ plugin chains, and `brew shellenv` are runners-up. See the [Performance](#performance) section for my numbers.
- **Per-OS plugin not loading** — check `echo $CURRENT_OS` (`arch` / `fedora` / `linux` / `macos`) matches what you expect. I detect via `/etc/arch-release`, `/etc/fedora-release`, and `uname -s`.
- **`Error: context with name "init" not found` on shell startup** — your `switcher` (kubeswitch) binary is too old to support shell integration. Upgrade it (see the install section) — `source <(switcher init zsh)` only works on v0.10+.
- **Leftover hooks from an uninstalled tool** — if you remove something like atuin from `.zshrc` but the hook still fires, it's because the running shell has the function in memory. `exec zsh` resets it.

---

## Not included

- `atuin` — native history + fzf's `Ctrl-R` is enough for me ([why](#atuin))
- `zsh-vi-mode` — emacs at the prompt, vim in the editor
- `starship` — p10k's instant prompt is faster
- `local.zsh` synced across machines — host-specific stuff is supposed to be host-specific

---

## License

MIT — take what you like, leave what you don't.
