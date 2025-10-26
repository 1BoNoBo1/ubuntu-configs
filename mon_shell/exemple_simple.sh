#!/usr/bin/env bash
# ============================================================
# Module : exemple_simple.sh
# Objectif : Exemple simple et fonctionnel de module mon_shell
# Usage : source exemple_simple.sh
# Style : Ultra-simple, testé, pas d'erreur
# ============================================================

# Couleurs simples
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ========== FONCTIONS SIMPLES ==========

# Fonction pour afficher avec couleur
dire_couleur() {
    local message="$1"
    local couleur="${2:-$NC}"
    echo -e "${couleur}${message}${NC}"
}

# Informations système ultra-simples
info_express() {
    dire_couleur "💻 INFOS EXPRESS" $BLEU
    echo "─────────────────"

    local ram_mb=$(free -m | awk 'NR==2{print $2}')
    local ram_utilise=$(free -m | awk 'NR==2{printf "%.0f", $3/$2*100}')
    local cpu_cores=$(nproc)
    local utilisateur=$(whoami)
    local dossier_actuel=$(pwd)

    echo "💾 RAM: ${ram_mb}MB (${ram_utilise}% utilisé)"
    echo "⚙️ CPU: ${cpu_cores} cœurs"
    echo "👤 User: $utilisateur"
    echo "📁 Dossier: $dossier_actuel"
    echo "🕐 Uptime: $(uptime -p | sed 's/up //')"
}

# Test de connexion simple
test_internet() {
    dire_couleur "🌐 Test connexion Internet..." $CYAN

    if ping -c1 8.8.8.8 >/dev/null 2>&1; then
        dire_couleur "✅ Internet fonctionne" $VERT
    else
        dire_couleur "❌ Pas de connexion Internet" $ROUGE
    fi
}

# Espace disque simple
espace_disque() {
    dire_couleur "💿 Espace disque principal" $CYAN
    echo "─────────────────────────"

    df -h / | tail -1 | while read filesystem size used avail use mounted; do
        echo "📊 Utilisé: $used sur $size ($use)"
        echo "📁 Libre: $avail"
    done
}

# Processus gourmands simple
top_processus() {
    dire_couleur "🔥 Top 3 processus gourmands" $CYAN
    echo "────────────────────────────"

    ps aux --sort=-%cpu | head -4 | tail -3 | while read ligne; do
        local user=$(echo "$ligne" | awk '{print $1}')
        local cpu=$(echo "$ligne" | awk '{print $3}')
        local mem=$(echo "$ligne" | awk '{print $4}')
        local cmd=$(echo "$ligne" | awk '{print $11}' | cut -c1-20)

        printf "%-8s CPU:%4s%% MEM:%4s%% %s\n" "$user" "$cpu" "$mem" "$cmd"
    done
}

# Nettoyage rapide et sûr
nettoyage_simple() {
    dire_couleur "🧹 Nettoyage simple et sûr" $JAUNE
    echo "──────────────────────────"

    local nettoye=0

    # Seulement dans le dossier actuel et sécurisé
    for pattern in "*.tmp" "*~" ".DS_Store"; do
        if ls $pattern >/dev/null 2>&1; then
            rm -f $pattern 2>/dev/null && {
                dire_couleur "🗑️ Supprimé: $pattern" $VERT
                ((nettoye++))
            }
        fi
    done

    if [[ $nettoye -eq 0 ]]; then
        dire_couleur "✅ Dossier déjà propre" $VERT
    else
        dire_couleur "✅ $nettoye type(s) de fichiers nettoyés" $VERT
    fi
}

# Recherche simple de fichier
chercher_simple() {
    local nom="$1"

    if [[ -z "$nom" ]]; then
        dire_couleur "❌ Usage: chercher_simple <nom_fichier>" $ROUGE
        return 1
    fi

    dire_couleur "🔍 Recherche de '$nom' dans le dossier actuel..." $CYAN

    # Utiliser find de base, très compatible
    find . -name "*$nom*" -type f 2>/dev/null | head -10 | while read fichier; do
        dire_couleur "📄 $fichier" $VERT
    done
}

# Check rapide du système
check_rapide() {
    dire_couleur "🔍 CHECK RAPIDE SYSTÈME" $BLEU
    echo "═══════════════════════"
    echo

    info_express
    echo
    test_internet
    echo
    espace_disque
    echo
    top_processus
}

# ========== ALIASES SIMPLES ==========

# Aliases sans problème de syntaxe
alias info='info_express'
alias net='test_internet'
alias espace='espace_disque'
alias processes='top_processus'
alias propre='nettoyage_simple'
alias chercher='chercher_simple'
alias check='check_rapide'

# ========== AIDE ==========

aide_module_simple() {
    dire_couleur "💡 MODULE SIMPLE - COMMANDES DISPONIBLES" $BLEU
    echo "══════════════════════════════════════════"
    echo
    dire_couleur "🔧 Commandes principales:" $CYAN
    echo "  info               # Informations système express"
    echo "  check              # Check rapide complet"
    echo "  net                # Test connexion Internet"
    echo "  espace             # Espace disque principal"
    echo "  processes          # Top processus gourmands"
    echo "  propre             # Nettoyage sûr dossier actuel"
    echo "  chercher <nom>     # Recherche fichier par nom"
    echo
    dire_couleur "💡 Exemples d'usage:" $CYAN
    echo "  check              # Diagnostic rapide"
    echo "  chercher script    # Trouver fichiers avec 'script'"
    echo "  info && net        # Infos + test Internet"
}

alias aide-simple='aide_module_simple'

# Message de chargement
dire_couleur "✅ Module simple chargé - tapez 'aide-simple'" $VERT