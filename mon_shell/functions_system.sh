#!/usr/bin/env zsh
# --------------------------------------------------
# Maintenance système, snapshots, disques, logs, docker
# --------------------------------------------------

# ---------- maj_ubuntu ----------
unalias maj_ubuntu 2>/dev/null
maj_ubuntu() {
  echo_color "🔄 Mise à jour complète du système..." $JAUNE
  sudo apt update && sudo apt full-upgrade -y
  command -v flatup &>/dev/null && flatup
  command -v snapup &>/dev/null && snapup
  sudo apt autoremove --purge -y && sudo apt clean
  echo_color "✅ Système à jour et propre." $VERT
}

# ---------- snapshot_rapide ----------
unalias snapshot_rapide 2>/dev/null
snapshot_rapide() {
  if ! command -v timeshift &>/dev/null; then
    echo_color "❌ Timeshift n'est pas installé." $ROUGE
    return 1
  fi
  sudo timeshift --create --comments "Snapshot $(date '+%F_%T')" --tags D
  echo_color "📸 Snapshot créé." $VERT
}

# ---------- maj_clamav ----------
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

# ---------- check_ssd ----------
unalias check_ssd 2>/dev/null
check_ssd() {
  local DEV="${1:-/dev/sda}"
  echo_color "🔍 SMART pour $DEV" $BLEU
  sudo smartctl -a "$DEV" | less
}

# ---------- nettoyer_logs ----------
unalias nettoyer_logs 2>/dev/null
nettoyer_logs() {
  sudo journalctl --vacuum-time=7d
  echo_color "🧹 Journaux >7 jours supprimés." $VERT
}

# ---------- docker_mise_a_jour ----------
unalias docker_mise_a_jour 2>/dev/null
docker_mise_a_jour() {
  echo_color "🔍 Nettoyage des conteneurs Docker..." $CYAN
  docker container prune -f
  docker image prune -a -f
  echo_color "✅ Docker nettoyé." $VERT
}

# ---------- analyse_disque ----------
unalias analyse_disque 2>/dev/null
analyse_disque() {
  echo_color "== Vue d'ensemble des périphériques (lsblk) ==" $CYAN
  lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINT -e7

  echo_color "
== Étiquettes & UUID (blkid) ==" $CYAN
  sudo blkid | sort

  echo_color "
== Occupation des systèmes de fichiers (df -hT) ==" $CYAN
  df -hT

  echo_color "
== Statut volumes chiffrés (cryptsetup) ==" $CYAN
  for map in $(ls /dev/mapper 2>/dev/null | grep -v control); do
    sudo cryptsetup status "$map" || true
    echo "---"
  done
}
