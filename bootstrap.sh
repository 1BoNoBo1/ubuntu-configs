#!/usr/bin/env bash
# -----------------------------------------------------------
# Restaure ~/.mon_shell et .zshrc sur une nouvelle machine.
# Usage : bash bootstrap.sh [url_git_repo]
# -----------------------------------------------------------
set -euo pipefail

repo="${1:-git@github.com:TonUser/ubuntu-configs.git}"   # URL par défaut
dest="$HOME/ubuntu-configs"                              # Où cloner

# 1) Clone ou met à jour le dépôt
if [[ -d "$dest/.git" ]]; then
  git -C "$dest" pull --quiet
else
  git clone --depth 1 "$repo" "$dest"
fi

# 2) (optionnel) Installe la liste de paquets si elle existe
if [[ -f "$dest/packages.list" ]]; then
  echo "🔧 Installation des paquets APT listés…"
  xargs -a "$dest/packages.list" sudo apt-get install -y
fi

# 3) Recopie les dotfiles nécessaires
rsync -a --delete "$dest/mon_shell/" "$HOME/.mon_shell/"
cp        "$dest/.zshrc"            "$HOME/.zshrc"

# 4) Ajoute le loader ~/.mon_shell dans .zshrc s’il manque
if ! grep -q '.mon_shell/colors.sh' "$HOME/.zshrc"; then
cat <<'LOAD' >> "$HOME/.zshrc"

# Chargement auto de ~/.mon_shell
[[ -f "$HOME/.mon_shell/colors.sh"    ]] && source "$HOME/.mon_shell/colors.sh"
[[ -f "$HOME/.mon_shell/aliases.sh"   ]] && source "$HOME/.mon_shell/aliases.sh"
[[ -f "$HOME/.mon_shell/functions.sh" ]] && source "$HOME/.mon_shell/functions.sh"
LOAD
fi

# 5) Passe le shell par défaut à zsh (si disponible)
if [[ $(basename "$SHELL") != "zsh" ]] && command -v zsh >/dev/null; then
  chsh -s "$(command -v zsh)" "$USER"
fi

echo -e "\e[32m✅ Environnement restauré. Ouvre un nouveau terminal ou tape 'source ~/.zshrc'.\e[0m"
