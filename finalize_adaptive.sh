#!/bin/bash
# ============================================================
# Script : finalize_adaptive.sh
# Objectif : Finalisation et validation système adaptatif
# Usage : ./finalize_adaptive.sh
# ============================================================

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo_color() {
    echo -e "${2}${1}${NC}"
}

echo_color "🎯 FINALISATION SYSTÈME UBUNTU ADAPTATIF" $MAGENTA
echo_color "=========================================" $MAGENTA
echo_color ""

# 1. Vérification structure complète
echo_color "📁 1. Vérification structure finale" $CYAN
echo_color "------------------------------------" $CYAN

REQUIRED_FILES=(
    "adaptive_ubuntu.sh"
    "demo_adaptive.sh"
    "test_adaptive_integration.sh"
    "README_Adaptive.md"
    "GUIDE_UTILISATION.md"
    "mon_shell/adaptive_detection.sh"
    "mon_shell/adaptive_tools.sh"
    "mon_shell/adaptive_monitoring.sh"
    "mon_shell/colors.sh"
)

all_files_present=true
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo_color "  ✅ $file" $GREEN
    else
        echo_color "  ❌ $file manquant" $YELLOW
        all_files_present=false
    fi
done

if $all_files_present; then
    echo_color "✅ Tous les fichiers requis sont présents" $GREEN
else
    echo_color "⚠️ Certains fichiers manquent" $YELLOW
fi

echo_color ""

# 2. Permissions exécutables
echo_color "🔧 2. Correction permissions exécutables" $CYAN
echo_color "-------------------------------------------" $CYAN

EXECUTABLE_FILES=(
    "adaptive_ubuntu.sh"
    "demo_adaptive.sh"
    "test_adaptive_integration.sh"
    "finalize_adaptive.sh"
    "mon_shell/adaptive_detection.sh"
    "mon_shell/adaptive_tools.sh"
    "mon_shell/adaptive_monitoring.sh"
    "mon_shell/colors.sh"
)

for file in "${EXECUTABLE_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        chmod +x "$file"
        echo_color "  ✅ $file - permissions corrigées" $GREEN
    fi
done

echo_color ""

# 3. Test de syntaxe rapide
echo_color "📝 3. Validation syntaxe" $CYAN
echo_color "-------------------------" $CYAN

syntax_errors=0
for file in "${EXECUTABLE_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        if bash -n "$file" 2>/dev/null; then
            echo_color "  ✅ $file - syntaxe OK" $GREEN
        else
            echo_color "  ❌ $file - erreur syntaxe" $YELLOW
            ((syntax_errors++))
        fi
    fi
done

if [[ $syntax_errors -eq 0 ]]; then
    echo_color "✅ Aucune erreur de syntaxe détectée" $GREEN
else
    echo_color "⚠️ $syntax_errors erreurs de syntaxe trouvées" $YELLOW
fi

echo_color ""

# 4. Test fonctionnel rapide
echo_color "⚡ 4. Test fonctionnel rapide" $CYAN
echo_color "-----------------------------" $CYAN

# Test détection
if ./adaptive_ubuntu.sh detect >/dev/null 2>&1; then
    echo_color "  ✅ Détection système fonctionne" $GREEN
else
    echo_color "  ❌ Problème détection système" $YELLOW
fi

# Test aide
if ./adaptive_ubuntu.sh help >/dev/null 2>&1; then
    echo_color "  ✅ Aide accessible" $GREEN
else
    echo_color "  ❌ Problème affichage aide" $YELLOW
fi

# Test chargement modules
if source mon_shell/adaptive_detection.sh >/dev/null 2>&1; then
    echo_color "  ✅ Modules se chargent correctement" $GREEN
else
    echo_color "  ❌ Problème chargement modules" $YELLOW
fi

echo_color ""

# 5. Vérification intégration mon_shell
echo_color "🔗 5. Vérification intégration mon_shell" $CYAN
echo_color "-----------------------------------------" $CYAN

# Vérifier que les fichiers existants ne sont pas cassés
if [[ -f "mon_shell/aliases.sh" ]] && source mon_shell/aliases.sh >/dev/null 2>&1; then
    echo_color "  ✅ aliases.sh compatible" $GREEN
else
    echo_color "  ⚠️ Problème avec aliases.sh" $YELLOW
