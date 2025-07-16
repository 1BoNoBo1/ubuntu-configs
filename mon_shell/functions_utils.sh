#!/usr/bin/env zsh
# --------------------------------------------------
# Utilitaires génériques (couleurs, alias dynamiques, backup)
# --------------------------------------------------

# ---------- echo_color ----------
# ---------- echo_color (rétabli) ----------
unalias echo_color 2>/dev/null
echo_color() {
  # Usage : echo_color "Message" $VERT
  local msg="$1" color="$2"
  printf "${color}%s${RESET}\n" "$msg"
}
# EX: echo_color "Hello, world!" $BLEU

# ---------- mkalias_color (sécurisée : plus de \ devant les espaces) ----------
#!/usr/bin/env zsh
# ---------- mkalias_color (version finale, testée) ----------
# ---------- mkalias_color (simple, comme reload) ----------
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
# ----------------------------------------------------------
# -----------------------------------------------------------
# -------------------------------------------------------------
 
# ---------- backup_mon_shell ----------
unalias backup_mon_shell 2>/dev/null
backup_mon_shell() {
  # backup_mon_shell [/chemin/vers/repo/local]
  local REPO="${1:-$HOME/ubuntu-configs}"
  if [[ ! -d "$REPO/.git" ]]; then
    echo_color "❌ Repo $REPO non trouvé ou inexistant." $ROUGE
    return 1
  fi
  rsync -a --delete "$HOME/.mon_shell/" "$REPO/mon_shell/"
  (
    cd "$REPO" || return 1
    git add . &&
    git commit -m "Update $(date '+%F %T')" &&
    git push
  )
  echo_color "✅ .mon_shell sauvegardé sur GitHub." $VERT
}
