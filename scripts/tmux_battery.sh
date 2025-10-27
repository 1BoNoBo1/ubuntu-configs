#!/bin/bash
# ==============================================================================
# Script d'affichage de la batterie pour tmux
# Adapte l'affichage selon portable/desktop
# ==============================================================================

if [[ -d /sys/class/power_supply/BAT0 ]]; then
    # Portable - afficher le pourcentage de batterie
    capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)

    if [[ -n "$capacity" ]]; then
        # Choisir l'icône selon le niveau
        if [[ $capacity -ge 80 ]]; then
            icon="🔋"
        elif [[ $capacity -ge 50 ]]; then
            icon="🔋"
        elif [[ $capacity -ge 20 ]]; then
            icon="⚡"
        else
            icon="🪫"
        fi

        # Ajouter indication de charge
        if [[ "$status" == "Charging" ]]; then
            echo "${icon} ${capacity}% ⚡"
        else
            echo "${icon} ${capacity}%"
        fi
    else
        echo "AC"
    fi
elif [[ -d /sys/class/power_supply/BAT1 ]]; then
    # Alternative BAT1
    capacity=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
    if [[ -n "$capacity" ]]; then
        echo "🔋 ${capacity}%"
    else
        echo "AC"
    fi
else
    # Desktop - afficher AC power
    echo "🔌 AC"
fi
