#!/usr/bin/env bash
# ============================================================
# Module : utilitaires_systeme.sh
# Objectif : Petits utilitaires système pratiques et maintenables
# Usage : source utilitaires_systeme.sh
# Style : Code français, fonctions courtes, faciles à comprendre
# ============================================================

# Couleurs pour les messages
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

afficher_message() {
    local message="$1"
    local couleur="${2:-$NC}"
    echo -e "${couleur}${message}${NC}"
}

# ========== INFORMATIONS SYSTÈME ==========

afficher_info_rapide() {
    afficher_message "📊 Informations système rapides" $CYAN
    echo "─────────────────────────────────"

    local memoire_mb=$(free -m | awk 'NR==2{print $2}')
    local memoire_utilisee=$(free -m | awk 'NR==2{printf "%.0f", $3/$2*100}')
    local processeur_cores=$(nproc)
    local charge_cpu=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

    echo "💾 Mémoire: ${memoire_mb}MB (${memoire_utilisee}% utilisé)"
    echo "⚙️ CPU: ${processeur_cores} cœurs (charge: ${charge_cpu})"
    echo "🖥️ Uptime: $(uptime -p | sed 's/up //')"
    echo "👤 Utilisateur: $(whoami)"
}

verifier_espace_disque() {
    afficher_message "💿 Vérification espace disque" $CYAN
    echo "──────────────────────────────"

    # Afficher l'espace des répertoires principaux
    df -h / /home 2>/dev/null | grep -v "Filesystem" | while read ligne; do
        local utilisation=$(echo "$ligne" | awk '{print $5}' | sed 's/%//')
        local point_montage=$(echo "$ligne" | awk '{print $6}')
        local espace_libre=$(echo "$ligne" | awk '{print $4}')

        if [[ $utilisation -gt 90 ]]; then
            afficher_message "🚨 $point_montage: ${utilisation}% (${espace_libre} libre)" $ROUGE
        elif [[ $utilisation -gt 80 ]]; then
            afficher_message "⚠️ $point_montage: ${utilisation}% (${espace_libre} libre)" $JAUNE
        else
            afficher_message "✅ $point_montage: ${utilisation}% (${espace_libre} libre)" $VERT
        fi
    done
}

afficher_processus_gourmands() {
    afficher_message "🔥 Top 5 processus les plus gourmands" $CYAN
    echo "────────────────────────────────────────"

    # Affichage simplifié et lisible
    ps aux --sort=-%cpu | head -6 | tail -5 | while read ligne; do
        local utilisateur=$(echo "$ligne" | awk '{print $1}')
        local cpu=$(echo "$ligne" | awk '{print $3}')
        local memoire=$(echo "$ligne" | awk '{print $4}')
        local commande=$(echo "$ligne" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-30)

        printf "%-8s CPU:%4s%% MEM:%4s%% %s\n" "$utilisateur" "$cpu" "$memoire" "$commande"
    done
}

# ========== NETTOYAGE SYSTÈME ==========

nettoyer_cache_simple() {
    afficher_message "🧹 Nettoyage cache simple" $JAUNE
    echo "─────────────────────────"

    # Nettoyage sécurisé et simple
    local taille_avant=$(df / | tail -1 | awk '{print $3}')

    # Cache apt
    if command -v apt-get >/dev/null; then
        sudo apt-get clean >/dev/null 2>&1
        afficher_message "✅ Cache APT nettoyé" $VERT
    fi

    # Logs anciens (garde 7 jours)
    sudo journalctl --vacuum-time=7d >/dev/null 2>&1
    afficher_message "✅ Logs anciens supprimés" $VERT

    # Cache utilisateur (si existe)
    if [[ -d "$HOME/.cache" ]]; then
        local cache_taille=$(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)
        afficher_message "📁 Cache utilisateur: $cache_taille" $CYAN
    fi

    local taille_apres=$(df / | tail -1 | awk '{print $3}')
    local espace_libere=$((taille_avant - taille_apres))

    if [[ $espace_libere -gt 0 ]]; then
        afficher_message "💾 Espace libéré: ${espace_libere}KB" $VERT
    else
        afficher_message "💾 Système déjà propre" $VERT
    fi
}

