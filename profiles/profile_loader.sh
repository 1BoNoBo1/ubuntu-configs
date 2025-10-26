#!/bin/bash
# ==============================================================================
# Script : profile_loader.sh
# Objectif : Chargement automatique du profil machine approprié
# Usage : source ~/ubuntu-configs/profiles/profile_loader.sh
# ==============================================================================

# Chemin de base des profils
PROFILES_DIR="$HOME/ubuntu-configs/profiles"

# ==========================================
# Fonction de chargement du profil
# ==========================================

load_machine_profile() {
    # Vérifier que le répertoire des profils existe
    if [[ ! -d "$PROFILES_DIR" ]]; then
        echo "⚠️  Répertoire des profils introuvable: $PROFILES_DIR"
        return 1
    fi

    # Charger le détecteur de machine
    if [[ -f "$PROFILES_DIR/machine_detector.sh" ]]; then
        source "$PROFILES_DIR/machine_detector.sh"
    else
        echo "⚠️  Détecteur de machine introuvable"
        return 1
    fi

    # Détecter la machine
    local profile=$(detecter_machine)

    # Vérifier que le profil existe
    local profile_config="$PROFILES_DIR/$profile/config.sh"

    if [[ ! -f "$profile_config" ]]; then
        # Fallback sur le profil default
        echo "⚠️  Profil $profile introuvable, utilisation du profil default"
        profile="default"
        profile_config="$PROFILES_DIR/default/config.sh"
    fi

    # Charger le profil
    if [[ -f "$profile_config" ]]; then
        source "$profile_config"

        # Export des variables de profil pour les scripts ultérieurs
        export CURRENT_PROFILE="$profile"
        export CURRENT_PROFILE_DIR="$PROFILES_DIR/$profile"

        return 0
    else
        echo "❌ Impossible de charger le profil: $profile"
        return 1
    fi
}

# ==========================================
# Fonction de chargement des modules du profil
# ==========================================

