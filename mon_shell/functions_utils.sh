#!/usr/bin/env zsh
# --------------------------------------------------
# Utilitaires génériques (couleurs, alias dynamiques, backup)
# --------------------------------------------------

# ---------- echo_color ----------
unalias echo_color 2>/dev/null
echo_color() {
  # Usage : echo_color "Message" $VERT
  local msg="$1" color="$2"
  printf "${color}%s${RESET}\n" "$msg"
}
# EX: echo_color "Hello, world!" $BLEU
# --------------------------------------------------
# ---------- mkalias_color ----------
# mkalias_color nom VAR_COULEUR "commande" [message]
# Crée un alias avec une couleur et un message optionnel.
# Exemple : mkalias_color reload VERT "source ~/.zshrc" "RECHARGEMENT SHELL"
# Utilise la variable de couleur définie dans colors.sh.
unalias mkalias_color 2>/dev/null
mkalias_color() {
  local _name="$1" _color="$2" _cmd="$3" _msg="${4:-}"
  if [[ -z $_name || -z $_color || -z $_cmd ]]; then
    printf "${ROUGE}Usage : mkalias_color nom VAR_COULEUR \"commande\" [message]${RESET}\n"
    return 1
  fi

  # On protège les apostrophes dans le message
  local _msg_safe=${_msg//\'/\'\\\'\'}

  local _line
  if [[ -n $_msg ]]; then
    # Même structure que ton alias reload :
    # '…commande… && printf "${COULEUR}message${RESET}\n"'
    _line="alias $_name='${_cmd} && printf \"\${${_color}}${_msg_safe}\${RESET}\\n\"'"
  else
    _line="alias $_name='${_cmd}'"
  fi

  echo "$_line" >> "$HOME/.mon_shell/aliases.sh"
  source "$HOME/.mon_shell/aliases.sh"
  printf "${VERT}Alias \`$_name\` créé.${RESET}\n"
}
 
# ---------- backup_mon_shell ----------
# backup_mon_shell [/chemin/vers/repo/local]
# Sauvegarde le dossier .mon_shell dans un dépôt Git local ou distant.
# Si le dépôt n'existe pas, affiche un message d'erreur.
# Utilise rsync pour synchroniser les fichiers.
# Nécessite que le dépôt soit déjà initialisé avec git.
# Exemple d'utilisation : backup_mon_shell ~/my_backup_repo
# Assure-toi que le dépôt est déjà initialisé avec git.
# Si le dépôt n'existe pas, affiche un message d'erreur.
# Si le dépôt n'est pas un dépôt Git, affiche un message d'erreur.

unalias backup_mon_shell 2>/dev/null
backup_mon_shell() {
  # backup_mon_shell [/chemin/vers/repo/local]
  local REPO="${1:-$HOME/ubuntu-configs}"
  if [[ ! -d "$REPO/.git" ]]; then
    echo_color "❌ Repo $REPO non trouvé ou inexistant." $ROUGE
    return 1
  fi
  rsync -a --delete "$HOME/.mon_shell/" "$REPO/mon_shell/"
#  rsync -a --delete "$HOME/.zshrc" "$REPO/" ".zshrc"
  if [[ $? -ne 0 ]]; then
    echo_color "❌ Erreur lors de la synchronisation avec $REPO." $ROUGE
    return 1
  fi
  (
    cd "$REPO" || return 1
    git add . &&
    git commit -m "Update $(date '+%F %T')" &&
    git push
  )
  echo_color "✅ .mon_shell sauvegardé sur GitHub." $VERT
}

# ---------- backup_ubuntu_configs ----------
# Sauvegarde les principaux dossiers/fichiers de configuration utilisateur pour Ubuntu 25.04 qui fonctionne avec GNOME.
# Propose une liste de dossiers/fichiers à sauvegarder pour faciliter la migration ou la restauration sur un autre PC d'une qualité de code niveau production.
# Le dépôt cible doit être déjà initialisé avec git qui se trouve dans ~/ubuntu-configs.
# noms de la fonction backup_ubuntu_configs.



  
# ---------- end of functions_utils.sh ----------
# --------------------------------------------------
# Source this file in your .zshrc or other scripts to use these functions.
# Example: source ~/.mon_shell/functions_utils.sh
# Ensure you have the necessary color variables defined in colors.sh.