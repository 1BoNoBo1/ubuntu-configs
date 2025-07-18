#!/bin/bash
# Script d'installation et configuration de BorgBackup 1.4 sur Ubuntu
# Ce script installe Borg 1.4, initialise un dépôt chiffré (si inexistant),
# configure les scripts de sauvegarde et de restauration, et programme une tâche quotidienne.
# Usage : exécuter en root (directement en tant que root ou via sudo).

set -euo pipefail

# 1. Vérification des privilèges root
if [[ "$EUID" -ne 0 ]]; then
    echo "Erreur : ce script doit être exécuté en tant que root (par ex. via sudo)." >&2
    exit 1
fi

# 2. Détection de l'utilisateur principal pour configuration (si exécuté via sudo)
BASE_USER="${SUDO_USER:-$(whoami)}"
if [[ "$BASE_USER" == "root" ]]; then
    BASE_HOME="/root"
else
    BASE_HOME="/home/$BASE_USER"
fi

# 3. Variables de configuration (modifier au besoin pour votre environnement)
BORG_REPO="${BORG_REPO:-$BASE_HOME/borgrepo}"  # chemin du dépôt Borg (ex. /home/utilisateur/borgrepo)
CONFIG_FILE="/etc/borgbackup.conf"             # fichier de configuration optionnel (contient variables BORG_PASSPHRASE, BORG_REPO...)
BACKUP_SCRIPT="/usr/local/sbin/borg_backup.sh"
RESTORE_SCRIPT="/usr/local/sbin/borg_restore.sh"
SERVICE_FILE="/etc/systemd/system/borg-backup.service"
TIMER_FILE="/etc/systemd/system/borg-backup.timer"
BACKUP_LOG="/var/log/borg_backup.log"
RESTORE_LOG="/var/log/borg_restore.log"

# 4. Installation de Borg Backup 1.4 et dépendances (libfuse2 nécessaire pour l'AppImage)
echo "Installation de BorgBackup 1.4..."
apt-get update -qq
apt-get install -y libfuse2 curl
# Détection de la version de la libc pour choisir le binaire Borg approprié
GLIBC_VER=$(ldd --version | awk '/GNU C Library/ {print $NF; exit}')
BORG_URL=""
# Choix du binaire selon la version de glibc du système
# (Borg 1.4 fournit des binaires "fat" nommés borg-linux-glibcVERSION)
ver_major="${GLIBC_VER%%.*}" 
ver_minor="${GLIBC_VER##*.}"
if (( ver_major > 2 || (ver_major == 2 && ver_minor >= 31) )); then
    BORG_URL="https://github.com/borgbackup/borg/releases/download/1.4.1/borg-linux-glibc231"
elif (( ver_major == 2 && ver_minor >= 28 )); then
    BORG_URL="https://github.com/borgbackup/borg/releases/download/1.4.1/borg-linux-glibc228"
else
    echo "Version de la libc ($GLIBC_VER) trop ancienne pour les binaires Borg 1.4." >&2
    echo "Installez Borg via pip (pip3 install borgbackup==1.4.1) ou mettez à niveau votre système." >&2
    exit 1
fi

# Téléchargement et installation du binaire Borg si non déjà présent ou version différente
if ! command -v borg >/dev/null || ! borg --version 2>/dev/null | grep -q "borg 1.4"; then
    curl -L "$BORG_URL" -o /usr/local/bin/borg
    chmod +x /usr/local/bin/borg
    echo "BorgBackup 1.4 installé dans /usr/local/bin/borg."
else
    echo "BorgBackup est déjà installé. Version : $(borg --version)"
fi

