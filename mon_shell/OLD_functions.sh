# ~/.mon_shell/functions.sh
# Fonctions utiles pour la configuration du shell.
# ========== outils couleur ==========
unalias echo_color 2>/dev/null
echo_color() {
    local message="$1"
    local color="$2"
    printf "${color}%s${RESET}\n" "$message"
}
# ===== Fonctions avancées, commentées et colorées ============
# ---------- mkalias_color (fix espaces/backslash) ----------
unalias mkalias_color 2>/dev/null
mkalias_color() {
  local _name="$1" _color="$2" _cmd="$3" _msg="${4:-}"
  if [[ -z "$_name" || -z "$_color" || -z "$_cmd" ]]; then
    echo_color "Usage : mkalias_color nom VAR_COULEUR \"commande\" [message]" $ROUGE
    return 1
  fi

  # Sécurise les simples quotes dans le message ( ' → '\'' )
  local _msg_safe=${_msg//\'/\'\\\'\'}

  local _line
  if [[ -n "$_msg" ]]; then
    _line="alias $_name='${_cmd}; printf \"\${${_color}}${_msg_safe}\${RESET}\\n\"'"
  else
    _line="alias $_name='${_cmd}'"
  fi

  print -r -- "$_line" >> "$HOME/.mon_shell/aliases.sh"
  source "$HOME/.mon_shell/aliases.sh"
  echo_color "Alias \`$_name\` créé." $VERT
}
# -----------------------------------------------------------
# ex: mkalias_color essai BLEU "echo hello" "on dirait que cela fonctionne"


# ========== fonctions système ==========
# utilisation: maj_ubuntu
unalias maj_ubuntu 2>/dev/null
maj_ubuntu() {
    echo_color "🔄 Mise à jour complète du système..." $JAUNE
    sudo apt update && sudo apt full-upgrade -y
    flatup && snapup
    sudo apt autoremove --purge -y && sudo apt clean
    echo_color "✅ Système à jour et propre." $VERT
}

# utilisation:  snapshot_rapide
unalias snapshot_rapide 2>/dev/null
snapshot_rapide() {
    if ! command -v timeshift &>/dev/null; then
        echo_color "❌ Timeshift n'est pas installé." $ROUGE
        return 1
    fi
    sudo timeshift --create --comments "Snapshot $(date '+%F_%T')" --tags D
    echo_color "📸 Snapshot créé." $VERT
}

# utilisation: maj_clamav
unalias maj_clamav 2>/dev/null
maj_clamav() {
    echo_color "⏸️  Arrêt freshclam..." $JAUNE
    sudo systemctl stop clamav-freshclam
    echo_color "⬇️  Téléchargement signatures..." $CYAN
    sudo freshclam
    echo_color "▶️  Redémarrage freshclam..." $JAUNE
    sudo systemctl start clamav-freshclam
    echo_color "✅ ClamAV à jour." $VERT
}

# ========== SMART ==========
# utilisation: check_ssd [disque]
unalias check_ssd 2>/dev/null
check_ssd() {
    local DEV="${1:-/dev/sda}"
    echo_color "🔍 SMART pour $DEV" $BLEU
    sudo smartctl -a "$DEV" | less
}

# ========== UFW ==========
# utilisation: activer_ufw
unalias activer_ufw 2>/dev/null
activer_ufw() {
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    echo_color "🛡️  UFW activé (+SSH permis)." $VERT
}

# utilisation: desactiver_ufw
unalias desactiver_ufw 2>/dev/null
desactiver_ufw() {
    sudo ufw disable
    echo_color "🚫 UFW désactivé." $ROUGE
}

unalias status_ufw 2>/dev/null
status_ufw() {
    sudo ufw status verbose
}

# utilisation: bloquer_tout
# Met à jour les règles par défaut pour bloquer tout le trafic entrant.
unalias bloquer_tout 2>/dev/null
bloquer_tout() {
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    echo_color "🌐 Règles par défaut mises à jour." $CYAN
}

# ========== journaux ==========
unalias nettoyer_logs 2>/dev/null
nettoyer_logs() {
    sudo journalctl --vacuum-time=7d
    echo_color "🧹 Journaux >7 jours supprimés." $VERT
}

# ========== Docker ==========
unalias docker_mise_a_jour 2>/dev/null
docker_mise_a_jour() {
    echo_color "🔍 Nettoyage des conteneurs Docker..." $CYAN
    docker container prune -f
    docker image prune -a -f
    echo_color "✅ Docker nettoyé." $VERT
}

# ========== analyse disque ==========
# utilisation: analyse_disque
# Affiche les informations sur les périphériques, étiquettes, UUID et occupation des systèmes de fichiers.
# Nécessite les droits sudo pour blkid et cryptsetup.
unalias analyse_disque 2>/dev/null
analyse_disque() {
    echo_color "== Vue d'ensemble des périphériques (lsblk) ==" $CYAN
    lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINT -e7

    echo_color "\n== Étiquettes & UUID (blkid) ==" $CYAN
    sudo blkid | sort

    echo_color "\n== Occupation des systèmes de fichiers (df -hT) ==" $CYAN
    df -hT

    echo_color "\n== Statut volumes chiffrés (cryptsetup) ==" $CYAN
    for map in $(ls /dev/mapper 2>/dev/null | grep -v control); do
        sudo cryptsetup status "$map" || true
        echo "---"
    done
}

# ========== sauvegarde GitHub ==========
unalias backup_mon_shell 2>/dev/null
backup_mon_shell() {
    # backup_mon_shell [/chemin/vers/repo/local]
    local REPO="${1:-$HOME/ubuntu-configs}"
    if [[ ! -d "$REPO/.git" ]]; then
        echo_color "❌ Repo $REPO non trouvé ou inexistant." $ROUGE
        return 1
    fi
    # Synchronise ~/.mon_shell → repo/mon_shell
    rsync -a --delete "$HOME/.mon_shell/" "$REPO/mon_shell/"
    echo_color "🔄 Synchronisation de .mon_shell vers $REPO/mon_shell" $CYAN
    # Synchronise .zshrc et .bashrc
    rsync -a --delete "$HOME/.zshrc" "$REPO/.zshrc"
    rsync -a --delete "$HOME/.bashrc" "$REPO/.bashrc"
    (
        cd "$REPO" || exit 1
        git add .
        git commit -m "Update $(date '+%F %T')" && git push
    )
    echo_color "✅ .mon_shell sauvegardé sur GitHub." $VERT
}