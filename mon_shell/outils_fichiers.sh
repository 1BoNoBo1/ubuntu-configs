#!/usr/bin/env bash
# ============================================================
# Module : outils_fichiers.sh
# Objectif : Outils pratiques pour gestion de fichiers
# Usage : source outils_fichiers.sh
# Style : Fonctions courtes, noms français, faciles à maintenir
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

dire() {
    local message="$1"
    local couleur="${2:-$NC}"
    echo -e "${couleur}${message}${NC}"
}

# ========== RECHERCHE INTELLIGENTE ==========

chercher_fichier_nom() {
    local nom_recherche="$1"
    local dossier="${2:-.}"

    if [[ -z "$nom_recherche" ]]; then
        dire "❌ Usage: chercher_fichier_nom <nom> [dossier]" $ROUGE
        return 1
    fi

    dire "🔍 Recherche de '$nom_recherche' dans $dossier..." $CYAN

    # Utiliser fd si disponible, sinon find
    if command -v fd >/dev/null; then
        fd "$nom_recherche" "$dossier" 2>/dev/null
    else
        find "$dossier" -name "*$nom_recherche*" 2>/dev/null
    fi
}

chercher_contenu_fichier() {
    local texte_recherche="$1"
    local dossier="${2:-.}"
    local type_fichier="${3:-}"

    if [[ -z "$texte_recherche" ]]; then
        dire "❌ Usage: chercher_contenu_fichier <texte> [dossier] [extension]" $ROUGE
        return 1
    fi

    dire "🔍 Recherche de '$texte_recherche' dans le contenu..." $CYAN

    local options=""
    if [[ -n "$type_fichier" ]]; then
        options="--include=*.$type_fichier"
    fi

    # Utiliser ripgrep si disponible, sinon grep
    if command -v rg >/dev/null; then
        if [[ -n "$type_fichier" ]]; then
            rg "$texte_recherche" --type "$type_fichier" "$dossier" 2>/dev/null || true
        else
            rg "$texte_recherche" "$dossier" 2>/dev/null || true
        fi
    else
        grep -r $options "$texte_recherche" "$dossier" 2>/dev/null || true
    fi
}

lister_gros_fichiers() {
    local dossier="${1:-.}"
    local nombre="${2:-10}"

    dire "📊 Top $nombre des plus gros fichiers dans $dossier" $CYAN
    echo "──────────────────────────────────────────────"

    # Utiliser du avec tri par taille
    du -ah "$dossier" 2>/dev/null | sort -rh | head -"$nombre" | while read taille fichier; do
        printf "%-8s %s\n" "$taille" "$fichier"
    done
}

# ========== NETTOYAGE FICHIERS ==========

nettoyer_fichiers_temporaires() {
    local dossier="${1:-$HOME}"

    dire "🧹 Nettoyage fichiers temporaires dans $dossier" $JAUNE
    echo "─────────────────────────────────────────────"

    local fichiers_supprimes=0

    # Fichiers temporaires courants
    local patterns=("*.tmp" "*.temp" "*~" ".DS_Store" "Thumbs.db")

    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d '' fichier; do
            if [[ -f "$fichier" ]]; then
                rm -f "$fichier"
                ((fichiers_supprimes++))
                dire "🗑️ Supprimé: $(basename "$fichier")" $VERT
            fi
        done < <(find "$dossier" -name "$pattern" -type f -print0 2>/dev/null)
    done

    if [[ $fichiers_supprimes -eq 0 ]]; then
        dire "✅ Aucun fichier temporaire trouvé" $VERT
    else
        dire "✅ $fichiers_supprimes fichiers temporaires supprimés" $VERT
    fi
}

supprimer_dossiers_vides() {
    local dossier="${1:-.}"

    dire "📁 Suppression dossiers vides dans $dossier" $JAUNE
    echo "──────────────────────────────────────"

    local dossiers_supprimes=0

    # Trouver et supprimer les dossiers vides
    while IFS= read -r -d '' dossier_vide; do
        if [[ -d "$dossier_vide" ]]; then
            rmdir "$dossier_vide" 2>/dev/null && {
                ((dossiers_supprimes++))
                dire "📂 Supprimé: $dossier_vide" $VERT
            }
        fi
    done < <(find "$dossier" -type d -empty -print0 2>/dev/null)

    if [[ $dossiers_supprimes -eq 0 ]]; then
        dire "✅ Aucun dossier vide trouvé" $VERT
    else
        dire "✅ $dossiers_supprimes dossiers vides supprimés" $VERT
    fi
}

# ========== ORGANISATION FICHIERS ==========

