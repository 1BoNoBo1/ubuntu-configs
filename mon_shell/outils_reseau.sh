#!/usr/bin/env bash
# ============================================================
# Module : outils_reseau.sh
# Objectif : Outils réseau et connectivité simplifiés
# Usage : source outils_reseau.sh
# Style : Fonctions courtes, diagnostic réseau pratique
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[0;35m'
NC='\033[0m'

afficher_msg() {
    echo -e "${2:-$NC}$1${NC}"
}

# ========== DIAGNOSTIC RÉSEAU ==========

info_reseau_rapide() {
    afficher_msg "🌐 DIAGNOSTIC RÉSEAU RAPIDE" $BLEU
    echo "═══════════════════════════════"

    # Interface principale
    local interface=$(ip route | grep default | awk '{print $5}' | head -1)
    local ip_local=$(ip addr show "$interface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)

    afficher_msg "🔗 Interface: $interface" $CYAN
    afficher_msg "📍 IP locale: $ip_local" $CYAN

    # Passerelle
    local passerelle=$(ip route | grep default | awk '{print $3}' | head -1)
    afficher_msg "🚪 Passerelle: $passerelle" $CYAN

    # Test connectivité
    afficher_msg "🌍 Tests de connectivité:" $CYAN

    if ping -c1 -W2 "$passerelle" >/dev/null 2>&1; then
        afficher_msg "  ✅ Passerelle accessible" $VERT
    else
        afficher_msg "  ❌ Passerelle inaccessible" $ROUGE
    fi

    if ping -c1 -W3 8.8.8.8 >/dev/null 2>&1; then
        afficher_msg "  ✅ Internet accessible" $VERT
    else
        afficher_msg "  ❌ Pas de connexion Internet" $ROUGE
    fi

    if nslookup google.com >/dev/null 2>&1; then
        afficher_msg "  ✅ DNS fonctionne" $VERT
    else
        afficher_msg "  ❌ Problème DNS" $ROUGE
    fi
}

tester_vitesse_simple() {
    afficher_msg "⚡ Test de vitesse simplifié" $CYAN
    echo "─────────────────────────────"

    afficher_msg "📊 Test latence vers 8.8.8.8..." $JAUNE
    local ping_result=$(ping -c4 8.8.8.8 2>/dev/null | tail -1)
    if [[ -n "$ping_result" ]]; then
        echo "   $ping_result"
    else
        afficher_msg "   ❌ Test échoué" $ROUGE
    fi

    # Test simple de bande passante avec curl si wget/curl disponible
    if command -v curl >/dev/null; then
        afficher_msg "📥 Test téléchargement (1MB)..." $JAUNE
        local start_time=$(date +%s%N)
        if curl -s -o /dev/null -w "%{http_code}" "http://ipv4.download.thinkbroadband.com/1MB.zip" | grep -q "200"; then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))
            local speed=$(( 1000 * 1000 / duration ))
            afficher_msg "   ✅ ~${speed} KB/s" $VERT
        else
            afficher_msg "   ⚠️ Test non disponible" $JAUNE
        fi
    else
        afficher_msg "📥 curl non disponible pour test vitesse" $JAUNE
    fi
}

scanner_ports_locaux() {
    afficher_msg "🔍 PORTS OUVERTS LOCALEMENT" $BLEU
    echo "═══════════════════════════"

    afficher_msg "📡 Ports en écoute:" $CYAN

    # Utiliser netstat ou ss selon disponibilité
    if command -v ss >/dev/null; then
        ss -tlnp 2>/dev/null | grep LISTEN | head -10 | while read ligne; do
            local port=$(echo "$ligne" | awk '{print $4}' | cut -d: -f2)
            local process=$(echo "$ligne" | awk '{print $6}' | cut -d, -f2 | cut -d= -f2 | cut -d: -f1)
            printf "   %-6s %s\n" "$port" "${process:-inconnu}"
        done
    elif command -v netstat >/dev/null; then
        netstat -tlnp 2>/dev/null | grep LISTEN | head -10 | while read ligne; do
            local port=$(echo "$ligne" | awk '{print $4}' | cut -d: -f2)
            local process=$(echo "$ligne" | awk '{print $7}' | cut -d/ -f2)
            printf "   %-6s %s\n" "$port" "${process:-inconnu}"
        done
    else
        afficher_msg "   ⚠️ netstat/ss non disponible" $JAUNE
    fi
}

# ========== OUTILS WIFI ==========

info_wifi() {
    afficher_msg "📶 INFORMATIONS WIFI" $BLEU
    echo "══════════════════════"

    # Interface WiFi
    local wifi_interface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)

    if [[ -z "$wifi_interface" ]]; then
        afficher_msg "❌ Aucune interface WiFi trouvée" $ROUGE
        return 1
    fi

    afficher_msg "📡 Interface: $wifi_interface" $CYAN

    # Réseau connecté
    local ssid=$(iw dev "$wifi_interface" link 2>/dev/null | grep SSID | awk '{print $2}')
    if [[ -n "$ssid" ]]; then
        afficher_msg "🌐 SSID: $ssid" $VERT

        # Signal strength
        local signal=$(iw dev "$wifi_interface" link 2>/dev/null | grep signal | awk '{print $2 " " $3}')
        if [[ -n "$signal" ]]; then
            afficher_msg "📶 Signal: $signal" $CYAN
        fi
    else
        afficher_msg "❌ Non connecté au WiFi" $ROUGE
    fi
}

