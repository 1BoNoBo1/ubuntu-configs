#!/bin/bash
# ==============================================================================
# Module : Bandeau de Statut
# Description : Fonctions pour afficher un bandeau d'informations
# Auteur : Système de profils Ubuntu
# ==============================================================================

# Désactiver l'alias si existe
unalias bandeau 2>/dev/null
unalias status-banner 2>/dev/null
unalias watch-status 2>/dev/null

# Couleurs (si pas déjà chargées)
if [[ -z "$VERT" ]]; then
    VERT='\033[0;32m'
    CYAN='\033[0;36m'
    JAUNE='\033[0;33m'
    ROUGE='\033[0;31m'
    MAGENTA='\033[0;35m'
    BLEU='\033[0;34m'
    NC='\033[0m'
fi

# ==============================================================================
# Fonction : bandeau
# Description : Affiche un bandeau de statut unique
# Usage : bandeau
# ==============================================================================
bandeau() {
    ~/ubuntu-configs/scripts/status_banner.sh
}

# ==============================================================================
# Fonction : watch-status
# Description : Affiche un bandeau de statut en continu
# Usage : watch-status
# ==============================================================================
watch-status() {
    echo -e "${VERT}🔄 Bandeau de statut en continu${NC}"
    echo -e "${CYAN}   Appuyez sur Ctrl+C pour arrêter${NC}"
    echo ""
    ~/ubuntu-configs/scripts/status_banner.sh --loop
}

# ==============================================================================
# Fonction : status-banner
# Description : Affiche les informations de statut formatées
# Usage : status-banner
# ==============================================================================
status-banner() {
    echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${VERT}📊 Statut Système${NC}"
    echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Profil actuel
    local profile="default"
    if [[ -f "$HOME/.config/ubuntu-configs/machine_profile" ]]; then
        profile=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null | tr -d '[:space:]')
    fi
    echo -e "  ${MAGENTA}💻 Profil${NC}      : ${profile}"

    # Hostname
    echo -e "  ${CYAN}🖥️  Machine${NC}     : $(hostname)"

    # Batterie
    if [[ -d /sys/class/power_supply/BAT0 ]]; then
        local capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        local bat_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        if [[ -n "$capacity" ]]; then
            local bat_display="${capacity}%"
            [[ "$bat_status" == "Charging" ]] && bat_display="${bat_display} (en charge)"
            echo -e "  ${JAUNE}🔋 Batterie${NC}    : ${bat_display}"
        fi
    else
        echo -e "  ${JAUNE}🔌 Alimentation${NC} : Secteur"
    fi

    # RAM
    local ram_info=$(free -h | awk '/^Mem:/ {print $3" / "$2" ("int($3/$2*100)"%)"}')
    echo -e "  ${CYAN}💾 RAM${NC}         : ${ram_info}"

    # CPU load
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "  ${VERT}⚙️  CPU Load${NC}   :${cpu_load}"

    # Disque
    local disk_info=$(df -h / | awk 'NR==2 {print $3" / "$2" ("$5")"}')
    echo -e "  ${ROUGE}💿 Disque (/)${NC}  : ${disk_info}"

    # Uptime
    local uptime_info=$(uptime -p | sed 's/up //')
    echo -e "  ${BLEU}⏱️  Uptime${NC}      : ${uptime_info}"

    echo ""
    echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ==============================================================================
# Fonction : start-tmux-status
# Description : Démarre tmux avec la configuration de statut
# Usage : start-tmux-status
# ==============================================================================
start-tmux-status() {
    if ! command -v tmux &>/dev/null; then
        echo -e "${ROUGE}❌ tmux n'est pas installé${NC}"
        echo -e "${JAUNE}   Installation: sudo apt install tmux${NC}"
        return 1
    fi

    # Créer lien symbolique vers la config tmux si nécessaire
    if [[ ! -f "$HOME/.tmux.conf" ]]; then
        if [[ -f "$HOME/ubuntu-configs/.tmux.conf" ]]; then
            ln -sf "$HOME/ubuntu-configs/.tmux.conf" "$HOME/.tmux.conf"
            echo -e "${VERT}✅ Configuration tmux liée${NC}"
        fi
    fi

    # Démarrer tmux
    if [[ -z "$TMUX" ]]; then
        echo -e "${VERT}🚀 Démarrage de tmux avec bandeau de statut${NC}"
        tmux new-session
    else
        echo -e "${JAUNE}⚠️  Vous êtes déjà dans tmux${NC}"
        echo -e "${CYAN}   Rechargez la config: Ctrl+B puis R${NC}"
    fi
}

# ==============================================================================
# Aide intégrée
# ==============================================================================
unalias aide-bandeau 2>/dev/null
aide-bandeau() {
    echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${VERT}📚 Aide : Bandeau de Statut${NC}"
    echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Commandes disponibles :${NC}"
    echo ""
    echo -e "  ${JAUNE}bandeau${NC}"
    echo -e "    Affiche un bandeau de statut unique en bas d'écran"
    echo ""
    echo -e "  ${JAUNE}status-banner${NC}"
    echo -e "    Affiche les informations de statut formatées"
    echo ""
    echo -e "  ${JAUNE}watch-status${NC}"
    echo -e "    Affiche un bandeau de statut en continu (Ctrl+C pour arrêter)"
    echo ""
    echo -e "  ${JAUNE}start-tmux-status${NC}"
    echo -e "    Démarre tmux avec bandeau de statut permanent"
    echo -e "    ${CYAN}Requis: sudo apt install tmux${NC}"
    echo ""
    echo -e "${MAGENTA}💡 Recommandation :${NC}"
    echo -e "   Utilisez ${JAUNE}start-tmux-status${NC} pour un bandeau permanent"
    echo -e "   ou ajoutez ${JAUNE}bandeau${NC} à votre PS1 pour l'afficher à chaque commande"
    echo ""
    echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Note: Les fonctions sont disponibles sans export dans les fichiers sourcés
# Export -f retiré pour des raisons de sécurité (risque d'hijacking)
