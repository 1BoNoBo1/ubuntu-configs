#!/bin/bash
# ==============================================================================
# Script : machine_detector.sh
# Objectif : Détection automatique de la machine pour chargement de profil
# Usage : source profiles/machine_detector.sh
# ==============================================================================

# Fonction de détection automatique
detecter_machine() {
    local machine_name=""

    # Méthode 1 : Fichier de configuration manuel (priorité la plus haute)
    if [[ -f "$HOME/.config/ubuntu-configs/machine_profile" ]]; then
        machine_name=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$machine_name" ]]; then
            echo "$machine_name"
            return 0
        fi
    fi

    # Méthode 2 : Détection par hostname
    local hostname=$(hostname)
    case "$hostname" in
        TuF|tuf|TUF)
            echo "TuF"
            return 0
            ;;
        PcDeV|pcdev|PCDEV|ultraportable)
            echo "PcDeV"
            return 0
            ;;
    esac

    # Méthode 3 : Détection par caractéristiques matérielles

    # Vérifier si c'est un portable (présence de batterie)
    if [[ -d /sys/class/power_supply/BAT* ]] || [[ -d /sys/class/power_supply/battery ]]; then
        # C'est un portable

        # Vérifier la RAM pour distinguer ultraportable vs desktop portable
        local ram_gb=$(free -g | awk '/^Mem:/{print $2}')

        if [[ $ram_gb -le 4 ]]; then
            # Ultraportable avec peu de RAM
            echo "PcDeV"
            return 0
        fi
    else
        # C'est un desktop

        # Vérifier si c'est le TuF (peut avoir des caractéristiques spécifiques)
        # Par exemple, présence de certains périphériques audio Bluetooth
        if lspci 2>/dev/null | grep -qi "audio"; then
            # Desktop avec audio, probablement TuF
            echo "TuF"
            return 0
        fi
    fi

    # Méthode 4 : Détection par présence de scripts spécifiques
    if [[ -f "$HOME/ubuntu-configs/script/son/fix_pipewire_bt.sh" ]]; then
        # Si le script audio existe, c'est probablement le TuF
        echo "TuF"
        return 0
    fi

    # Par défaut : profil default
    echo "default"
    return 0
}

# Fonction pour afficher les informations de détection
afficher_info_machine() {
    local profile="$1"

    echo "🖥️  Détection de machine:"
    echo "   Hostname: $(hostname)"
    echo "   Type: $(detecter_type_machine)"
    echo "   RAM: $(free -h | awk '/^Mem:/{print $2}')"
    echo "   Profil sélectionné: $profile"
}

# Fonction helper pour détecter le type de machine
detecter_type_machine() {
    if [[ -d /sys/class/power_supply/BAT* ]] || [[ -d /sys/class/power_supply/battery ]]; then
        echo "Portable"
    else
        echo "Desktop"
    fi
}

# Fonction pour créer un profil manuel
definir_profil_manuel() {
    local profile="$1"

    if [[ -z "$profile" ]]; then
        echo "Usage: definir_profil_manuel [TuF|PcDeV|default]"
        return 1
    fi

    # Créer le répertoire si nécessaire
    mkdir -p "$HOME/.config/ubuntu-configs"

    # Écrire le profil
    echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile"

    echo "✅ Profil manuel défini: $profile"
    echo "   Rechargez votre shell pour appliquer les changements."
}

# Export des fonctions (compatible bash/zsh)
if [[ -n "$BASH_VERSION" ]]; then
    export -f detecter_machine
    export -f afficher_info_machine
    export -f detecter_type_machine
    export -f definir_profil_manuel
fi

# Variable globale pour le profil détecté
export MACHINE_PROFILE=$(detecter_machine)
