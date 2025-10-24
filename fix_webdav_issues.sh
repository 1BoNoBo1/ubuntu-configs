#!/bin/bash
# ============================================================
# Script : fix_webdav_issues.sh
# Objectif : Corriger les problèmes de configuration WebDAV
# Usage : sudo ./fix_webdav_issues.sh
# ============================================================

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_color() {
    echo -e "${2}${1}${NC}"
}

if [[ "$EUID" -ne 0 ]]; then
    echo_color "Ce script doit être exécuté avec sudo" $RED
    exit 1
fi

UTILISATEUR="${SUDO_USER:-$(logname)}"
USER_HOME="/home/$UTILISATEUR"

echo_color "🔧 Correction des problèmes WebDAV pour l'utilisateur: $UTILISATEUR" $BLUE

# 1. Remplacer le script kdrive-mount défaillant
echo_color "📜 Mise à jour du script kdrive-mount..." $YELLOW
cp /tmp/kdrive-mount-fixed /usr/local/bin/kdrive-mount
chmod +x /usr/local/bin/kdrive-mount
chown root:root /usr/local/bin/kdrive-mount

echo_color "✅ Script kdrive-mount corrigé" $GREEN

# 2. Vérifier la configuration des credentials
SECRETS_FILE="$USER_HOME/.davfs2/secrets"
if [[ ! -f "$SECRETS_FILE" ]]; then
    echo_color "⚠️  Fichier secrets manquant. Création du répertoire..." $YELLOW
    mkdir -p "$USER_HOME/.davfs2"
    chown "$UTILISATEUR":"$UTILISATEUR" "$USER_HOME/.davfs2"
    chmod 700 "$USER_HOME/.davfs2"

    echo_color "🔐 Veuillez reconfigurer vos credentials:" $BLUE
    echo_color "   1. Nom d'utilisateur Infomaniak (email):" $YELLOW
    read -p "   Email: " KDRIVE_USERNAME
    read -s -p "   Mot de passe: " KDRIVE_PASSWORD
    echo

    cat > "$SECRETS_FILE" <<EOF
# Configuration WebDAV pour Infomaniak kDrive
https://connect.drive.infomaniak.com/remote.php/dav/files/${KDRIVE_USERNAME}/ ${KDRIVE_USERNAME} ${KDRIVE_PASSWORD}
EOF

    chmod 600 "$SECRETS_FILE"
    chown "$UTILISATEUR":"$UTILISATEUR" "$SECRETS_FILE"
    echo_color "✅ Credentials configurés" $GREEN
else
    echo_color "✅ Fichier secrets présent: $SECRETS_FILE" $GREEN
fi

# 3. Vérifier et corriger les permissions
echo_color "🔐 Vérification des permissions..." $YELLOW

# Ajouter l'utilisateur au groupe davfs2 si nécessaire
if ! groups "$UTILISATEUR" | grep -q davfs2; then
    usermod -a -G davfs2 "$UTILISATEUR"
    echo_color "✅ Utilisateur ajouté au groupe davfs2" $GREEN
else
    echo_color "✅ Utilisateur déjà dans le groupe davfs2" $GREEN
fi

# 4. Créer la structure de répertoires
SAUVEGARDE_DIR="$USER_HOME/SAUVEGARDE"
KDRIVE_MOUNT="$SAUVEGARDE_DIR/kdrive"

mkdir -p "$KDRIVE_MOUNT"
chown -R "$UTILISATEUR":"$UTILISATEUR" "$SAUVEGARDE_DIR"

echo_color "✅ Structure de répertoires corrigée" $GREEN

# 5. Tester la configuration
echo_color "🧪 Test de la configuration..." $BLUE

# Test du script
echo_color "Test du script kdrive-mount status..." $YELLOW
/usr/local/bin/kdrive-mount status

echo_color "\n🎉 Correction terminée!" $GREEN
echo_color "\n📋 Prochaines étapes:" $BLUE
echo_color "   1. Déconnectez-vous et reconnectez-vous (pour le groupe davfs2)" $YELLOW
echo_color "   2. Testez: kdrive-mount" $YELLOW
echo_color "   3. Vérifiez: kdrive-status" $YELLOW

echo_color "\n💡 Si le montage échoue encore:" $BLUE
echo_color "   sudo /usr/local/bin/kdrive-mount mount" $YELLOW