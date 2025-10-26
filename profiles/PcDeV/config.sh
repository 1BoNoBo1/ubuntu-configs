#!/bin/bash
# ==============================================================================
# Profil : PcDeV (Ultraportable)
# Description : Configuration optimisée pour PC ultraportable
# Mode Adaptatif : MINIMAL
# ==============================================================================

# Informations du profil
export PROFILE_NAME="PcDeV"
export PROFILE_TYPE="laptop"
export PROFILE_MODE="MINIMAL"

# Couleurs pour les messages
source ~/ubuntu-configs/mon_shell/colors.sh 2>/dev/null || {
    VERT='\033[0;32m'
    BLEU='\033[0;34m'
    JAUNE='\033[1;33m'
    NC='\033[0m'
}

echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${VERT}💻 Profil PcDeV (Ultraportable) - Mode MINIMAL${NC}"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ==========================================
# Configuration Système Adaptative
# ==========================================

# Force le mode MINIMAL pour économiser les ressources
export FORCE_ADAPTIVE_MODE="MINIMAL"

# ==========================================
# Modules Essentiels Uniquement
# ==========================================

# Charger uniquement les modules essentiels pour économiser la RAM
MODULES_PCDEV=(
    "utilitaires_systeme.sh:Utilitaires système de base"
    "outils_fichiers.sh:Gestion de fichiers"
    "aide_memoire.sh:Aide rapide"
    "raccourcis_pratiques.sh:Navigation rapide"
)

echo "   📦 Modules: Essentiels uniquement (économie mémoire)"

# ==========================================
# Optimisations Batterie et Performance
# ==========================================

# Historique réduit pour économiser la mémoire
export HISTSIZE=1000
export HISTFILESIZE=2000

# Éditeur léger
export EDITOR="nano"
export VISUAL="nano"

# ==========================================
# Alias Spécifiques Ultraportable
# ==========================================

# Gestion batterie
alias battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E 'state|percentage|time'"
alias bat="battery"

# Économie d'énergie
alias wifi-off="nmcli radio wifi off && echo '📡 WiFi désactivé'"
alias wifi-on="nmcli radio wifi on && echo '📡 WiFi activé'"
alias bt-off="bluetoothctl power off && echo '🔵 Bluetooth désactivé'"
alias bt-on="bluetoothctl power on && echo '🔵 Bluetooth activé'"

# Luminosité rapide
alias bright-low="brightnessctl set 30% && echo '💡 Luminosité: 30%'"
alias bright-med="brightnessctl set 60% && echo '💡 Luminosité: 60%'"
alias bright-high="brightnessctl set 100% && echo '💡 Luminosité: 100%'"

# Monitoring léger
alias cpu="top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print \"CPU: \" 100 - \$1\"%\"}'"
alias mem="free -h | awk '/^Mem:/ {print \"RAM: \"\$3\" / \"\$2}'"
alias temp="sensors 2>/dev/null | grep -i 'core 0' | awk '{print \"CPU: \"\$3}' || echo 'sensors non installé'"

# Raccourcis essentiels
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"

# ==========================================
# Fonctions Spécifiques Ultraportable
# ==========================================

# Fonction pour afficher le statut de la batterie détaillé
battery-status() {
    echo "🔋 Statut Batterie - PcDeV"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if command -v upower &>/dev/null; then
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|time to|energy-rate" | while read line; do
            echo "  $line"
        done
    else
        cat /sys/class/power_supply/BAT0/capacity 2>/dev/null | awk '{print "  Charge: "$1"%"}' || echo "  Informations batterie non disponibles"
    fi
}

# Fonction de monitoring système ultra-léger
quick-status() {
    echo "⚡ Statut Rapide - PcDeV"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # CPU
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  CPU: " 100 - $1"%"}'

    # RAM
    free -h | awk '/^Mem:/ {print "  RAM: "$3" / "$2}'

    # Disque
    df -h / | awk 'NR==2 {print "  Disque: "$3" / "$2" ("$5")"}'

    # Batterie (si portable)
    if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
        local bat=$(cat /sys/class/power_supply/BAT0/capacity)
        echo "  🔋 Batterie: ${bat}%"
    fi

    # WiFi
    if nmcli radio wifi | grep -q "enabled"; then
        echo "  📡 WiFi: Activé"
    else
        echo "  📡 WiFi: Désactivé"
    fi
}

# Mode économie d'énergie maximale
eco-mode() {
    echo "🌿 Activation Mode Économie..."

    # Réduire luminosité
    if command -v brightnessctl &>/dev/null; then
        brightnessctl set 30% &>/dev/null
        echo "  ✅ Luminosité: 30%"
    fi

    # Désactiver Bluetooth si non utilisé
    if ! bluetoothctl devices | grep -q "Device"; then
        bluetoothctl power off &>/dev/null
        echo "  ✅ Bluetooth: Désactivé"
    fi

    echo "  🌿 Mode économie activé"
}

# Mode performance (pour travail intensif sur secteur)
perf-mode() {
    echo "⚡ Activation Mode Performance..."

    # Augmenter luminosité
    if command -v brightnessctl &>/dev/null; then
        brightnessctl set 80% &>/dev/null
        echo "  ✅ Luminosité: 80%"
    fi

    # Activer WiFi et Bluetooth
    nmcli radio wifi on &>/dev/null
    bluetoothctl power on &>/dev/null
    echo "  ✅ WiFi et Bluetooth: Activés"

    echo "  ⚡ Mode performance activé"
}

# Note: Les fonctions sont disponibles sans export dans les fichiers sourcés
# Export -f retiré pour des raisons de sécurité (risque d'hijacking)

# ==========================================
# Auto-détection Mode Batterie/Secteur
# ==========================================

# Fonction pour détecter si on est sur batterie
on_battery() {
    if [[ -f /sys/class/power_supply/AC/online ]]; then
        [[ $(cat /sys/class/power_supply/AC/online) == "0" ]]
    else
        return 1
    fi
}

# Message si sur batterie
if on_battery; then
    echo -e "${JAUNE}   ⚠️  Sur batterie - Mode économie recommandé (eco-mode)${NC}"
fi

# ==========================================
# Messages de Bienvenue
# ==========================================

echo "   🔋 Mode: MINIMAL (optimisé batterie)"
echo "   💾 Modules: Essentiels uniquement"
echo "   📊 Commandes spéciales:"
echo "      • battery / bat      : Statut batterie"
echo "      • quick-status       : Statut système rapide"
echo "      • eco-mode           : Mode économie d'énergie"
echo "      • perf-mode          : Mode performance"
echo "      • wifi-on/off        : Gestion WiFi"
echo "      • bt-on/off          : Gestion Bluetooth"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
