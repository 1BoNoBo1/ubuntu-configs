#!/bin/bash
# ------------------------------------------------------------
# Script : borg_setup.sh
# Objectif : Installer et configurer Borg Backup avec systemd
#             Dépôt chiffré local dans kDrive
# Compatible : Ubuntu/Debian
# ------------------------------------------------------------
set -euo pipefail

# Chemin relatif par défaut pour le dépôt Borg dans le home de l'utilisateur
CHEMIN_RELATIF_DEF="kDrive/INFORMATIQUE/PC_TUF"
# Permettre la personnalisation via un argument optionnel
CHEMIN_RELATIF="${1:-$CHEMIN_RELATIF_DEF}"

# -------- Fonctions utilitaires --------

verifier_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Erreur : ce script doit être exécuté en tant que root (sudo)." >&2
    exit 1
  fi
  if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" = "root" ]]; then
    echo "Veuillez lancer ce script en tant qu'utilisateur normal via sudo." >&2
    exit 1
  fi
  UTILISATEUR="$SUDO_USER"
  DOSSIER_HOME="/home/$UTILISATEUR"
}

installer_borg() {
  apt-get update -qq
  apt-get install -y libfuse2 borgbackup >/dev/null
}

preparer_dossiers() {
  # Dossier qui contiendra le dépôt Borg
  CHEMIN_KDRIVE="$DOSSIER_HOME/$CHEMIN_RELATIF"
  DEPOT_BORG="$CHEMIN_KDRIVE/borgrepo"
  mkdir -p "$DEPOT_BORG"
  chown -R "$UTILISATEUR":"$UTILISATEUR" "$CHEMIN_KDRIVE"
  chmod 700 "$DEPOT_BORG"
}
  FICHIER_LOG="/var/log/borg_backup.log"
  FICHIER_RESTORE_LOG="/var/log/borg_restore.log"

initialiser_depot() {
  FICHIER_CONF="/etc/borgbackup.conf"
  if [[ ! -f "$DEPOT_BORG/config" ]]; then
    read -r -s -p "Passphrase Borg : " PASSPHRASE; echo
    read -r -s -p "Confirmez : " CONFIRM; echo
    if [[ "$PASSPHRASE" != "$CONFIRM" ]]; then
      echo "Les passphrases ne correspondent pas." >&2
      exit 1
    fi
    printf 'BORG_PASSPHRASE="%s"\nBORG_REPO="%s"\n' "$PASSPHRASE" "$DEPOT_BORG" > "$FICHIER_CONF"
    chmod 600 "$FICHIER_CONF"
    # shellcheck source=/etc/borgbackup.conf
    source "$FICHIER_CONF"
    export BORG_PASSPHRASE BORG_REPO
    borg init --encryption=repokey "$DEPOT_BORG"
    echo "Dépôt Borg initialisé dans $DEPOT_BORG"
  else
    if [[ -f "$FICHIER_CONF" ]]; then
      # shellcheck source=/etc/borgbackup.conf
      source "$FICHIER_CONF"
      export BORG_PASSPHRASE BORG_REPO
    else
      echo "Configuration $FICHIER_CONF manquante." >&2
      exit 1
    fi
  fi
}

creer_script_backup() {
  cat > /usr/local/sbin/borg_backup.sh <<EOS
#!/bin/bash
set -euo pipefail
# shellcheck source=/etc/borgbackup.conf
source /etc/borgbackup.conf
export BORG_REPO BORG_PASSPHRASE
LOG="/var/log/borg_backup.log"
CHEMIN_KDRIVE="$CHEMIN_KDRIVE"

horodatage() { date '+%Y-%m-%d %H:%M:%S'; }

echo "$(horodatage) - Démarrage backup" >> "$LOG"
if ! mountpoint -q "$CHEMIN_KDRIVE"; then
  echo "$(horodatage) - Erreur : $CHEMIN_KDRIVE non monté" >> "$LOG"
  exit 1
fi
borg create --verbose --stats --exclude "$BORG_REPO" \
  ::"$(hostname)-$(date +%F_%H%M)" /home /etc >> "$LOG" 2>&1 || {
  echo "$(horodatage) - Erreur borg create" >> "$LOG"
  exit 1
}

borg prune --list --prefix "$(hostname)-" --keep-daily=7 --keep-weekly=4 --keep-monthly=12 >> "$LOG" 2>&1 || {
  echo "$(horodatage) - Erreur borg prune" >> "$LOG"
}

chown -R '$UTILISATEUR':'$UTILISATEUR' "$BORG_REPO" 2>/dev/null || true

echo "$(horodatage) - Sauvegarde terminée" >> "$LOG"
EOS
  chmod 700 /usr/local/sbin/borg_backup.sh
}

creer_script_restore() {
  cat > /usr/local/sbin/borg_restore.sh <<EOS
#!/bin/bash
set -euo pipefail
# shellcheck source=/etc/borgbackup.conf
source /etc/borgbackup.conf
export BORG_REPO BORG_PASSPHRASE
LOG="/var/log/borg_restore.log"

ARCHIVE="${1:-}"
DEST="${2:-$HOME/borg-restore}"

if [[ -z "$ARCHIVE" ]]; then
  echo "Usage : borg_restore.sh <archive> [destination]" >&2
  borg list "$BORG_REPO"
  exit 1
fi

mkdir -p "$DEST"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Restauration de $ARCHIVE" >> "$LOG"

borg extract "$BORG_REPO::$ARCHIVE" --target "$DEST" >> "$LOG" 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') - Restauration terminée" >> "$LOG"
EOS
  chmod 700 /usr/local/sbin/borg_restore.sh
}

creer_service_systemd() {
  cat > /etc/systemd/system/borg-backup.service <<EOS
[Unit]
Description=Sauvegarde Borg quotidienne
Wants=network-online.target
After=network-online.target
RequiresMountsFor=$CHEMIN_KDRIVE

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/borg_backup.sh
Nice=19
IOSchedulingClass=idle
EOS

  cat > /etc/systemd/system/borg-backup.timer <<EOS
[Unit]
Description=Planification de la sauvegarde Borg

[Timer]
OnCalendar=*-*-* 02:30:00
RandomizedDelaySec=5m
Persistent=true

[Install]
WantedBy=timers.target
EOS

  systemctl daemon-reload
  systemctl enable --now borg-backup.timer
}

initialiser_logs() {
  touch "$FICHIER_LOG" "$FICHIER_RESTORE_LOG"
  chmod 600 "$FICHIER_LOG" "$FICHIER_RESTORE_LOG"
}

# --------- Exécution ---------
verifier_root
installer_borg
preparer_dossiers
initialiser_depot
creer_script_backup
creer_script_restore
creer_service_systemd
initialiser_logs

echo "Installation terminée. Le dépôt est situé dans $DEPOT_BORG"
echo "Le timer systemd \`borg-backup.timer\` est activé."
