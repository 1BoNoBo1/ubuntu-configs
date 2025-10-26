#!/bin/bash
# ============================================================
# Script : demo_adaptive.sh
# Objectif : Démonstration du système Ubuntu adaptatif
# Usage : ./demo_adaptive.sh
# ============================================================

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo_color() {
    echo -e "${2}${1}${NC}"
}

echo_color "🚀 DÉMONSTRATION SYSTÈME UBUNTU ADAPTATIF" $MAGENTA
echo_color "==========================================" $MAGENTA
echo_color ""

# 1. Détection du système
echo_color "📊 1. DÉTECTION ET CLASSIFICATION SYSTÈME" $CYAN
echo_color "--------------------------------------------" $CYAN
source /home/jim/ubuntu-configs/mon_shell/adaptive_detection.sh
detect_and_classify
echo_color ""

# 2. Matrice d'outils selon le niveau
echo_color "🔧 2. MATRICE D'OUTILS PAR NIVEAU" $CYAN
echo_color "-----------------------------------" $CYAN

echo_color "⚡ NIVEAU MINIMAL (score < 40) - Ressources limitées:" $YELLOW
echo_color "  • fd-find (find rapide)" $NC
echo_color "  • ripgrep (grep optimisé)" $NC
echo_color "  • bat (cat coloré)" $NC
echo_color "  • htop (monitoring léger)" $NC
echo_color "  • ncdu (analyse espace)" $NC
echo_color ""

echo_color "📈 NIVEAU STANDARD (score 40-69) - Équilibré:" $BLUE
echo_color "  • Tous les outils minimaux +" $NC
echo_color "  • exa (ls moderne)" $NC
echo_color "  • fzf (fuzzy finder)" $NC
echo_color "  • jq (JSON processor)" $NC
echo_color "  • tmux (multiplexeur)" $NC
echo_color "  • rsync (synchronisation)" $NC
echo_color ""

echo_color "🚀 NIVEAU PERFORMANCE (score ≥ 70) - Complet:" $GREEN
echo_color "  • Tous les outils standard +" $NC
echo_color "  • zoxide (cd intelligent)" $NC
echo_color "  • delta (diff moderne)" $NC
echo_color "  • procs (ps amélioré)" $NC
echo_color "  • dust (du graphique)" $NC
echo_color "  • hyperfine (benchmark)" $NC
echo_color "  • docker (conteneurs)" $NC
echo_color ""

# 3. Configuration adaptative
echo_color "⚙️ 3. CONFIGURATION ADAPTATIVE" $CYAN
echo_color "--------------------------------" $CYAN

case "${SYSTEM_TIER:-standard}" in
    "minimal")
        echo_color "Configuration pour votre système (minimal):" $YELLOW
        echo_color "  • ZRAM: 50% RAM (économie mémoire)" $NC
        echo_color "  • Services: essentiels uniquement" $NC
        echo_color "  • Monitoring: basique (15min)" $NC
        echo_color "  • Backup: local uniquement" $NC
        ;;
    "standard")
        echo_color "Configuration pour votre système (standard):" $BLUE
        echo_color "  • ZRAM: 25% RAM (équilibré)" $NC
        echo_color "  • Services: complets" $NC
        echo_color "  • Monitoring: détaillé (10min)" $NC
        echo_color "  • Backup: hybride local/cloud" $NC
        ;;
    "performance")
        echo_color "Configuration pour votre système (performance):" $GREEN
        echo_color "  • ZRAM: 12.5% RAM (performance max)" $NC
        echo_color "  • Services: tous activés" $NC
        echo_color "  • Monitoring: complet (5min)" $NC
        echo_color "  • Backup: cloud hybride avancé" $NC
        ;;
esac
echo_color ""

# 4. Seuils adaptatifs
echo_color "📈 4. SEUILS DE SURVEILLANCE ADAPTATIFS" $CYAN
echo_color "---------------------------------------" $CYAN

case "${SYSTEM_TIER:-standard}" in
    "minimal")
        echo_color "Seuils conservatives (système contraint):" $YELLOW
        echo_color "  • Mémoire: 85% attention | 95% critique" $NC
        echo_color "  • CPU: 90% attention | 98% critique" $NC
        echo_color "  • Disque: 90% attention | 98% critique" $NC
        ;;
    "standard")
        echo_color "Seuils équilibrés (système moyen):" $BLUE
        echo_color "  • Mémoire: 80% attention | 90% critique" $NC
        echo_color "  • CPU: 85% attention | 95% critique" $NC
        echo_color "  • Disque: 85% attention | 95% critique" $NC
        ;;
    "performance")
        echo_color "Seuils agressifs (système puissant):" $GREEN
        echo_color "  • Mémoire: 75% attention | 85% critique" $NC
        echo_color "  • CPU: 80% attention | 90% critique" $NC
        echo_color "  • Disque: 80% attention | 90% critique" $NC
        ;;
esac
echo_color ""

# 5. Commandes disponibles
echo_color "🎯 5. COMMANDES DISPONIBLES" $CYAN
echo_color "----------------------------" $CYAN
echo_color "Installation complète:" $BLUE
echo_color "  sudo ./adaptive_ubuntu.sh install" $NC
echo_color ""
echo_color "Gestion:" $BLUE
echo_color "  ./adaptive_ubuntu.sh detect    # Détecter le système" $NC
echo_color "  ./adaptive_ubuntu.sh status    # État actuel" $NC
echo_color "  sudo ./adaptive_ubuntu.sh tools     # Configurer outils" $NC
echo_color "  sudo ./adaptive_ubuntu.sh optimize  # Optimiser mémoire" $NC
echo_color ""

# 6. Intégration mon_shell
echo_color "🔗 6. INTÉGRATION MON_SHELL" $CYAN
echo_color "----------------------------" $CYAN
echo_color "Le système s'intègre avec votre architecture mon_shell:" $BLUE
echo_color "  • Préserve les fonctions existantes" $NC
echo_color "  • Ajoute des améliorations adaptatives" $NC
echo_color "  • Fournit des alternatives intelligentes" $NC
echo_color "  • Maintient la compatibilité complète" $NC
echo_color ""

echo_color "✨ SYSTÈME ADAPTATIF OPÉRATIONNEL" $GREEN
echo_color "Niveau détecté: ${SYSTEM_TIER:-standard} (score: ${SYSTEM_PERFORMANCE_SCORE:-47}/100)" $GREEN
echo_color "Prêt pour installation avec: sudo ./adaptive_ubuntu.sh install" $GREEN