load_profile_modules() {
    # Vérifier que les variables de profil sont définies
    if [[ -z "$PROFILE_NAME" ]]; then
        echo "⚠️  Aucun profil chargé"
        return 1
    fi

    # Charger le chargeur de modules principal
    if [[ -f "$HOME/ubuntu-configs/mon_shell/chargeur_modules.sh" ]]; then
        source "$HOME/ubuntu-configs/mon_shell/chargeur_modules.sh"
    else
        echo "⚠️  Chargeur de modules introuvable"
        return 1
    fi

    # Déterminer quels modules charger selon le profil
    local modules_to_load=()

    case "$PROFILE_NAME" in
        TuF)
            # Profil TuF : Tous les modules (mode PERFORMANCE)
            if [[ -n "${MODULES_TUF[@]}" ]]; then
                modules_to_load=("${MODULES_TUF[@]}")
            fi
            ;;
        PcDeV)
            # Profil PcDeV : Modules essentiels uniquement (mode MINIMAL)
            if [[ -n "${MODULES_PCDEV[@]}" ]]; then
                modules_to_load=("${MODULES_PCDEV[@]}")
            fi
            ;;
        default)
            # Profil default : Modules standard (mode STANDARD)
            if [[ -n "${MODULES_DEFAULT[@]}" ]]; then
                modules_to_load=("${MODULES_DEFAULT[@]}")
            fi
            ;;
        *)
            # Profil inconnu : charger les modules de base
            modules_to_load=(
                "utilitaires_systeme.sh:Utilitaires système"
                "aide_memoire.sh:Aide rapide"
            )
            ;;
    esac

    # Charger les modules si définis
    if [[ ${#modules_to_load[@]} -gt 0 ]]; then
        for module_info in "${modules_to_load[@]}"; do
            local module="${module_info%%:*}"
            local module_path="$HOME/ubuntu-configs/mon_shell/$module"

            if [[ -f "$module_path" ]]; then
                source "$module_path"
            fi
        done
    fi

    return 0
}

# ==========================================
# Fonction de chargement des couleurs
# ==========================================

load_colors() {
    if [[ -f "$HOME/ubuntu-configs/mon_shell/colors.sh" ]]; then
        source "$HOME/ubuntu-configs/mon_shell/colors.sh"
    fi
}

# ==========================================
# Fonction de chargement des aliases
# ==========================================

load_aliases() {
    if [[ -f "$HOME/ubuntu-configs/mon_shell/aliases.sh" ]]; then
        source "$HOME/ubuntu-configs/mon_shell/aliases.sh"
    fi
}

# ==========================================
# Fonction principale de chargement complet
# ==========================================

load_complete_environment() {
    # Étape 1 : Charger les couleurs (pour les messages)
    load_colors

    # Étape 2 : Charger le profil machine
    if ! load_machine_profile; then
        echo "❌ Erreur lors du chargement du profil"
        return 1
    fi

    # Étape 3 : Charger les modules selon le profil
    load_profile_modules

    # Étape 4 : Charger les aliases communs
    load_aliases

    # Étape 5 : Charger le système adaptatif si disponible
    if [[ -f "$HOME/ubuntu-configs/mon_shell/adaptive_detection.sh" ]]; then
        source "$HOME/ubuntu-configs/mon_shell/adaptive_detection.sh"
    fi

    return 0
}

# ==========================================
# Fonctions utilitaires pour l'utilisateur
# ==========================================

# Fonction pour recharger le profil
reload-profile() {
    echo "🔄 Rechargement du profil..."

    # Recharger l'environnement complet
    if load_complete_environment; then
        echo "✅ Profil rechargé avec succès"
    else
        echo "❌ Erreur lors du rechargement"
    fi
}

# Fonction pour lister les profils disponibles
list-profiles() {
    echo "📋 Profils Disponibles"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for profile_dir in "$PROFILES_DIR"/*/; do
        local profile_name=$(basename "$profile_dir")

        # Ignorer les fichiers non-profils
        [[ "$profile_name" == "*" ]] && continue

        # Lire la description depuis config.sh si disponible
        if [[ -f "$profile_dir/config.sh" ]]; then
            local description=$(grep "^# Description" "$profile_dir/config.sh" | cut -d: -f2- | xargs)
            local mode=$(grep "^# Mode Adaptatif" "$profile_dir/config.sh" | cut -d: -f2- | xargs)

            echo "  📁 $profile_name"
            [[ -n "$description" ]] && echo "     $description"
            [[ -n "$mode" ]] && echo "     Mode: $mode"
            echo ""
        else
            echo "  📁 $profile_name (configuration manquante)"
            echo ""
        fi
    done

    echo "Profil actuel: ${PROFILE_NAME:-non défini}"
}

# Fonction pour changer de profil
switch-profile() {
    local new_profile="$1"

    if [[ -z "$new_profile" ]]; then
        echo "Usage: switch-profile [TuF|PcDeV|default]"
        echo ""
        list-profiles
        return 1
    fi

    # Utiliser la fonction set-profile si disponible
    if command -v set-profile &>/dev/null; then
        set-profile "$new_profile"
    elif command -v definir_profil_manuel &>/dev/null; then
        definir_profil_manuel "$new_profile"
    else
        # Fallback manuel
        mkdir -p "$HOME/.config/ubuntu-configs"
        echo "$new_profile" > "$HOME/.config/ubuntu-configs/machine_profile"
        echo "✅ Profil défini: $new_profile"
        echo "   Rechargez votre shell pour appliquer les changements"
    fi
}

# Export des fonctions (compatible bash/zsh)
if [[ -n "$BASH_VERSION" ]]; then
    export -f reload-profile
    export -f list-profiles
    export -f switch-profile
    export -f load_complete_environment
fi

# ==========================================
# Chargement automatique au sourcing
# ==========================================

# Charger l'environnement complet automatiquement
load_complete_environment
