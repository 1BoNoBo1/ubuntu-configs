#!/usr/bin/env bash
# ============================================================
# Module : chargeur_modules.sh
# Objectif : Chargement intelligent de tous les modules mon_shell
# Usage : source chargeur_modules.sh
# Style : Simple, robuste, messages clairs en français
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[0;35m'
NC='\033[0m'

annoncer() {
    local message="$1"
    local couleur="${2:-$NC}"
    echo -e "${couleur}${message}${NC}"
}

# Répertoire des modules (dossier actuel du script)
MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ========== CHARGEMENT INTELLIGENT ==========

charger_module() {
    local module="$1"
    local description="$2"
    local obligatoire="${3:-false}"

    local chemin_module="$MODULES_DIR/$module"

    if [[ -f "$chemin_module" ]]; then
        if source "$chemin_module" 2>/dev/null; then
            annoncer "  ✅ $description" $VERT
            return 0
        else
            annoncer "  ❌ $description (erreur chargement)" $ROUGE
            if [[ "$obligatoire" == "true" ]]; then
                annoncer "⚠️ Module obligatoire échoué: $module" $JAUNE
            fi
            return 1
        fi
    else
        annoncer "  ❓ $description (fichier absent)" $JAUNE
        if [[ "$obligatoire" == "true" ]]; then
            annoncer "⚠️ Module obligatoire manquant: $module" $JAUNE
        fi
        return 1
    fi
}

charger_tous_modules() {
    annoncer "🔧 CHARGEMENT MODULES MON_SHELL" $BLEU
    annoncer "═══════════════════════════════" $BLEU

    local modules_charges=0
    local modules_echecs=0

    # Modules de base (obligatoires)
    annoncer "📦 Modules de base:" $CYAN
    charger_module "colors.sh" "Système de couleurs" true && ((modules_charges++)) || ((modules_echecs++))
    charger_module "functions_system.sh" "Fonctions système" true && ((modules_charges++)) || ((modules_echecs++))
    charger_module "functions_utils.sh" "Utilitaires généraux" false && ((modules_charges++)) || ((modules_echecs++))

    # Modules spécialisés
    annoncer "🎯 Modules spécialisés:" $CYAN
    charger_module "functions_security.sh" "Fonctions sécurité" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "functions_webdav.sh" "Gestion WebDAV" false && ((modules_charges++)) || ((modules_echecs++))

    # Modules adaptatifs (nouveaux)
    annoncer "🤖 Modules adaptatifs:" $CYAN
    charger_module "adaptive_detection.sh" "Détection système" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "adaptive_tools.sh" "Outils adaptatifs" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "adaptive_monitoring.sh" "Surveillance adaptative" false && ((modules_charges++)) || ((modules_echecs++))

    # Modules utilitaires (tout nouveaux)
    annoncer "🛠️ Modules utilitaires:" $CYAN
    charger_module "utilitaires_systeme.sh" "Utilitaires système" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "outils_fichiers.sh" "Outils fichiers" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "aide_memoire.sh" "Aide-mémoire interactif" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "raccourcis_pratiques.sh" "Raccourcis pratiques" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "outils_productivite.sh" "Outils productivité" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "outils_developpeur.sh" "Outils développeur" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "outils_reseau.sh" "Outils réseau" false && ((modules_charges++)) || ((modules_echecs++))
    charger_module "outils_multimedia.sh" "Outils multimédia" false && ((modules_charges++)) || ((modules_echecs++))

    # Aliases (toujours en dernier)
    annoncer "🔗 Configuration:" $CYAN
    charger_module "aliases.sh" "Aliases et raccourcis" false && ((modules_charges++)) || ((modules_echecs++))

    # Bilan final
    echo
    annoncer "📊 BILAN CHARGEMENT" $VIOLET
    annoncer "══════════════════" $VIOLET
    annoncer "✅ Modules chargés: $modules_charges" $VERT

    if [[ $modules_echecs -gt 0 ]]; then
        annoncer "❌ Modules échoués: $modules_echecs" $ROUGE
    else
        annoncer "🎉 Tous les modules disponibles sont chargés!" $VERT
    fi

    # Message de bienvenue
    echo
    afficher_bienvenue
}

afficher_bienvenue() {
    annoncer "🎯 MON_SHELL ACTIVÉ" $BLEU
    annoncer "═══════════════════" $BLEU
    annoncer "Commandes rapides disponibles:" $CYAN
    echo "  maintenance         # Check système rapide"
    echo "  aide               # Aide-mémoire interactif"
    echo "  raccourcis         # Liste raccourcis"
    echo "  info               # Infos système"
    echo "  adaptive-status    # État système adaptatif"
    echo
    annoncer "💡 Tapez 'aide' pour l'aide interactive complète" $JAUNE
}

# ========== FONCTIONS UTILITAIRES ==========

recharger_modules() {
    annoncer "🔄 Rechargement des modules..." $CYAN
    charger_tous_modules
}

lister_modules() {
    annoncer "📋 MODULES MON_SHELL DISPONIBLES" $BLEU
    annoncer "═════════════════════════════════" $BLEU

    local modules=(
        "colors.sh:Système de couleurs universel"
        "functions_system.sh:Fonctions système de base"
        "functions_utils.sh:Utilitaires généraux"
        "functions_security.sh:Fonctions de sécurité"
        "functions_webdav.sh:Gestion WebDAV kDrive"
        "adaptive_detection.sh:Détection intelligente ressources"
        "adaptive_tools.sh:Sélection outils adaptatifs"
        "adaptive_monitoring.sh:Surveillance adaptative"
        "utilitaires_systeme.sh:Utilitaires système pratiques"
        "outils_fichiers.sh:Outils gestion fichiers"
        "aide_memoire.sh:Aide-mémoire interactif"
        "raccourcis_pratiques.sh:Raccourcis ultra-pratiques"
        "outils_productivite.sh:Outils productivité quotidienne"
        "outils_developpeur.sh:Outils développement logiciel"
        "outils_reseau.sh:Outils réseau et connectivité"
        "outils_multimedia.sh:Outils fichiers multimédia"
        "exemple_simple.sh:Module démonstration simple"
        "aliases.sh:Aliases et raccourcis configurés"
    )

    for module_info in "${modules[@]}"; do
        local fichier="${module_info%:*}"
        local description="${module_info#*:}"
        local chemin="$MODULES_DIR/$fichier"

        if [[ -f "$chemin" ]]; then
            annoncer "✅ $fichier - $description" $VERT
        else
            annoncer "❌ $fichier - $description (manquant)" $ROUGE
        fi
    done
}

verifier_modules() {
    annoncer "🔍 Vérification intégrité des modules..." $CYAN
    echo

    local modules_ok=0
    local modules_ko=0

    for fichier in "$MODULES_DIR"/*.sh; do
        if [[ -f "$fichier" ]]; then
            local nom=$(basename "$fichier")

            # Test syntaxe bash
            if bash -n "$fichier" 2>/dev/null; then
                annoncer "  ✅ $nom - syntaxe OK" $VERT
                ((modules_ok++))
            else
                annoncer "  ❌ $nom - erreur syntaxe" $ROUGE
                ((modules_ko++))
            fi
        fi
    done

    echo
    annoncer "📊 Modules OK: $modules_ok | Modules KO: $modules_ko" $CYAN

    if [[ $modules_ko -eq 0 ]]; then
        annoncer "✅ Tous les modules sont valides" $VERT
    else
        annoncer "⚠️ Des modules ont des erreurs de syntaxe" $JAUNE
    fi
}

# ========== ALIASES ==========

alias recharger='recharger_modules'
alias modules='lister_modules'
alias verif-modules='verifier_modules'

# Export des fonctions
export -f annoncer charger_module charger_tous_modules afficher_bienvenue
export -f recharger_modules lister_modules verifier_modules

# ========== CHARGEMENT AUTOMATIQUE ==========

# Si ce script est sourcé (pas exécuté), charger automatiquement
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    charger_tous_modules
else
    # Si exécuté directement, proposer les options
    annoncer "🔧 GESTIONNAIRE MODULES MON_SHELL" $BLEU
    annoncer "════════════════════════════════" $BLEU
    echo
    annoncer "Options disponibles:" $CYAN
    echo "  source $0              # Charger tous les modules"
    echo "  $0 lister             # Lister modules disponibles"
    echo "  $0 verifier           # Vérifier syntaxe modules"
    echo

    case "${1:-}" in
        "lister"|"list")
            lister_modules
            ;;
        "verifier"|"check")
            verifier_modules
            ;;
        *)
            annoncer "💡 Pour charger: source $0" $JAUNE
            ;;
    esac
fi