scanner_wifi() {
    afficher_msg "🔎 SCAN RÉSEAUX WIFI DISPONIBLES" $BLEU
    echo "════════════════════════════════"

    local wifi_interface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)

    if [[ -z "$wifi_interface" ]]; then
        afficher_msg "❌ Interface WiFi non trouvée" $ROUGE
        return 1
    fi

    afficher_msg "🔍 Scan en cours..." $JAUNE

    # Scan avec timeout
    if timeout 10 iw dev "$wifi_interface" scan 2>/dev/null | grep -E "(SSID:|signal:)" | paste - - 2>/dev/null | head -10 | while read ligne; do
        local ssid=$(echo "$ligne" | grep -o "SSID: [^[:space:]]*" | cut -d' ' -f2)
        local signal=$(echo "$ligne" | grep -o "signal: [^[:space:]]*" | cut -d' ' -f2)

        if [[ -n "$ssid" && "$ssid" != "" ]]; then
            printf "   %-20s %s\n" "$ssid" "${signal:-N/A}"
        fi
    done; then
        afficher_msg "✅ Scan terminé" $VERT
    else
        afficher_msg "⚠️ Scan échoué ou pas de permissions" $JAUNE
    fi
}

# ========== OUTILS UTILITAIRES ==========

mon_ip_publique() {
    afficher_msg "🌍 Recherche IP publique..." $CYAN

    # Essayer plusieurs services
    local ip=""

    # Service 1
    ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null)

    # Service 2 si échec
    if [[ -z "$ip" ]]; then
        ip=$(curl -s --connect-timeout 5 icanhazip.com 2>/dev/null)
    fi

    # Service 3 si échec
    if [[ -z "$ip" ]]; then
        ip=$(curl -s --connect-timeout 5 ipecho.net/plain 2>/dev/null)
    fi

    if [[ -n "$ip" ]]; then
        afficher_msg "🌐 Votre IP publique: $ip" $VERT
    else
        afficher_msg "❌ Impossible de récupérer l'IP publique" $ROUGE
    fi
}

tester_dns() {
    local domaine="${1:-google.com}"

    afficher_msg "🔍 Test DNS pour: $domaine" $CYAN
    echo "────────────────────────────"

    # Test nslookup
    if command -v nslookup >/dev/null; then
        afficher_msg "📋 Résolution DNS:" $JAUNE
        nslookup "$domaine" 2>/dev/null | grep -E "(Address|Nom|Name)" | head -3
    fi

    # Test dig si disponible
    if command -v dig >/dev/null; then
        afficher_msg "⚡ Temps de réponse:" $JAUNE
        local temps=$(dig +short +time=3 "$domaine" | tail -1)
        if [[ -n "$temps" ]]; then
            afficher_msg "   ✅ Résolu: $temps" $VERT
        fi
    fi
}

verifier_connectivite() {
    afficher_msg "🚦 VÉRIFICATION CONNECTIVITÉ COMPLÈTE" $BLEU
    echo "═══════════════════════════════════════"

    # Tests progressifs
    afficher_msg "1️⃣ Interface réseau..." $CYAN
    info_reseau_rapide

    echo
    afficher_msg "2️⃣ WiFi (si applicable)..." $CYAN
    info_wifi

    echo
    afficher_msg "3️⃣ IP publique..." $CYAN
    mon_ip_publique

    echo
    afficher_msg "4️⃣ Test DNS..." $CYAN
    tester_dns
}

# ========== ALIASES ==========

alias net-info='info_reseau_rapide'
alias wifi-info='info_wifi'
alias wifi-scan='scanner_wifi'
alias ip-pub='mon_ip_publique'
alias test-net='verifier_connectivite'
alias vitesse='tester_vitesse_simple'
alias ports='scanner_ports_locaux'
alias dns='tester_dns'

# ========== AIDE ==========

aide_reseau() {
    afficher_msg "🌐 OUTILS RÉSEAU" $BLEU
    echo "═══════════════════"
    echo
    afficher_msg "🔧 Diagnostic:" $CYAN
    echo "  net-info                # Infos réseau rapides"
    echo "  test-net                # Vérification complète"
    echo "  vitesse                 # Test vitesse simple"
    echo "  ports                   # Ports ouverts locaux"
    echo
    afficher_msg "📶 WiFi:" $CYAN
    echo "  wifi-info               # État WiFi actuel"
    echo "  wifi-scan               # Scanner réseaux"
    echo
    afficher_msg "🌍 Internet:" $CYAN
    echo "  ip-pub                  # Mon IP publique"
    echo "  dns [domaine]           # Test DNS"
    echo
    afficher_msg "💡 Exemples:" $JAUNE
    echo "  net-info                # Diagnostic rapide"
    echo "  test-net                # Check complet"
    echo "  dns github.com          # Test DNS GitHub"
}

alias aide-reseau='aide_reseau'

afficher_msg "✅ Outils réseau chargés" $VERT
afficher_msg "💡 Tapez 'aide-reseau' pour voir toutes les commandes" $CYAN