#!/usr/bin/env bash
# ============================================================
# Module : outils_productivite.sh
# Objectif : Outils de productivité quotidienne
# Usage : source outils_productivite.sh
# Style : Fonctions courtes, pratiques, gain de temps
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[0;35m'
NC='\033[0m'

msg_couleur() {
    echo -e "${2:-$NC}$1${NC}"
}

# ========== GESTIONNAIRE DE NOTES RAPIDES ==========

prendre_note() {
    local note="$*"
    local fichier_notes="$HOME/.notes_rapides.txt"
    local horodatage=$(date "+%Y-%m-%d %H:%M")

    if [[ -z "$note" ]]; then
        msg_couleur "❌ Usage: prendre_note <votre note>" $ROUGE
        return 1
    fi

    echo "[$horodatage] $note" >> "$fichier_notes"
    msg_couleur "✅ Note ajoutée" $VERT
}

voir_notes() {
    local fichier_notes="$HOME/.notes_rapides.txt"
    local nombre="${1:-10}"

    if [[ ! -f "$fichier_notes" ]]; then
        msg_couleur "📝 Aucune note trouvée" $JAUNE
        msg_couleur "💡 Créez une note: prendre_note <texte>" $CYAN
        return
    fi

    msg_couleur "📝 Dernières $nombre notes:" $CYAN
    echo "─────────────────────────"
    tail -n "$nombre" "$fichier_notes" | while read ligne; do
        echo "$ligne"
    done
}

chercher_notes() {
    local terme="$1"
    local fichier_notes="$HOME/.notes_rapides.txt"

    if [[ -z "$terme" ]]; then
        msg_couleur "❌ Usage: chercher_notes <terme>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier_notes" ]]; then
        msg_couleur "📝 Aucune note trouvée" $JAUNE
        return
    fi

    msg_couleur "🔍 Notes contenant '$terme':" $CYAN
    echo "──────────────────────────"
    grep -i "$terme" "$fichier_notes" || msg_couleur "❌ Aucune note trouvée" $JAUNE
}

nettoyer_notes() {
    local fichier_notes="$HOME/.notes_rapides.txt"
    local sauvegarde="$HOME/.notes_rapides_$(date +%Y%m%d).txt"

    if [[ ! -f "$fichier_notes" ]]; then
        msg_couleur "📝 Aucune note à nettoyer" $JAUNE
        return
    fi

    cp "$fichier_notes" "$sauvegarde"
    > "$fichier_notes"
    msg_couleur "✅ Notes nettoyées (sauvegarde: $(basename "$sauvegarde"))" $VERT
}

# ========== TIMER POMODORO SIMPLE ==========

pomodoro() {
    local duree="${1:-25}"

    msg_couleur "🍅 POMODORO $duree minutes - Début !" $ROUGE
    msg_couleur "⏰ Démarré à $(date '+%H:%M')" $CYAN

    # Calcul en secondes
    local secondes=$((duree * 60))

    # Affichage du temps restant toutes les 5 minutes
    while [[ $secondes -gt 0 ]]; do
        local minutes=$((secondes / 60))
        local secs=$((secondes % 60))

        if [[ $((secondes % 300)) -eq 0 ]] || [[ $secondes -le 60 ]]; then
            printf "\r⏱️  Temps restant: %02d:%02d   " $minutes $secs
        fi

        sleep 1
        ((secondes--))
    done

    echo
    msg_couleur "🔔 POMODORO TERMINÉ ! Prenez une pause." $VERT
    msg_couleur "⏰ Fini à $(date '+%H:%M')" $CYAN

    # Son de notification si possible
    which beep >/dev/null 2>&1 && beep -f 800 -l 200 -r 3 2>/dev/null || true
}

pause_courte() {
    local duree="${1:-5}"
    msg_couleur "☕ Pause courte $duree minutes" $JAUNE

    local secondes=$((duree * 60))
    sleep $secondes

    msg_couleur "🔔 Pause terminée ! Retour au travail." $VERT
}

# ========== CALCULATRICE RAPIDE ==========

