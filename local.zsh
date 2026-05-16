# Host/identity-specific config — NOT tracked in git (see .gitignore)
# Anything that depends on this specific machine, account, or work network
# goes here so the shared .zshrc can stay clean and portable.

# Personal PATH additions (only if the dir exists)
typeset -U path
[[ -d "${KREW_ROOT:-$HOME/.krew}/bin" ]] && path=("${KREW_ROOT:-$HOME/.krew}/bin" $path)
[[ -d "/usr/local/go/bin" ]]              && path=("/usr/local/go/bin" $path)
[[ -d "$HOME/.kubescape/bin" ]]           && path=("$HOME/.kubescape/bin" $path)
export PATH

# switcher / switch (k8s context switcher)
if command -v switcher &>/dev/null; then
  source <(switcher init zsh)
  alias s=switch
  command -v switch &>/dev/null && source <(switch completion zsh)
fi

# Nix (single-user install)
[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"

# Tilix / VTE integration (for shell-aware terminal features)
if [ -n "$TILIX_ID" ] || [ -n "$VTE_VERSION" ]; then
  [ -f /etc/profile.d/vte.sh ] && source /etc/profile.d/vte.sh
fi

# Legacy bash aliases
[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"
