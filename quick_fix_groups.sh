#!/bin/bash
# Fix rapide pour les groupes davfs2

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_color() {
    echo -e "${2}${1}${NC}"
}

echo_color "🔧 Correction des groupes davfs2" $BLUE

# Ajouter au groupe davfs2
sudo usermod -a -G davfs2 $USER

echo_color "✅ Utilisateur ajouté au groupe davfs2" $GREEN
echo_color "📋 Groupes actuels:" $BLUE
groups

echo_color "\n💡 Pour activer le nouveau groupe:" $YELLOW
echo_color "   newgrp davfs2" $YELLOW
echo_color "   OU redémarrez votre session" $YELLOW

echo_color "\n🧪 Test après activation du groupe:" $YELLOW
echo_color "   ./test_mount_kdrive.sh" $YELLOW