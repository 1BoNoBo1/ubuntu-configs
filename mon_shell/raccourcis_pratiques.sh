#!/usr/bin/env bash
# ============================================================
# Module : raccourcis_pratiques.sh
# Objectif : Raccourcis et fonctions courtes très pratiques
# Usage : source raccourcis_pratiques.sh
# Style : Ultra-simple, noms courts, gain de temps maximum
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

msg() {
    echo -e "${2:-$NC}$1${NC}"
}

# ========== RACCOURCIS NAVIGATION ==========

# Navigation rapide vers dossiers courants
alias home='cd ~'
alias bureau='cd ~/Desktop'
alias docs='cd ~/Documents'
alias telechargements='cd ~/Downloads'
alias images='cd ~/Pictures'
alias musique='cd ~/Music'
alias videos='cd ~/Videos'

# Navigation intelligente
monter() { cd ..; }
redescendre() { cd -; }

aller() {
    local destination="$1"
    if [[ -z "$destination" ]]; then
        msg "❌ Usage: aller <dossier>" $ROUGE
        return 1
    fi

    if [[ -d "$destination" ]]; then
        cd "$destination" && ls
    else
        msg "❌ Dossier '$destination' introuvable" $ROUGE
    fi
}

# ========== RACCOURCIS FICHIERS ==========

# Création rapide
nouveau() {
    local nom="$1"
    if [[ -z "$nom" ]]; then
        msg "❌ Usage: nouveau <nom_fichier>" $ROUGE
        return 1
    fi
    touch "$nom" && msg "✅ Fichier '$nom' créé" $VERT
}

dossier() {
    local nom="$1"
    if [[ -z "$nom" ]]; then
        msg "❌ Usage: dossier <nom_dossier>" $ROUGE
        return 1
    fi
    mkdir -p "$nom" && msg "✅ Dossier '$nom' créé" $VERT
}

# Copie/déplacement simple
dupliquer() {
    local source="$1"
    local copie="${2:-${source}.copie}"

    if [[ ! -e "$source" ]]; then
        msg "❌ '$source' introuvable" $ROUGE
        return 1
    fi

    cp -r "$source" "$copie" && msg "✅ '$source' dupliqué vers '$copie'" $VERT
}

renommer() {
    local ancien="$1"
    local nouveau="$2"

    if [[ -z "$ancien" ]] || [[ -z "$nouveau" ]]; then
        msg "❌ Usage: renommer <ancien_nom> <nouveau_nom>" $ROUGE
        return 1
    fi

    if [[ ! -e "$ancien" ]]; then
        msg "❌ '$ancien' introuvable" $ROUGE
        return 1
    fi

    mv "$ancien" "$nouveau" && msg "✅ '$ancien' renommé en '$nouveau'" $VERT
}

# ========== RACCOURCIS AFFICHAGE ==========

# Affichage intelligent de fichiers
voir() {
    local fichier="$1"

    if [[ -z "$fichier" ]]; then
        # Pas de fichier spécifié, lister le dossier
        if command -v exa >/dev/null; then
            exa -la --color=always
        else
            ls -la --color=always
        fi
        return
    fi

    if [[ ! -e "$fichier" ]]; then
        msg "❌ '$fichier' introuvable" $ROUGE
        return 1
    fi

    # Afficher selon le type
    if [[ -d "$fichier" ]]; then
        if command -v exa >/dev/null; then
            exa -la --color=always "$fichier"
        else
            ls -la --color=always "$fichier"
        fi
    else
        if command -v bat >/dev/null; then
            bat "$fichier"
        else
            cat "$fichier"
        fi
    fi
}

# Affichage taille humaine
taille() {
    local cible="${1:-.}"
    du -sh "$cible" 2>/dev/null | while read taille_item item; do
        msg "📊 $item: $taille_item" $CYAN
    done
}

# ========== RACCOURCIS RECHERCHE ==========

# Recherche ultra-rapide
ou() {
    local nom="$1"
    if [[ -z "$nom" ]]; then
        msg "❌ Usage: ou <nom_fichier>" $ROUGE
        return 1
    fi

    msg "🔍 Recherche de '$nom'..." $CYAN

    if command -v fd >/dev/null; then
        fd "$nom" . 2>/dev/null
    else
        find . -name "*$nom*" 2>/dev/null
    fi
}

dedans() {
    local texte="$1"
    local ou="${2:-.}"

    if [[ -z "$texte" ]]; then
        msg "❌ Usage: dedans <texte> [dossier]" $ROUGE
        return 1
    fi

    msg "🔍 Recherche de '$texte' dans $ou..." $CYAN

    if command -v rg >/dev/null; then
        rg "$texte" "$ou" 2>/dev/null
    else
        grep -r "$texte" "$ou" 2>/dev/null
    fi
}

# ========== RACCOURCIS SYSTÈME ==========

# Information système rapide
info() {
    msg "💻 INFOS SYSTÈME RAPIDES" $BLEU
    echo "────────────────────────"
    echo "💾 RAM: $(free -h | awk 'NR==2{print $3"/"$2}')"
    echo "⚙️ CPU: $(nproc) cœurs"
    echo "🖥️ Uptime: $(uptime -p | sed 's/up //')"
    echo "👤 User: $(whoami)"
    echo "📁 PWD: $(pwd)"
}

# Processus gourmands
gourmands() {
    msg "🔥 TOP 5 PROCESSUS GOURMANDS" $BLEU
    echo "────────────────────────────"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-10s %4s%% %4s%% %s\n", $1, $3, $4, $11}'
}

