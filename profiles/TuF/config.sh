#!/bin/bash
# ==============================================================================
# Profil : TuF (Desktop)
# Description : Configuration pour PC desktop TuF avec fix audio PipeWire
# Mode Adaptatif : PERFORMANCE
# ==============================================================================

# Informations du profil
export PROFILE_NAME="TuF"
export PROFILE_TYPE="desktop"
export PROFILE_MODE="PERFORMANCE"

# Couleurs pour les messages
source ~/ubuntu-configs/mon_shell/colors.sh 2>/dev/null || {
    VERT='\033[0;32m'
    BLEU='\033[0;34m'
    NC='\033[0m'
}

echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${VERT}🖥️  Profil TuF (Desktop) - Mode PERFORMANCE${NC}"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ==========================================
# Configuration Système Adaptative
# ==========================================

# Force le mode PERFORMANCE pour le système adaptatif
export FORCE_ADAPTIVE_MODE="PERFORMANCE"

# ==========================================
# Modules Spécifiques TuF
# ==========================================

# Charger tous les modules de productivité et développement
MODULES_TUF=(
    "utilitaires_systeme.sh:Utilitaires système complets"
    "outils_fichiers.sh:Gestion avancée de fichiers"
    "outils_productivite.sh:Outils de productivité"
    "outils_developpeur.sh:Outils développeur complets"
    "outils_reseau.sh:Diagnostics réseau"
    "outils_multimedia.sh:Traitement multimédia"
    "aide_memoire.sh:Système d'aide complet"
    "raccourcis_pratiques.sh:Navigation rapide"
    "nettoyage_securise.sh:Nettoyage sécurisé"
)

# ==========================================
# Configuration Audio Spécifique
# ==========================================

# Alias pour le fix audio PipeWire Bluetooth
alias fix-audio="bash ~/ubuntu-configs/profiles/TuF/scripts/fix_pipewire_bt.sh"
alias fix-bt-audio="fix-audio"
alias fix-pipewire="fix-audio"

# Auto-fix au démarrage (optionnel, commenté par défaut)
# bash ~/ubuntu-configs/profiles/TuF/scripts/fix_pipewire_bt.sh &>/dev/null &

echo "   🔊 Fix audio Bluetooth disponible: fix-audio"

# ==========================================
# Configuration Performance
# ==========================================

# Historique plus grand pour le développement
export HISTSIZE=10000
export HISTFILESIZE=20000

# Optimisations pour développement
export EDITOR="nano"
export VISUAL="nano"

# Activer toutes les fonctionnalités de complétion
if [[ -n "$BASH_VERSION" ]]; then
    shopt -s histappend
    shopt -s checkwinsize
    shopt -s cdspell
    shopt -s dirspell
fi

# ==========================================
# Alias Spécifiques Desktop
# ==========================================

# Raccourcis développement
alias dev="cd ~/Projets && ls -la"
alias projets="cd ~/Projets && ls -la"

# Outils système avancés
alias monitor="htop"
alias disk="df -h && echo && du -sh * 2>/dev/null | sort -h"
alias ports="sudo netstat -tulpn"

# Docker (si disponible)
if command -v docker &>/dev/null; then
    alias dps="docker ps -a"
    alias dim="docker images"
    alias dlog="docker logs -f"
fi

# Git avancé (pour le développement)
alias gs="git status -sb"
alias gl="git log --oneline --graph --decorate --all -10"
alias gd="git diff"

# ==========================================
# Fonctions Spécifiques TuF
# ==========================================

# Fonction pour redémarrer PipeWire manuellement
restart-pipewire() {
    echo "🔄 Redémarrage de PipeWire..."
    systemctl --user restart pipewire pipewire-pulse wireplumber
    echo "✅ PipeWire redémarré"
}

# Fonction pour vérifier le statut audio
status-audio() {
    echo "🔊 Statut Audio PipeWire:"
    echo ""
    systemctl --user status pipewire --no-pager | head -n 3
    echo ""
    pactl list sinks short 2>/dev/null
}

# Fonction de monitoring système complet
system-monitor() {
    echo "🖥️  Monitoring Système - TuF"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CPU:"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  Utilisation: " 100 - $1"%"}'
    echo ""
    echo "RAM:"
    free -h | awk '/^Mem:/ {print "  Utilisée: "$3" / "$2" ("$3/$2*100"%)"}'
    echo ""
    echo "Disque:"
    df -h / | awk 'NR==2 {print "  Utilisé: "$3" / "$2" ("$5")"}'
    echo ""
    echo "Température CPU:"
    sensors 2>/dev/null | grep -i "core 0" || echo "  sensors non installé"
}

# Note: Les fonctions sont disponibles sans export dans les fichiers sourcés
# Export -f retiré pour des raisons de sécurité (risque d'hijacking)

# ==========================================
# Messages de Bienvenue
# ==========================================

echo "   ⚡ Mode: PERFORMANCE (tous les outils chargés)"
echo "   🛠️  Outils développeur: disponibles"
echo "   📊 Commandes spéciales:"
echo "      • fix-audio          : Corriger audio Bluetooth"
echo "      • restart-pipewire   : Redémarrer PipeWire"
echo "      • status-audio       : Vérifier statut audio"
echo "      • system-monitor     : Monitoring système complet"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