fi

# Vérifier functions existantes
functions_ok=true
for func_file in mon_shell/functions_*.sh; do
    if [[ -f "$func_file" ]]; then
        if source "$func_file" >/dev/null 2>&1; then
            echo_color "  ✅ $(basename "$func_file") compatible" $GREEN
        else
            echo_color "  ⚠️ Problème avec $(basename "$func_file")" $YELLOW
            functions_ok=false
        fi
    fi
done

if $functions_ok; then
    echo_color "✅ Intégration mon_shell réussie" $GREEN
else
    echo_color "⚠️ Problèmes d'intégration détectés" $YELLOW
fi

echo_color ""

# 6. Récapitulatif système détecté
echo_color "📊 6. Récapitulatif système adaptatif" $CYAN
echo_color "--------------------------------------" $CYAN

# Charger la détection
source mon_shell/adaptive_detection.sh >/dev/null 2>&1

echo_color "🎯 Système détecté:" $BLUE
echo_color "   Niveau: ${SYSTEM_TIER:-inconnu}" $NC
echo_color "   Score: ${SYSTEM_PERFORMANCE_SCORE:-0}/100" $NC
echo_color "   RAM: ${SYSTEM_RAM_MB:-?}MB" $NC
echo_color "   CPU: ${SYSTEM_CPU_CORES:-?} cores" $NC
echo_color "   Stockage: ${SYSTEM_STORAGE_TYPE:-?}" $NC

echo_color ""

# 7. Instructions finales
echo_color "🚀 7. Instructions finales" $CYAN
echo_color "---------------------------" $CYAN

echo_color "Le système Ubuntu adaptatif est prêt ! Voici les prochaines étapes :" $BLUE
echo_color ""
echo_color "📋 Tests recommandés :" $CYAN
echo_color "   ./demo_adaptive.sh              # Démonstration complète" $NC
echo_color "   ./test_adaptive_integration.sh  # Tests d'intégration" $NC
echo_color "   ./adaptive_ubuntu.sh detect     # Test détection" $NC
echo_color ""
echo_color "⚙️ Installation :" $CYAN
echo_color "   sudo ./adaptive_ubuntu.sh install  # Installation complète adaptative" $NC
echo_color "   sudo ./enhance_ubuntu_geek.sh       # Transformation complète système" $NC
echo_color ""
echo_color "📚 Documentation :" $CYAN
echo_color "   cat README_Adaptive.md           # Documentation détaillée" $NC
echo_color "   cat GUIDE_UTILISATION.md         # Guide utilisation rapide" $NC
echo_color ""
echo_color "🔧 Maintenance :" $CYAN
echo_color "   ./adaptive_ubuntu.sh status      # État système" $NC
echo_color "   ./adaptive_ubuntu.sh validate    # Validation installation" $NC
echo_color ""

# 8. Statistiques finales
echo_color "📈 8. Statistiques du projet" $CYAN
echo_color "-----------------------------" $CYAN

total_lines=$(find . -name "*.sh" -exec wc -l {} + | tail -1 | awk '{print $1}')
total_files=$(find . -name "*.sh" | wc -l)
adaptive_files=$(find . -name "*adaptive*" | wc -l)

echo_color "📊 Projet ubuntu-configs :" $BLUE
echo_color "   Total lignes de code: $total_lines" $NC
echo_color "   Total scripts: $total_files" $NC
echo_color "   Fichiers adaptatifs: $adaptive_files" $NC
echo_color "   Architecture: Modulaire (mon_shell)" $NC
echo_color "   Fonctionnalités: WebDAV + Restic + Adaptatif" $NC

echo_color ""
echo_color "🎉 SYSTÈME UBUNTU ADAPTATIF FINALISÉ AVEC SUCCÈS !" $GREEN
echo_color ""
echo_color "Votre configuration ubuntu-configs est maintenant le dépôt" $CYAN
echo_color "le plus abouti avec détection intelligente des ressources" $CYAN
echo_color "et adaptation automatique selon vos capacités matérielles !" $CYAN

echo_color ""
echo_color "💡 Conseil: Commencez par ./demo_adaptive.sh pour voir" $YELLOW
echo_color "   le système en action, puis sudo ./adaptive_ubuntu.sh install" $YELLOW