organiser_par_extension() {
    local dossier_source="${1:-.}"
    local dossier_cible="${2:-$dossier_source/organisé}"

    dire "📁 Organisation fichiers par extension" $CYAN
    echo "Source: $dossier_source"
    echo "Cible: $dossier_cible"
    echo "──────────────────────────────────"

    # Créer dossier cible
    mkdir -p "$dossier_cible"

    local fichiers_organises=0

    # Parcourir les fichiers du dossier source
    find "$dossier_source" -maxdepth 1 -type f | while read fichier; do
        local nom_fichier=$(basename "$fichier")
        local extension="${nom_fichier##*.}"

        # Si pas d'extension, mettre dans "sans_extension"
        if [[ "$extension" == "$nom_fichier" ]]; then
            extension="sans_extension"
        fi

        local dossier_extension="$dossier_cible/$extension"
        mkdir -p "$dossier_extension"

        # Déplacer le fichier
        if mv "$fichier" "$dossier_extension/"; then
            dire "📄 $nom_fichier → $extension/" $VERT
            ((fichiers_organises++))
        fi
    done

    dire "✅ $fichiers_organises fichiers organisés" $VERT
}

creer_sauvegarde_fichier() {
    local fichier="$1"

    if [[ ! -f "$fichier" ]]; then
        dire "❌ Fichier '$fichier' introuvable" $ROUGE
        return 1
    fi

    local horodatage=$(date +"%Y%m%d_%H%M%S")
    local fichier_sauvegarde="${fichier}.sauvegarde_${horodatage}"

    if cp "$fichier" "$fichier_sauvegarde"; then
        dire "✅ Sauvegarde créée: $fichier_sauvegarde" $VERT
    else
        dire "❌ Erreur création sauvegarde" $ROUGE
        return 1
    fi
}

# ========== INFORMATIONS FICHIERS ==========

analyser_dossier() {
    local dossier="${1:-.}"

    dire "📊 ANALYSE DU DOSSIER: $dossier" $BLEU
    echo "════════════════════════════════"

    if [[ ! -d "$dossier" ]]; then
        dire "❌ Dossier '$dossier' introuvable" $ROUGE
        return 1
    fi

    # Statistiques de base
    local total_fichiers=$(find "$dossier" -type f 2>/dev/null | wc -l)
    local total_dossiers=$(find "$dossier" -type d 2>/dev/null | wc -l)
    local taille_totale=$(du -sh "$dossier" 2>/dev/null | cut -f1)

    echo "📁 Dossiers: $total_dossiers"
    echo "📄 Fichiers: $total_fichiers"
    echo "💾 Taille totale: $taille_totale"
    echo

    # Top 5 extensions
    dire "🏷️ Top 5 extensions de fichiers:" $CYAN
    find "$dossier" -type f -name "*.*" 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -5 | while read count ext; do
        printf "%-8s %s\n" "$count×" ".$ext"
    done
    echo

    # Plus gros fichiers
    dire "📊 5 plus gros fichiers:" $CYAN
    lister_gros_fichiers "$dossier" 5
}

comparer_fichiers_simple() {
    local fichier1="$1"
    local fichier2="$2"

    if [[ ! -f "$fichier1" ]] || [[ ! -f "$fichier2" ]]; then
        dire "❌ Un des fichiers est introuvable" $ROUGE
        return 1
    fi

    dire "🔍 Comparaison: $(basename "$fichier1") ↔ $(basename "$fichier2")" $CYAN

    # Comparaison simple
    if cmp -s "$fichier1" "$fichier2"; then
        dire "✅ Les fichiers sont identiques" $VERT
    else
        dire "⚠️ Les fichiers sont différents" $JAUNE

        # Afficher les différences si c'est du texte
        if file "$fichier1" | grep -q "text" && file "$fichier2" | grep -q "text"; then
            dire "📋 Différences (premières lignes):" $CYAN
            diff "$fichier1" "$fichier2" | head -10
        fi
    fi
}

# ========== ALIASES PRATIQUES ==========

alias chercher='chercher_fichier_nom'
alias chercher-dans='chercher_contenu_fichier'
alias gros-fichiers='lister_gros_fichiers'
alias nettoyer-temp='nettoyer_fichiers_temporaires'
alias nettoyer-vides='supprimer_dossiers_vides'
alias organiser='organiser_par_extension'
alias sauvegarder='creer_sauvegarde_fichier'
alias analyser='analyser_dossier'
alias comparer='comparer_fichiers_simple'

# Export des fonctions
export -f dire chercher_fichier_nom chercher_contenu_fichier lister_gros_fichiers
export -f nettoyer_fichiers_temporaires supprimer_dossiers_vides organiser_par_extension
export -f creer_sauvegarde_fichier analyser_dossier comparer_fichiers_simple

dire "✅ Outils fichiers chargés" $VERT
dire "💡 Exemples: 'chercher mon_fichier', 'analyser /home/user', 'gros-fichiers'" $CYAN