#!/bin/bash
# ==============================================================================
# Bandeau de statut permanent avec tput (sans tmux)
# Affiche les informations importantes en bas de l'écran
# ==============================================================================

# Couleurs
source ~/ubuntu-configs/mon_shell/colors.sh 2>/dev/null || {
    VERT='\033[0;32m'
    CYAN='\033[0;36m'
    JAUNE='\033[0;33m'
    ROUGE='\033[0;31m'
    MAGENTA='\033[0;35m'
    NC='\033[0m'
}

get_profile() {
    if [[ -f "$HOME/.config/ubuntu-configs/machine_profile" ]]; then
        cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null | tr -d '[:space:]'
    else
        echo "default"
    fi
}

get_battery() {
    if [[ -d /sys/class/power_supply/BAT0 ]]; then
        local capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        local status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)

        if [[ -n "$capacity" ]]; then
            if [[ "$status" == "Charging" ]]; then
                echo "🔋${capacity}%⚡"
            else
                echo "🔋${capacity}%"
            fi
        else
            echo "AC"
        fi
    else
        echo "🔌AC"
    fi
}

get_ram() {
    free -h | awk '/^Mem:/ {print $3"/"$2}'
}

get_cpu() {
    uptime | awk -F'load average:' '{print $2}' | awk '{gsub(/^[ \t]+/, ""); print $1}' | tr -d ','
}

get_time() {
    date '+%H:%M:%S'
}

display_banner() {
    # Sauvegarder la position du curseur
    tput sc

    # Aller en bas de l'écran
    local lines=$(tput lines)
    tput cup $((lines - 1)) 0

    # Effacer la ligne
    tput el

    # Construire le bandeau
    local profile=$(get_profile)
    local battery=$(get_battery)
    local ram=$(get_ram)
    local cpu=$(get_cpu)
    local time=$(get_time)

    # Afficher avec couleurs
    echo -ne "${MAGENTA}💻 ${profile}${NC} | ${JAUNE}${battery}${NC} | ${CYAN}💾 ${ram}${NC} | ${VERT}⚙️  ${cpu}${NC} | ${ROUGE}⏰ ${time}${NC}"

    # Restaurer la position du curseur
    tput rc
}

# Mode continu ou affichage unique
if [[ "$1" == "--loop" ]]; then
    while true; do
        display_banner
        sleep 2
    done
else
    display_banner
fi