calculer() {
    local expression="$*"

    if [[ -z "$expression" ]]; then
        msg_couleur "❌ Usage: calculer <expression>" $ROUGE
        msg_couleur "💡 Exemples: calculer 2+2, calculer 15*3, calculer 100/4" $CYAN
        return 1
    fi

    # Utiliser bc si disponible, sinon bash
    if command -v bc >/dev/null; then
        local resultat=$(echo "scale=2; $expression" | bc 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            msg_couleur "🔢 $expression = $resultat" $VERT
        else
            msg_couleur "❌ Expression invalide" $ROUGE
        fi
    else
        # Calcul simple avec bash (entiers uniquement)
        local resultat=$((expression))
        msg_couleur "🔢 $expression = $resultat" $VERT
    fi
}

convertir_unite() {
    local valeur="$1"
    local unite="$2"

    if [[ -z "$valeur" ]] || [[ -z "$unite" ]]; then
        msg_couleur "❌ Usage: convertir_unite <valeur> <unite>" $ROUGE
        msg_couleur "💡 Unités: ko_mo, mo_go, cm_m, m_km, c_f, f_c" $CYAN
        return 1
    fi

    case "$unite" in
        "ko_mo")
            local resultat=$(echo "scale=2; $valeur / 1024" | bc 2>/dev/null)
            msg_couleur "💾 $valeur Ko = $resultat Mo" $VERT
            ;;
        "mo_go")
            local resultat=$(echo "scale=2; $valeur / 1024" | bc 2>/dev/null)
            msg_couleur "💾 $valeur Mo = $resultat Go" $VERT
            ;;
        "cm_m")
            local resultat=$(echo "scale=2; $valeur / 100" | bc 2>/dev/null)
            msg_couleur "📏 $valeur cm = $resultat m" $VERT
            ;;
        "m_km")
            local resultat=$(echo "scale=3; $valeur / 1000" | bc 2>/dev/null)
            msg_couleur "📏 $valeur m = $resultat km" $VERT
            ;;
        "c_f")
            local resultat=$(echo "scale=1; ($valeur * 9/5) + 32" | bc 2>/dev/null)
            msg_couleur "🌡️ $valeur°C = $resultat°F" $VERT
            ;;
        "f_c")
            local resultat=$(echo "scale=1; ($valeur - 32) * 5/9" | bc 2>/dev/null)
            msg_couleur "🌡️ $valeur°F = $resultat°C" $VERT
            ;;
        *)
            msg_couleur "❌ Unité '$unite' non supportée" $ROUGE
            ;;
    esac
}

# ========== GÉNÉRATEUR DE MOTS DE PASSE ==========

generer_mdp() {
    local longueur="${1:-12}"
    local type="${2:-mixte}"

    msg_couleur "🔐 Génération mot de passe ($longueur caractères)" $CYAN

    local caracteres=""
    case "$type" in
        "simple")
            caracteres="abcdefghijklmnopqrstuvwxyz0123456789"
            ;;
        "complet")
            caracteres="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
            ;;
        "mixte"|*)
            caracteres="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            ;;
    esac

    local mdp=""
    for ((i=0; i<longueur; i++)); do
        local index=$((RANDOM % ${#caracteres}))
        mdp="${mdp}${caracteres:$index:1}"
    done

    msg_couleur "🔑 Mot de passe: $mdp" $VERT
    msg_couleur "💡 Copiez rapidement avant de l'oublier !" $JAUNE
}

generer_pin() {
    local longueur="${1:-4}"

    local pin=""
    for ((i=0; i<longueur; i++)); do
        pin="${pin}$((RANDOM % 10))"
    done

    msg_couleur "🔢 Code PIN ($longueur chiffres): $pin" $VERT
}

# ========== UTILITAIRES TEXTE ==========

compter_mots() {
    local texte="$*"

    if [[ -z "$texte" ]]; then
        msg_couleur "❌ Usage: compter_mots <texte ou fichier>" $ROUGE
        return 1
    fi

    # Si c'est un fichier
    if [[ -f "$texte" ]]; then
        local mots=$(wc -w < "$texte")
        local lignes=$(wc -l < "$texte")
        local caracteres=$(wc -c < "$texte")

        msg_couleur "📄 Statistiques fichier $(basename "$texte"):" $CYAN
        echo "   📝 Lignes: $lignes"
        echo "   📖 Mots: $mots"
        echo "   🔤 Caractères: $caracteres"
    else
        # Si c'est du texte direct
        local mots=$(echo "$texte" | wc -w)
        local caracteres=$(echo -n "$texte" | wc -c)

        msg_couleur "📝 Statistiques texte:" $CYAN
        echo "   📖 Mots: $mots"
        echo "   🔤 Caractères: $caracteres"
    fi
}

nettoyer_texte() {
    local texte="$*"

    if [[ -z "$texte" ]]; then
        msg_couleur "❌ Usage: nettoyer_texte <texte>" $ROUGE
        return 1
    fi

    # Supprimer espaces multiples, tabulations, retours à la ligne
    local propre=$(echo "$texte" | tr -s ' ' | tr -d '\t' | tr '\n' ' ')

    msg_couleur "✨ Texte nettoyé:" $VERT
    echo "$propre"
}

# ========== ORGANISATEUR DE TÂCHES SIMPLE ==========

ajouter_tache() {
    local tache="$*"
    local fichier_taches="$HOME/.taches_todo.txt"

    if [[ -z "$tache" ]]; then
        msg_couleur "❌ Usage: ajouter_tache <description tâche>" $ROUGE
        return 1
    fi

    local id=$(date +%s | tail -c 4)  # 4 derniers chiffres timestamp
    echo "[ ] #$id $tache" >> "$fichier_taches"
    msg_couleur "✅ Tâche #$id ajoutée" $VERT
}

voir_taches() {
    local fichier_taches="$HOME/.taches_todo.txt"

    if [[ ! -f "$fichier_taches" ]]; then
        msg_couleur "📋 Aucune tâche trouvée" $JAUNE
        msg_couleur "💡 Ajoutez une tâche: ajouter_tache <description>" $CYAN
        return
    fi

    msg_couleur "📋 Vos tâches en cours:" $CYAN
    echo "─────────────────────"

    local numero=1
    while read ligne; do
        if [[ "$ligne" =~ ^\[\ \] ]]; then
            msg_couleur "$numero) ${ligne#* }" $JAUNE
        elif [[ "$ligne" =~ ^\[x\] ]]; then
            msg_couleur "$numero) ${ligne#* } ✓" $VERT
        fi
        ((numero++))
    done < "$fichier_taches"
}

finir_tache() {
    local id="$1"
    local fichier_taches="$HOME/.taches_todo.txt"

    if [[ -z "$id" ]]; then
        msg_couleur "❌ Usage: finir_tache <id>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier_taches" ]]; then
        msg_couleur "📋 Aucune tâche trouvée" $JAUNE
        return
    fi

    # Marquer comme terminée
    sed -i "s/\[ \] #$id/[x] #$id/" "$fichier_taches" 2>/dev/null
    msg_couleur "✅ Tâche #$id marquée comme terminée" $VERT
}

