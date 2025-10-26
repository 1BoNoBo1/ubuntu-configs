#!/bin/bash
# ==============================================================================
# Profil : Default (Universel)
# Description : Configuration par défaut pour machines non identifiées
# Mode Adaptatif : STANDARD (détection automatique)
# ==============================================================================

# Informations du profil
export PROFILE_NAME="default"
export PROFILE_TYPE="universal"
export PROFILE_MODE="STANDARD"

# Couleurs pour les messages
source ~/ubuntu-configs/mon_shell/colors.sh 2>/dev/null || {
    VERT='\033[0;32m'
    BLEU='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
}

echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${VERT}🌐 Profil Default (Universel) - Mode STANDARD${NC}"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ==========================================
# Configuration Système Adaptative
# ==========================================

# Laisser le système adaptatif détecter automatiquement
# (pas de FORCE_ADAPTIVE_MODE, détection automatique)

# ==========================================
# Modules Standard
# ==========================================

# Charger un ensemble équilibré de modules
MODULES_DEFAULT=(
    "utilitaires_systeme.sh:Utilitaires système"
    "outils_fichiers.sh:Gestion de fichiers"
    "outils_productivite.sh:Outils de productivité"
    "aide_memoire.sh:Système d'aide"
    "raccourcis_pratiques.sh:Navigation rapide"
    "nettoyage_securise.sh:Nettoyage sécurisé"
)

echo "   📦 Modules: Configuration standard équilibrée"

# ==========================================
# Configuration Standard
# ==========================================

# Historique standard
export HISTSIZE=5000
export HISTFILESIZE=10000

# Éditeur par défaut
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"

# Options bash standard
if [[ -n "$BASH_VERSION" ]]; then
    shopt -s histappend
    shopt -s checkwinsize
fi

# ==========================================
# Alias Standard
# ==========================================

# Navigation
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."

# Sécurité
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Système
alias update="sudo apt update && sudo apt upgrade -y"
alias clean="sudo apt autoremove -y && sudo apt autoclean"
alias disk="df -h"
alias mem="free -h"

# Réseau
alias ping="ping -c 5"
alias myip="curl -s ifconfig.me && echo"

# ==========================================
# Fonctions Universelles
# ==========================================

# Fonction pour afficher les informations système
system-info() {
    echo "🖥️  Informations Système"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Hostname
    echo "  Machine: $(hostname)"

    # OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "  OS: $PRETTY_NAME"
    fi

    # Kernel
    echo "  Kernel: $(uname -r)"

    # CPU
    echo "  CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"

    # RAM
    local ram_total=$(free -h | awk '/^Mem:/{print $2}')
    local ram_used=$(free -h | awk '/^Mem:/{print $3}')
    echo "  RAM: $ram_used / $ram_total"

    # Disque
    df -h / | awk 'NR==2 {print "  Disque: "$3" / "$2" ("$5")"}'

    # Type de machine
    if [[ -d /sys/class/power_supply/BAT* ]]; then
        echo "  Type: Portable"
        if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
            local bat=$(cat /sys/class/power_supply/BAT0/capacity)
            echo "  🔋 Batterie: ${bat}%"
        fi
    else
        echo "  Type: Desktop"
    fi
}

# Fonction de monitoring simple
quick-monitor() {
    echo "📊 Monitoring Rapide"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # CPU
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  CPU: " 100 - $1"%"}'

    # RAM
    free -h | awk '/^Mem:/ {print "  RAM: "$3" / "$2}'

    # Disque
    df -h / | awk 'NR==2 {print "  Disque: "$5" utilisé"}'

    # Processus top 5
    echo "  Top 5 processus:"
    ps aux --sort=-%mem | awk 'NR>1 && NR<=6 {printf "    %s: %.1f%%\n", $11, $4}'
}

# Fonction pour définir un profil personnalisé
set-profile() {
    local profile="${1:-}"

    if [[ -z "$profile" ]]; then
        echo "Usage: set-profile [TuF|PcDeV|default]"
        echo ""
        echo "Profils disponibles:"
        echo "  TuF     - Desktop avec fix audio"
        echo "  PcDeV   - Ultraportable mode minimal"
        echo "  default - Configuration universelle"
        return 1
    fi

    # Utiliser la fonction du détecteur
    if command -v definir_profil_manuel &>/dev/null; then
        definir_profil_manuel "$profile"
    else
        mkdir -p "$HOME/.config/ubuntu-configs"
        echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile"
        echo "✅ Profil manuel défini: $profile"
        echo "   Rechargez votre shell: source ~/.bashrc (ou ~/.zshrc)"
    fi
}

# Fonction pour afficher le profil actuel
show-profile() {
    echo "📋 Profil Actuel"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Nom: ${PROFILE_NAME}"
    echo "  Type: ${PROFILE_TYPE}"
    echo "  Mode: ${PROFILE_MODE}"

    if command -v afficher_info_machine &>/dev/null; then
        echo ""
        afficher_info_machine "${PROFILE_NAME}"
    fi
}

# Note: Les fonctions sont disponibles sans export dans les fichiers sourcés
# Export -f retiré pour des raisons de sécurité (risque d'hijacking)

# ==========================================
# Messages de Bienvenue
# ==========================================

echo "   🌐 Mode: STANDARD (détection automatique)"
echo "   ⚙️  Configuration: Universelle équilibrée"
echo "   📊 Commandes disponibles:"
echo "      • system-info        : Informations système complètes"
echo "      • quick-monitor      : Monitoring rapide"
echo "      • set-profile        : Changer de profil manuellement"
echo "      • show-profile       : Afficher le profil actuel"
echo ""
echo "   💡 Pour utiliser un profil spécifique:"
echo "      set-profile TuF      (Desktop avec audio)"
echo "      set-profile PcDeV    (Ultraportable)"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