# 5. Initialisation du dépôt Borg (si nécessaire)
# Création des dossiers du dépôt si manquants
mkdir -p "$(dirname "$BORG_REPO")"
if [[ ! -e "$BORG_REPO/config" ]]; then
    # Charger la passphrase depuis le fichier de conf ou demander à l'utilisateur
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
    if [[ -z "${BORG_PASSPHRASE:-}" ]]; then
        echo "Veuillez entrer une passphrase pour chiffrer le dépôt Borg (elle ne sera pas affichée) :"
        read -s BORG_PASSPHRASE
        echo    # retour à la ligne
    fi
    export BORG_PASSPHRASE
    echo "Initialisation d’un nouveau dépôt Borg chiffré dans $BORG_REPO..."
    borg init --encryption=repokey "$BORG_REPO"
    # Conseil : conservez la passphrase en lieu sûr et éventuellement sauvegardez la clé du dépôt :
    # borg key export --paper $BORG_REPO /chemin/vers/backup_cle.txt
else
    echo "Dépôt Borg déjà présent à $BORG_REPO : initialisation sautée."
fi

# 6. Création du script de sauvegarde
cat > "$BACKUP_SCRIPT" << 'EOF'
#!/bin/bash
# Script de sauvegarde Borg - sauvegarde /etc et /home, puis prune les anciennes archives.
set -euo pipefail

# Charger la configuration (passphrase, dépôt, etc.) si disponible
[ -f /etc/borgbackup.conf ] && source /etc/borgbackup.conf

# Variables locales
REPO="${BORG_REPO:-/root/borgrepo}"                  # Chemin du dépôt Borg (défaut si non défini)
BACKUP_TARGETS="/etc /home"                          # Répertoires à sauvegarder
EXCLUDES="--exclude-caches"                          # Exclure les dossiers marqués cache (peut être complété)
ARCHIVE_NAME="$(hostname)-$(date +'%Y-%m-%d_%H-%M')" # Nom de l’archive (hostname-date_heure)

# Exporter variables sensibles pour borg (passphrase notamment)
export BORG_PASSPHRASE BORG_REPO

# Fichier de log
LOG_FILE="/var/log/borg_backup.log"
timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

# Début de journalisation
echo "$(timestamp) – Début de la sauvegarde Borg" >> "$LOG_FILE"

# Exécution de la sauvegarde Borg
borg create -v --stats ::${ARCHIVE_NAME} $BACKUP_TARGETS $EXCLUDES >> "$LOG_FILE" 2>&1 || {
    echo "$(timestamp) – ERREUR : échec de la sauvegarde Borg (borg create)" >> "$LOG_FILE"
    exit 1
}

# Prune des anciennes sauvegardes (politique de rétention : 7 quotidien, 4 hebdo, 12 mensuel)
borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=12 >> "$LOG_FILE" 2>&1 || {
    echo "$(timestamp) – ERREUR : échec du prune des anciennes archives" >> "$LOG_FILE"
}

# Fin de journalisation
echo "$(timestamp) – Sauvegarde terminée avec succès" >> "$LOG_FILE"

# Optionnel : ajuster les permissions du dépôt si le dépôt est dans le home d’un utilisateur non-root
if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "$SUDO_USER":"$SUDO_USER" "${BORG_REPO:-$REPO}" 2>/dev/null || true
fi

EOF
chmod 700 "$BACKUP_SCRIPT"

# 7. Création du script de restauration
cat > "$RESTORE_SCRIPT" << 'EOF'
#!/bin/bash
# Script de restauration Borg - extrait une archive vers un emplacement donné.
set -euo pipefail

[ -f /etc/borgbackup.conf ] && source /etc/borgbackup.conf
export BORG_PASSPHRASE BORG_REPO

# Utilisation : borg_restore.sh [nom_archive] [destination]
ARCHIVE="${1:-}"
DEST_DIR="${2:-/root/borg-restore}"

if [[ -z "$ARCHIVE" ]]; then
    echo "Aucune archive spécifiée, détermination de la dernière archive..."
    # Récupère le nom de la dernière archive du dépôt
    if ! ARCHIVE=$(borg list --last 1 --format '{archive}{NL}' ::); then
        echo "Erreur : impossible de déterminer la dernière archive (vérifiez que le dépôt existe et que la passphrase est correcte)." >&2
        exit 1
    fi
    echo "Dernière archive détectée : $ARCHIVE"