# ========== ALIASES PRATIQUES ==========

alias note='prendre_note'
alias notes='voir_notes'
alias cherche-note='chercher_notes'
alias mdp='generer_mdp'
alias pin='generer_pin'
alias calc='calculer'
alias convertir='convertir_unite'
alias compte-mots='compter_mots'
alias tache='ajouter_tache'
alias taches='voir_taches'
alias fini='finir_tache'

# ========== AIDE ==========

aide_productivite() {
    msg_couleur "🚀 OUTILS DE PRODUCTIVITÉ" $BLEU
    echo "═════════════════════════"
    echo
    msg_couleur "📝 Notes rapides:" $CYAN
    echo "  note <texte>            # Prendre une note"
    echo "  notes [nombre]          # Voir dernières notes"
    echo "  cherche-note <terme>    # Chercher dans notes"
    echo
    msg_couleur "🍅 Pomodoro:" $CYAN
    echo "  pomodoro [minutes]      # Timer Pomodoro (défaut: 25min)"
    echo "  pause_courte [minutes]  # Pause courte (défaut: 5min)"
    echo
    msg_couleur "🔢 Calculs:" $CYAN
    echo "  calc 2+2                # Calculatrice rapide"
    echo "  convertir 1024 ko_mo    # Convertir unités"
    echo
    msg_couleur "🔐 Sécurité:" $CYAN
    echo "  mdp [longueur] [type]   # Générer mot de passe"
    echo "  pin [longueur]          # Générer code PIN"
    echo
    msg_couleur "📄 Texte:" $CYAN
    echo "  compte-mots <texte>     # Compter mots/caractères"
    echo "  nettoyer_texte <texte>  # Nettoyer espaces/tabs"
    echo
    msg_couleur "📋 Tâches:" $CYAN
    echo "  tache <description>     # Ajouter tâche"
    echo "  taches                  # Voir tâches"
    echo "  fini <id>              # Marquer tâche terminée"
    echo
    msg_couleur "💡 Exemples d'usage:" $JAUNE
    echo "  note Acheter du pain"
    echo "  pomodoro 25"
    echo "  calc 15*8+20"
    echo "  mdp 16 complet"
}

alias aide-productivite='aide_productivite'

msg_couleur "✅ Outils productivité chargés" $VERT
msg_couleur "💡 Tapez 'aide-productivite' pour voir toutes les commandes" $CYAN