#!/bin/bash
# ------------------------------------------------------------
# Script : borg_setup.sh
# Objectif : Installer et configurer Borg Backup avec systemd
#            Dépôt chiffré local dans un dossier synchronisé avec kDrive
# Usage : sudo ./borg_setup.sh [chemin/vers/repo/local]
# Compatibilité : Ubuntu ≥ 24.04 / Debian ≥ 12
# Auteur : Jean BoNoBo - 2025
# ------------------------------------------------------------
set -euo pipefail

# Chemin relatif par défaut pour le dépôt Borg dans le home de l'utilisateur
CHEMIN_RELATIF_DEF="kDrive/INFORMATIQUE/PC_TUF"
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

creer_fichier_excludes() {
  EXCLUDES="/etc/borg_excludes.txt"
  if [ ! -f "$EXCLUDES" ]; then
    cat > "$EXCLUDES" <<'EOF'
# Exclusions recommandées pour Borg
/home/*/.cache
*.tmp
/var/tmp
# Ajoute ici tes propres règles d'exclusion
EOF
    chmod 644 "$EXCLUDES"
    echo "Fichier d'exclusion créé à : $EXCLUDES"
  else
    echo "Fichier d'exclusion déjà présent à : $EXCLUDES"
  fi
}

preparer_dossiers() {
  CHEMIN_KDRIVE="$DOSSIER_HOME/$CHEMIN_RELATIF"
  DEPOT_BORG="$CHEMIN_KDRIVE/borgrepo"
  # Vérifie que kDrive est bien monté/synchronisé
  if [ ! -d "$CHEMIN_KDRIVE" ]; then
    echo "Le dossier $CHEMIN_KDRIVE n’existe pas ou n’est pas monté/synchronisé. Vérifie la synchronisation kDrive avant de continuer." >&2
    exit 1
  fi
  mkdir -p "$DEPOT_BORG"
  chown -R "$UTILISATEUR":"$UTILISATEUR" "$CHEMIN_KDRIVE"
  chmod 700 "$DEPOT_BORG"
  FICHIER_LOG="/var/log/borg_backup.log"
  FICHIER_RESTORE_LOG="/var/log/borg_restore.log"
}

initialiser_depot() {
  FICHIER_CONF="/etc/borgbackup.conf"
  if [[ ! -f "$DEPOT_BORG/config" ]]; then
    read -r -s -p "Passphrase Borg : " PASSPHRASE; echo
    read -r -s -p "Confirmez : " CONFIRM; echo
    if [[ "$PASSPHRASE" != "$CONFIRM" ]]; then
      echo "Les passphrases ne correspondent pas." >&2
      exit 1
    fi
    printf 'BORG_PASSPHRASE="%s"\nBORG_REPO="%s"\nCHEMIN_KDRIVE="%s"\n' "$PASSPHRASE" "$DEPOT_BORG" "$CHEMIN_KDRIVE" > "$FICHIER_CONF"
    chmod 600 "$FICHIER_CONF"
    # shellcheck source=/etc/borgbackup.conf
    source "$FICHIER_CONF"
    export BORG_PASSPHRASE BORG_REPO CHEMIN_KDRIVE
    sudo -u "$UTILISATEUR" borg init --encryption=repokey "$DEPOT_BORG"
    echo "Dépôt Borg initialisé dans $DEPOT_BORG"
  else
    if [[ -f "$FICHIER_CONF" ]]; then
      # shellcheck source=/etc/borgbackup.conf
      source "$FICHIER_CONF"
      export BORG_PASSPHRASE BORG_REPO CHEMIN_KDRIVE
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
if [ ! -f /etc/borgbackup.conf ]; then
  echo "Fichier de configuration Borg manquant (/etc/borgbackup.conf)." >&2
  exit 1
fi
source /etc/borgbackup.conf
export BORG_REPO BORG_PASSPHRASE CHEMIN_KDRIVE
LOG="/var/log/borg_backup.log"

horodatage() { date '+%Y-%m-%d %H:%M:%S'; }

echo "\$(horodatage) - Démarrage backup" >> "\$LOG"
if [ ! -d "\$CHEMIN_KDRIVE" ] || [ -z "\$(ls -A "\$CHEMIN_KDRIVE")" ]; then
  echo "... n'existe pas ou vide ..." >> "\$LOG"
  exit 1
fi
borg create --verbose --stats --exclude "\$BORG_REPO" --exclude-from /etc/borg_excludes.txt \
  ::"\$(hostname)-\$(date +%F_%H%M)" /home /etc >> "\$LOG" 2>&1 || {
  echo "\$(horodatage) - Erreur borg create" >> "\$LOG"
  exit 1
}

borg prune --list --glob-archives "\$(hostname)-" --keep-daily=7 --keep-weekly=4 --keep-monthly=12 >> "\$LOG" 2>&1 || {
  echo "\$(horodatage) - Erreur borg prune" >> "\$LOG"
}

chown -R "$UTILISATEUR":"$UTILISATEUR" "\$BORG_REPO" 2>/dev/null || true

echo "\$(horodatage) - Sauvegarde terminée" >> "\$LOG"
EOS
  chmod 700 /usr/local/sbin/borg_backup.sh
}

creer_script_restore() {
  cat > /usr/local/sbin/borg_restore.sh <<EOS
#!/bin/bash
set -euo pipefail
if [ ! -f /etc/borgbackup.conf ]; then
  echo "Fichier de configuration Borg manquant (/etc/borgbackup.conf)." >&2
  exit 1
fi
source /etc/borgbackup.conf
export BORG_REPO BORG_PASSPHRASE CHEMIN_KDRIVE
LOG="/var/log/borg_restore.log"

ARCHIVE="\${1:-}"
DEST="\${2:-\$HOME/borg-restore}"

if [[ -z "\$ARCHIVE" ]]; then
  echo "Usage : borg_restore.sh <archive> [destination]" >&2
  borg list "\$BORG_REPO"
  exit 1
fi

mkdir -p "\$DEST"

echo "\$(date '+%Y-%m-%d %H:%M:%S') - Restauration de \$ARCHIVE" >> "\$LOG"

borg extract "\$BORG_REPO::\$ARCHIVE" --target "\$DEST" >> "\$LOG" 2>&1

echo "\$(date '+%Y-%m-%d %H:%M:%S') - Restauration terminée" >> "\$LOG"
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
User=$UTILISATEUR
Environment="BORG_PASSPHRASE=$BORG_PASSPHRASE"
Environment="BORG_REPO=$DEPOT_BORG"
Environment="CHEMIN_KDRIVE=$CHEMIN_KDRIVE"
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
  chown "$UTILISATEUR":"$UTILISATEUR" "$FICHIER_LOG" "$FICHIER_RESTORE_LOG"
}

verifier_borg_installation() {
    echo "=== Vérification de l'installation BorgBackup ==="

    echo "[1/6] 📁 Vérification des fichiers principaux..."
    fichiers=(/etc/borgbackup.conf /usr/local/sbin/borg_backup.sh /usr/local/sbin/borg_restore.sh /etc/systemd/system/borg-backup.service /etc/systemd/system/borg-backup.timer)
    for fichier in "${fichiers[@]}"; do
        if [ -f "$fichier" ]; then
            echo "✅ Fichier présent : $fichier"
        else
            echo "❌ Fichier manquant : $fichier"
        fi
    done

    echo "[2/6] 📄 Vérification du contenu de /etc/borgbackup.conf..."
    if [ -f /etc/borgbackup.conf ]; then
        source /etc/borgbackup.conf
        if [[ -z "$BORG_PASSPHRASE" || -z "$BORG_REPO" || -z "$CHEMIN_KDRIVE" ]]; then
            echo "❌ Variables manquantes dans le fichier de conf."
        else
            echo "✅ Variables détectées : BORG_REPO=$BORG_REPO"
        fi
    else
        echo "❌ Fichier /etc/borgbackup.conf introuvable."
    fi

    echo "[3/6] 📦 Vérification de l'état du dépôt Borg..."
    if borg info "$BORG_REPO" &>/dev/null; then
        echo "✅ Dépôt Borg lisible : $BORG_REPO"
    else
        echo "❌ Impossible de lire le dépôt Borg : $BORG_REPO"
    fi

    echo "[4/6] ⏲️ Vérification de la planification systemd..."
    if systemctl is-active --quiet borg-backup.timer; then
        echo "✅ Le timer systemd est actif."
        systemctl list-timers | grep borg
    else
        echo "❌ Le timer systemd n’est pas actif."
    fi

    echo "[5/6] 📚 Vérification des archives existantes..."
    if borg list "$BORG_REPO" | tail -n 1; then
        echo "✅ Archive trouvée dans le dépôt."
    else
        echo "❌ Aucune archive trouvée dans le dépôt."
    fi

    echo "[6/6] 🧾 Vérification du log de sauvegarde..."
    if sudo tail -n 30 /var/log/borg_backup.log | grep -iE "error|failed"; then
        echo "❌ Des erreurs détectées dans /var/log/borg_backup.log"
    else
        echo "✅ Aucun message d’erreur détecté dans le log."
    fi

    echo "=== Fin de la vérification ==="

    echo
    echo "ℹ️ Tu peux maintenant lancer manuellement une sauvegarde ou une restauration pour tester :"
    echo "🔹 Pour lancer une sauvegarde :    sudo /usr/local/sbin/borg_backup.sh"
    echo "🔹 Pour voir les archives :        borg list \"$BORG_REPO\""
    echo "🔹 Pour restaurer (exemple) :      sudo /usr/local/sbin/borg_restore.sh NOM_ARCHIVE /tmp/test-restore"
}

# --------- Exécution ---------
verifier_root
installer_borg
creer_fichier_excludes
preparer_dossiers
initialiser_depot
creer_script_backup
creer_script_restore
creer_service_systemd
initialiser_logs
verifier_borg_installation
echo "Borg Backup a été installé et configuré avec succès."
echo "Le dépôt Borg est situé dans : $DEPOT_BORG"
echo "Les scripts de sauvegarde et de restauration sont disponibles dans /usr/local/sbin/"
echo "Le fichier de configuration est situé dans /etc/borgbackup.conf"
echo "Les logs de sauvegarde sont dans /var/log/borg_backup.log"
echo "Pour vérifier l'état du service, utilisez : systemctl status borg-backup.service"
echo "Pour vérifier l'état du timer, utilisez : systemctl status borg-backup.timer"
# creation des aliaas pour borg s'ils ne sont pas present dans aliases.sh
if ! grep -q "alias borg-backup-now" "$HOME/.mon_shell/aliases.sh"; then
  echo "Création des alias Borg dans ~/.mon_shell/aliases.sh"
  echo "alias borg-backup-now='sudo systemctl start borg-backup.service'" >> "$HOME/.mon_shell/aliases.sh"
  echo "alias borg-backup-log='sudo tail -n 50 /var/log/borg_backup.log'" >> "$HOME/.mon_shell/aliases.sh"
  echo "alias borg-list='borg list /home/jim/kDrive/INFORMATIQUE/PC_TUF/borgrepo'" >> "$HOME/.mon_shell/aliases.sh"
  echo "alias borg-restore-last='LATEST=\$(borg list /home/jim/kDrive/INFORMATIQUE/PC_TUF/borgrepo --format=\"{archive}\\n\" | tail -n1) && sudo /usr/local/sbin/borg_restore.sh \"\$LATEST\"'" >> "$HOME/.mon_shell/aliases.sh"
  echo "alias borg-check-timer='systemctl status borg-backup.timer'" >> "$HOME/.mon_shell/aliases.sh"
  echo "alias borg-check-repo='ls -ld /home/jim/kDrive/INFORMATIQUE/PC_TUF/borgrepo'" >> "$HOME/.mon_shell/aliases.sh"
  echo "Les alias Borg ont été ajoutés à ~/.mon_shell/aliases.sh"
  source "$HOME/.mon_shell/aliases.sh"
else
  echo "Les alias Borg sont déjà présents dans ~/.mon_shell/aliases.sh"
fi
echo "Pour recharger les alias, exécutez : source ~/.mon_shell/aliases.sh"
echo "Pour lancer une sauvegarde manuelle, utilisez : borg-backup-now"
echo "Pour consulter le log de la dernière sauvegarde, utilisez : borg-backup-log"
echo "Pour lister les archives, utilisez : borg-list"
echo "Pour restaurer la dernière archive, utilisez : borg-restore-last"
echo "Pour vérifier l'état du timer, utilisez : borg-check-timer"
echo "Pour vérifier le dépôt, utilisez : borg-check-repo"
echo "Pour plus d'informations, consultez la documentation de Borg Backup : https://borgbackup.readthedocs.io/en/stable/"
echo "Bonne sauvegarde !"
echo "N'oublie pas de vérifier régulièrement tes sauvegardes et de tester les restaurations !"
echo "By 1BoNoBo1 - 2025"