# Espace disque rapide
espace() {
    msg "💿 ESPACE DISQUE" $BLEU
    echo "───────────────"
    df -h | grep -E '^/|^tmpfs' | while read ligne; do
        echo "$ligne" | awk '{printf "%-15s %5s utilisé / %5s total (%s)\n", $6, $3, $2, $5}'
    done
}

# ========== RACCOURCIS RÉSEAU ==========

# Test connectivité rapide
net() {
    msg "🌐 Test connectivité..." $CYAN
    if ping -c1 8.8.8.8 >/dev/null 2>&1; then
        msg "✅ Internet OK" $VERT
    else
        msg "❌ Pas d'Internet" $ROUGE
    fi
}

# IP rapide
ip_local() {
    msg "🔗 Adresses IP locales:" $CYAN
    ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print "   " $2}' | cut -d'/' -f1
}

# ========== RACCOURCIS UTILES ==========

# Nettoyage rapide
propre() {
    msg "🧹 Nettoyage rapide..." $JAUNE

    # Nettoyage sécurisé
    local nettoye=0

    # Fichiers temporaires dans le dossier actuel
    if ls *.tmp >/dev/null 2>&1; then
        rm *.tmp && ((nettoye++))
    fi

    if ls *~ >/dev/null 2>&1; then
        rm *~ && ((nettoye++))
    fi

    # Cache APT si on est admin
    if [[ $EUID -eq 0 ]]; then
        apt-get clean >/dev/null 2>&1 && ((nettoye++))
    fi

    if [[ $nettoye -gt 0 ]]; then
        msg "✅ $nettoye éléments nettoyés" $VERT
    else
        msg "✅ Déjà propre" $VERT
    fi
}

# Sauvegarde rapide
sauver() {
    local fichier="$1"

    if [[ -z "$fichier" ]]; then
        msg "❌ Usage: sauver <fichier>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier" ]]; then
        msg "❌ Fichier '$fichier' introuvable" $ROUGE
        return 1
    fi

    local horodatage=$(date +"%Y%m%d_%H%M")
    local sauvegarde="${fichier}.sauvegarde_${horodatage}"

    cp "$fichier" "$sauvegarde" && msg "✅ Sauvegarde: $sauvegarde" $VERT
}

# Historique intelligent
quand() {
    local commande="$1"

    if [[ -z "$commande" ]]; then
        msg "📜 Dernières commandes:" $CYAN
        history | tail -10 | awk '{$1=""; print "  " $0}'
    else
        msg "🔍 Recherche '$commande' dans l'historique:" $CYAN
        history | grep "$commande" | tail -5 | awk '{$1=""; print "  " $0}'
    fi
}

# ========== RACCOURCIS RAPIDES ==========

# Aliases ultra-courts pour efficacité maximum
alias ..='cd ..'
alias ...='cd ../..'
alias l='voir'
alias ll='ls -la'
alias la='ls -la'
alias c='clear'
alias h='history'
alias q='exit'

# Navigation rapide
alias -='cd -'
alias ~='cd ~'

# Fichiers rapides
alias v='voir'
alias e='$EDITOR'
alias nano='nano'
alias vim='vim'

# Système rapide
alias ports='netstat -tulpn'
alias proc='ps aux'
alias mem='free -h'
alias cpu='htop'

# Git ultra-rapide
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline'

# ========== FONCTION D'AIDE ==========

raccourcis() {
    msg "⚡ RACCOURCIS PRATIQUES DISPONIBLES" $BLEU
    echo "═══════════════════════════════════"
    echo
    msg "📁 Navigation:" $CYAN
    echo "  aller <dossier>     # Aller dans dossier + lister"
    echo "  monter              # cd .."
    echo "  redescendre         # cd -"
    echo "  home, docs, bureau  # Dossiers courants"
    echo
    msg "📄 Fichiers:" $CYAN
    echo "  nouveau <nom>       # Créer fichier"
    echo "  dossier <nom>       # Créer dossier"
    echo "  voir [fichier]      # Afficher fichier/dossier"
    echo "  dupliquer <src>     # Copier fichier"
    echo "  renommer <old> <new># Renommer"
    echo "  sauver <fichier>    # Sauvegarde horodatée"
    echo
    msg "🔍 Recherche:" $CYAN
    echo "  ou <nom>            # Chercher fichier par nom"
    echo "  dedans <texte>      # Chercher texte dans fichiers"
    echo
    msg "⚙️ Système:" $CYAN
    echo "  info                # Infos système rapides"
    echo "  espace              # Espace disque"
    echo "  gourmands           # Top processus"
    echo "  net                 # Test Internet"
    echo "  propre              # Nettoyage rapide"
    echo
    msg "📜 Aliases courts:" $CYAN
    echo "  l, v = voir         # Affichage"
    echo "  .., ... = cd        # Navigation"
    echo "  c = clear           # Effacer écran"
    echo "  q = exit            # Quitter"
    echo "  gs, ga, gc = git    # Git rapide"
}

# Export des fonctions
export -f msg aller nouveau dossier dupliquer renommer voir taille
export -f ou dedans info gourmands espace net propre sauver quand raccourcis
export -f monter redescendre ip_local

msg "✅ Raccourcis pratiques chargés" $VERT
msg "💡 Tapez 'raccourcis' pour voir tous les raccourcis" $CYAN