supprimer_paquets_orphelins() {
    afficher_message "📦 Suppression paquets orphelins" $JAUNE
    echo "─────────────────────────────────"

    if command -v apt-get >/dev/null; then
        local orphelins=$(apt list --installed 2>/dev/null | grep -c "installé automatiquement" || echo "0")

        if [[ $orphelins -gt 0 ]]; then
            afficher_message "🔍 $orphelins paquets orphelins trouvés" $CYAN
            sudo apt-get autoremove -y >/dev/null 2>&1
            afficher_message "✅ Paquets orphelins supprimés" $VERT
        else
            afficher_message "✅ Aucun paquet orphelin" $VERT
        fi
    fi
}

# ========== SURVEILLANCE RAPIDE ==========

verifier_services_essentiels() {
    afficher_message "🔧 Vérification services essentiels" $CYAN
    echo "────────────────────────────────────"

    local services=("ssh" "systemd-resolved" "cron")

    for service in "${services[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            afficher_message "✅ $service: actif" $VERT
        else
            afficher_message "❌ $service: inactif" $ROUGE
        fi
    done

    # Vérifier connexion réseau
    if ping -c1 8.8.8.8 >/dev/null 2>&1; then
        afficher_message "✅ Connexion Internet: OK" $VERT
    else
        afficher_message "❌ Connexion Internet: problème" $ROUGE
    fi
}

surveiller_temperature() {
    afficher_message "🌡️ Surveillance température" $CYAN
    echo "──────────────────────────"

    # Vérifier si sensors est disponible
    if command -v sensors >/dev/null; then
        local temp=$(sensors 2>/dev/null | grep -E "Core|temp" | head -3)
        if [[ -n "$temp" ]]; then
            echo "$temp"
        else
            afficher_message "ℹ️ Capteurs température non disponibles" $JAUNE
        fi
    else
        afficher_message "ℹ️ Commande 'sensors' non installée" $JAUNE
        afficher_message "💡 Installation: sudo apt install lm-sensors" $CYAN
    fi
}

# ========== FONCTIONS DE MAINTENANCE ==========

maintenance_rapide() {
    afficher_message "🔧 MAINTENANCE RAPIDE SYSTÈME" $BLEU
    echo "════════════════════════════════"
    echo

    afficher_info_rapide
    echo
    verifier_espace_disque
    echo
    verifier_services_essentiels
    echo

    # Proposer nettoyage si nécessaire
    local espace_racine=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $espace_racine -gt 85 ]]; then
        afficher_message "⚠️ Espace disque faible, nettoyage recommandé" $JAUNE
        read -p "Lancer nettoyage automatique ? (o/N): " reponse
        if [[ "$reponse" =~ ^[oO]$ ]]; then
            nettoyer_cache_simple
            supprimer_paquets_orphelins
        fi
    fi

    afficher_message "✅ Maintenance rapide terminée" $VERT
}

diagnostic_complet() {
    afficher_message "🔍 DIAGNOSTIC SYSTÈME COMPLET" $BLEU
    echo "═════════════════════════════════"
    echo

    afficher_info_rapide
    echo
    verifier_espace_disque
    echo
    afficher_processus_gourmands
    echo
    verifier_services_essentiels
    echo
    surveiller_temperature
    echo

    afficher_message "📋 Diagnostic terminé" $VERT
}

# ========== ALIASES PRATIQUES ==========

# Aliases pour les fonctions (à charger dans le shell)
alias info-systeme='afficher_info_rapide'
alias verif-disque='verifier_espace_disque'
alias top-processus='afficher_processus_gourmands'
alias nettoyage-rapide='nettoyer_cache_simple && supprimer_paquets_orphelins'
alias maintenance='maintenance_rapide'
alias diagnostic='diagnostic_complet'
alias verif-services='verifier_services_essentiels'
alias temperature='surveiller_temperature'

# Export des fonctions pour qu'elles soient disponibles
export -f afficher_message afficher_info_rapide verifier_espace_disque
export -f afficher_processus_gourmands nettoyer_cache_simple supprimer_paquets_orphelins
export -f verifier_services_essentiels surveiller_temperature
export -f maintenance_rapide diagnostic_complet

afficher_message "✅ Utilitaires système chargés" $VERT
afficher_message "💡 Tapez 'maintenance' pour un check rapide" $CYAN