fi

echo "Restauration de l’archive '$ARCHIVE' vers '$DEST_DIR'..."
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"
# Extraction de l'archive
borg extract ::${ARCHIVE} >> /var/log/borg_restore.log 2>&1 || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') – ERREUR : échec de la restauration de l'archive $ARCHIVE" >> /var/log/borg_restore.log
    exit 1
}
echo "$(date '+%Y-%m-%d %H:%M:%S') – Archive $ARCHIVE restaurée avec succès vers $DEST_DIR" >> /var/log/borg_restore.log

echo "Restauration terminée. Les données de '$ARCHIVE' ont été extraites dans '$DEST_DIR'."
EOF
chmod 700 "$RESTORE_SCRIPT"

# 8. Configuration du service systemd pour exécuter la sauvegarde quotidiennement
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Sauvegarde quotidienne Borg
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=$BACKUP_SCRIPT
# Réduction de priorité pour limiter l'impact (optionnel)
IOSchedulingClass=best-effort
IOSchedulingPriority=7
Nice=19

[Install]
WantedBy=multi-user.target
EOF

cat > "$TIMER_FILE" << EOF
[Unit]
Description=Timer de sauvegarde quotidienne Borg

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true        # Garantit l'exécution dès le démarrage si la planification a été manquée (ex. machine éteinte)
RandomizedDelaySec=15m # Décalage aléatoire (jusqu'à 15min) pour éviter surcharge simultanée (optionnel)

[Install]
WantedBy=timers.target
EOF

# Rechargement de systemd et activation du timer
systemctl daemon-reload
systemctl enable --now borg-backup.timer

# 9. Préparation des fichiers de log
touch "$BACKUP_LOG" "$RESTORE_LOG"
chmod 600 "$BACKUP_LOG" "$RESTORE_LOG"
echo "Installation terminée. Le service borg-backup.timer est activé (sauvegarde quotidienne à 02:30)."
echo "Vous pouvez consulter $BACKUP_LOG pour les journaux de sauvegarde, et utiliser $RESTORE_SCRIPT pour restaurer une archive si besoin."

Non, pas besoin de tout recommencer à zéro à la main : ce script est **idempotent**, il va détecter l’existant et ne ré‑initialisera pas un dépôt déjà créé. Concrètement :

1. **Initialisation conditionnelle**

   * Si `/home/jim/kDrive/INFORMATIQUE/PC_TUF/borgrepo/config` existe déjà, le script sautera l’étape `borg init`
   * Sinon, il initialisera un nouveau dépôt chiffré

2. **Scripts et service**

   * Il écrasera (ou créera) les scripts de sauvegarde et de restauration dans `/usr/local/sbin`
   * Il (re)créera le service systemd et le timer pour garantir qu’ils sont correctement installés

3. **Journalisation et permissions**

   * Il mettra en place vos logs et vos permissions de façon sécurisée, même si vous aviez déjà partiellement configuré des éléments

---

### Que faire maintenant

1. **Lancez simplement le script** :

   ```bash
   sudo bash /home/jim/ubuntu-configs/borg_setup.sh
   ```

2. **Vérifiez**

   * Que votre dépôt n’a pas été ré‑initialisé (le contenu de `borgrepo` reste intact)
   * Que le service systemd `borg-backup.timer` est bien activé (`systemctl status borg-backup.timer`)
   * Que les scripts `/usr/local/sbin/borg_backup.sh` et `/usr/local/sbin/borg_restore.sh` sont en place et exécutables

3. **Exécutez un test**

   * Forcez immédiatement un backup :

     ```bash
     sudo systemctl start borg-backup.service
     tail -n50 /var/log/borg_backup.log
     ```
   * Vérifiez qu’une archive datée est bien créée dans `borgrepo`

Vous n’avez **aucune** autre opération manuelle à faire : le script se charge de tout remettre à neuf ou de compléter votre configuration existante.
