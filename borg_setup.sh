#!/bin/bash
# /home/jim/ubuntu-configs/borg_setup.sh
# Installation et configuration automatisée de Borg Backup 1.4 sur Ubuntu
# Dépôt Borg chiffré (repokey) dans kDrive + scripts backup/restore + service systemd

set -euo pipefail

# 1) Vérification des privilèges root
if [[ "$EUID" -ne 0 ]]; then
  echo "Erreur : ce script doit être exécuté en tant que root." >&2
  exit 1
fi

# 2) Détection de l'utilisateur non-root à l'origine (pour permissions)
BASE_USER="${SUDO_USER:-$(whoami)}"
BASE_HOME="/home/$BASE_USER"

# 3) Variables de configuration (à adapter si nécessaire)
KDRIVE_PATH="$BASE_HOME/kDrive/INFORMATIQUE/PC_TUF"
BORG_REPO="$KDRIVE_PATH/borgrepo"
BACKUP_SCRIPT="/usr/local/sbin/borg_backup.sh"
RESTORE_SCRIPT="/usr/local/sbin/borg_restore.sh"
SERVICE_FILE="/etc/systemd/system/borg-backup.service"
TIMER_FILE="/etc/systemd/system/borg-backup.timer"
BACKUP_LOG="/var/log/borg_backup.log"
RESTORE_LOG="/var/log/borg_restore.log"
CONFIG_FILE="/etc/borgbackup.conf"

# 4) Installation des dépendances et de Borg via apt
apt-get update -qq
apt-get install -y libfuse2 borgbackup

# 5) Préparation du dépôt Borg
if [[ ! -d "$KDRIVE_PATH" ]]; then
  echo "ERREUR: dossier kDrive introuvable: $KDRIVE_PATH" >&2
  exit 1
fi
dirname "$BORG_REPO" | xargs mkdir -p
chown "$BASE_USER":"$BASE_USER" "$KDRIVE_PATH"
mkdir -p "$BORG_REPO"
chown "$BASE_USER":"$BASE_USER" "$BORG_REPO"
chmod 700 "$BORG_REPO"

# 6) Gestion interactive de la passphrase et initialisation du dépôt
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Aucun fichier de configuration trouvé, initialisation interactive de la passphrase."
  read -s -p "Entrez la passphrase Borg (elle sera stockée en /etc/borgbackup.conf) : " BORG_PASSPHRASE
  echo
  # Enregistrer la passphrase en lieu sûr
  echo "BORG_PASSPHRASE=\"$BORG_PASSPHRASE\"" > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
fi
# Charger la passphrase
source "$CONFIG_FILE"
export BORG_PASSPHRASE

# Initialisation conditionnelle du dépôt
if [[ ! -f "$BORG_REPO/config" ]]; then
  borg init --encryption=repokey "$BORG_REPO"
  echo "Dépôt Borg initialisé dans $BORG_REPO."
else
  echo "Dépôt Borg existant détecté, initialisation ignorée."
fi

# 7) Création du script de sauvegarde
cat > "$BACKUP_SCRIPT" << 'EOF'
#!/bin/bash
set -euo pipefail

# Chargement config
[[ -f /etc/borgbackup.conf ]] && source /etc/borgbackup.conf
export BORG_REPO BORG_PASSPHRASE
LOG_FILE="/var/log/borg_backup.log"
timestamp(){ date '+%Y-%m-%d %H:%M:%S'; }

echo "$(timestamp) Début sauvegarde Borg" >> "$LOG_FILE"

borg create --verbose --stats ::"$(hostname)-$(date +%F_%H%M)" /home /etc >> "$LOG_FILE" 2>&1 || {
  echo "$(timestamp) ERREUR lors de borg create" >> "$LOG_FILE"
  exit 1
}

borg prune --list --prefix "$(hostname)-" --keep-daily=7 --keep-weekly=4 --keep-monthly=12 >> "$LOG_FILE" 2>&1 || {
  echo "$(timestamp) ERREUR lors de borg prune" >> "$LOG_FILE"
}

if [[ -n "${SUDO_USER:-}" ]]; then
  chown -R "$SUDO_USER":"$SUDO_USER" "$BORG_REPO" 2>/dev/null || true
fi

echo "$(timestamp) Sauvegarde terminée" >> "$LOG_FILE"
EOF
chmod 700 "$BACKUP_SCRIPT"

# 8) Création du script de restauration
cat > "$RESTORE_SCRIPT" << 'EOF'
#!/bin/bash
set -euo pipefail

[[ -f /etc/borgbackup.conf ]] && source /etc/borgbackup.conf
export BORG_REPO BORG_PASSPHRASE
ARCHIVE="${1:-}"
DEST="${2:-$HOME/borg-restore}"

if [[ -z "$ARCHIVE" ]]; then
  echo "Liste des archives disponibles :"
  borg list "$BORG_REPO"
  echo "Usage : borg_restore.sh <archive> [destination]"
  exit 1
fi

echo "Restauration de $ARCHIVE vers $DEST"
mkdir -p "$DEST"
borg extract "$BORG_REPO::$ARCHIVE" --target "$DEST" >> "${RESTORE_LOG:-/var/log/borg_restore.log}" 2>&1
EOF
chmod 700 "$RESTORE_SCRIPT"

# 9) Configuration systemd + timer
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Borg Backup quotidien
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=$BACKUP_SCRIPT
Nice=19
EOF

cat > "$TIMER_FILE" << EOF
[Unit]
Description=Timer pour Borg Backup quotidien

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
RandomizedDelaySec=5m

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now borg-backup.timer

# 10) Préparer fichiers de log
touch "$BACKUP_LOG" "$RESTORE_LOG"
chmod 600 "$BACKUP_LOG" "$RESTORE_LOG"

# 11) Bilan
echo "✅ Installation terminée."
echo "Dépôt Borg : $BORG_REPO"
echo "Script backup : $BACKUP_SCRIPT"
echo "Script restore : $RESTORE_SCRIPT"
echo "Cron systemd : borg-backup.timer (02:30)"
echo "Consultez $BACKUP_LOG et $RESTORE_LOG pour les logs."
