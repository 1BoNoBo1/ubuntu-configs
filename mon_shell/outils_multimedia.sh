#!/usr/bin/env bash
# ============================================================
# Module : outils_multimedia.sh
# Objectif : Outils multimédia et fichiers pratiques
# Usage : source outils_multimedia.sh
# Style : Fonctions courtes, manipulation fichiers multimédia
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[0;35m'
NC='\033[0m'

dire_msg() {
    echo -e "${2:-$NC}$1${NC}"
}

# ========== INFORMATIONS FICHIERS ==========

info_image() {
    local fichier="$1"

    if [[ -z "$fichier" ]]; then
        dire_msg "❌ Usage: info_image <fichier>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier" ]]; then
        dire_msg "❌ Fichier '$fichier' introuvable" $ROUGE
        return 1
    fi

    dire_msg "🖼️ INFORMATIONS IMAGE: $(basename "$fichier")" $BLEU
    echo "═══════════════════════════════════════"

    # Informations de base
    local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
    local taille_mb=$(echo "scale=2; $taille / 1024 / 1024" | bc 2>/dev/null || echo "N/A")

    echo "📂 Fichier: $(basename "$fichier")"
    echo "📏 Taille: ${taille_mb}MB"

    # Utiliser file pour détection type
    local type_fichier=$(file "$fichier" 2>/dev/null)
    echo "🏷️ Type: $type_fichier"

    # Si identify (ImageMagick) disponible
    if command -v identify >/dev/null; then
        dire_msg "📐 Détails image:" $CYAN
        identify "$fichier" 2>/dev/null | while read ligne; do
            echo "   $ligne"
        done
    else
        dire_msg "💡 Installez ImageMagick pour plus de détails" $JAUNE
    fi
}

info_video() {
    local fichier="$1"

    if [[ -z "$fichier" ]]; then
        dire_msg "❌ Usage: info_video <fichier>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier" ]]; then
        dire_msg "❌ Fichier '$fichier' introuvable" $ROUGE
        return 1
    fi

    dire_msg "🎬 INFORMATIONS VIDÉO: $(basename "$fichier")" $BLEU
    echo "═══════════════════════════════════════"

    # Informations de base
    local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
    local taille_mb=$(echo "scale=2; $taille / 1024 / 1024" | bc 2>/dev/null || echo "N/A")

    echo "📂 Fichier: $(basename "$fichier")"
    echo "📏 Taille: ${taille_mb}MB"

    # Si ffprobe (FFmpeg) disponible
    if command -v ffprobe >/dev/null; then
        dire_msg "🎯 Détails techniques:" $CYAN

        # Durée
        local duree=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$fichier" 2>/dev/null)
        if [[ -n "$duree" ]]; then
            local minutes=$(echo "$duree / 60" | bc 2>/dev/null || echo "0")
            local secondes=$(echo "$duree % 60" | bc 2>/dev/null || echo "0")
            echo "   ⏱️ Durée: ${minutes}m ${secondes}s"
        fi

        # Résolution
        local resolution=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$fichier" 2>/dev/null)
        if [[ -n "$resolution" ]]; then
            echo "   📐 Résolution: $resolution"
        fi

        # Codec
        local codec=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$fichier" 2>/dev/null)
        if [[ -n "$codec" ]]; then
            echo "   🎞️ Codec: $codec"
        fi
    else
        dire_msg "💡 Installez FFmpeg pour plus de détails" $JAUNE
    fi
}

info_audio() {
    local fichier="$1"

    if [[ -z "$fichier" ]]; then
        dire_msg "❌ Usage: info_audio <fichier>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier" ]]; then
        dire_msg "❌ Fichier '$fichier' introuvable" $ROUGE
        return 1
    fi

    dire_msg "🎵 INFORMATIONS AUDIO: $(basename "$fichier")" $BLEU
    echo "═══════════════════════════════════════"

    # Informations de base
    local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
    local taille_mb=$(echo "scale=2; $taille / 1024 / 1024" | bc 2>/dev/null || echo "N/A")

    echo "📂 Fichier: $(basename "$fichier")"
    echo "📏 Taille: ${taille_mb}MB"

    # Si ffprobe disponible
    if command -v ffprobe >/dev/null; then
        dire_msg "🎯 Détails techniques:" $CYAN

        # Durée
        local duree=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$fichier" 2>/dev/null)
        if [[ -n "$duree" ]]; then
            local minutes=$(echo "$duree / 60" | bc 2>/dev/null || echo "0")
            local secondes=$(echo "$duree % 60" | bc 2>/dev/null || echo "0")
            echo "   ⏱️ Durée: ${minutes}m ${secondes}s"
        fi

        # Codec audio
        local codec=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$fichier" 2>/dev/null)
        if [[ -n "$codec" ]]; then
            echo "   🎼 Codec: $codec"
        fi

        # Bitrate
        local bitrate=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$fichier" 2>/dev/null)
        if [[ -n "$bitrate" && "$bitrate" != "N/A" ]]; then
            local bitrate_kb=$(echo "scale=0; $bitrate / 1000" | bc 2>/dev/null || echo "N/A")
            echo "   🎚️ Bitrate: ${bitrate_kb} kbps"
        fi
    else
        dire_msg "💡 Installez FFmpeg pour plus de détails" $JAUNE
    fi
}

# ========== CONVERSIONS SIMPLES ==========

convertir_image() {
    local source="$1"
    local format="$2"

    if [[ -z "$source" ]] || [[ -z "$format" ]]; then
        dire_msg "❌ Usage: convertir_image <fichier> <format>" $ROUGE
        dire_msg "💡 Formats: jpg, png, webp, gif" $CYAN
        return 1
    fi

    if [[ ! -f "$source" ]]; then
        dire_msg "❌ Fichier '$source' introuvable" $ROUGE
        return 1
    fi

    if ! command -v convert >/dev/null; then
        dire_msg "❌ ImageMagick non installé" $ROUGE
        dire_msg "💡 Installez avec: sudo apt install imagemagick" $CYAN
        return 1
    fi

    local nom_base="${source%.*}"
    local destination="${nom_base}.${format}"

    dire_msg "🔄 Conversion: $(basename "$source") → $(basename "$destination")" $CYAN

    if convert "$source" "$destination" 2>/dev/null; then
        dire_msg "✅ Conversion réussie: $destination" $VERT
    else
        dire_msg "❌ Échec de la conversion" $ROUGE
    fi
}

redimensionner_image() {
    local source="$1"
    local taille="$2"

    if [[ -z "$source" ]] || [[ -z "$taille" ]]; then
        dire_msg "❌ Usage: redimensionner_image <fichier> <taille>" $ROUGE
        dire_msg "💡 Exemples: 800x600, 50%, 1920x1080" $CYAN
        return 1
    fi

    if [[ ! -f "$source" ]]; then
        dire_msg "❌ Fichier '$source' introuvable" $ROUGE
        return 1
    fi

    if ! command -v convert >/dev/null; then
        dire_msg "❌ ImageMagick non installé" $ROUGE
        return 1
    fi

    local nom_base="${source%.*}"
    local extension="${source##*.}"
    local destination="${nom_base}_${taille}.${extension}"

    dire_msg "📏 Redimensionnement: $(basename "$source") → $taille" $CYAN

    if convert "$source" -resize "$taille" "$destination" 2>/dev/null; then
        dire_msg "✅ Image redimensionnée: $destination" $VERT
    else
        dire_msg "❌ Échec du redimensionnement" $ROUGE
    fi
}

# ========== OUTILS PDF ==========

info_pdf() {
    local fichier="$1"

    if [[ -z "$fichier" ]]; then
        dire_msg "❌ Usage: info_pdf <fichier.pdf>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier" ]]; then
        dire_msg "❌ Fichier '$fichier' introuvable" $ROUGE
        return 1
    fi

    dire_msg "📄 INFORMATIONS PDF: $(basename "$fichier")" $BLEU
    echo "═══════════════════════════════════"

    # Taille fichier
    local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
    local taille_mb=$(echo "scale=2; $taille / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
    echo "📏 Taille: ${taille_mb}MB"

    # Si pdfinfo disponible
    if command -v pdfinfo >/dev/null; then
        dire_msg "📋 Détails:" $CYAN
        pdfinfo "$fichier" 2>/dev/null | grep -E "(Pages|Title|Author|Creator|Producer)" | while read ligne; do
            echo "   $ligne"
        done
    else
        dire_msg "💡 Installez poppler-utils pour plus de détails" $JAUNE
    fi
}

fusionner_pdf() {
    if [[ $# -lt 2 ]]; then
        dire_msg "❌ Usage: fusionner_pdf <fichier1.pdf> <fichier2.pdf> [...]" $ROUGE
        return 1
    fi

    local fichier_sortie="fusion_$(date +%Y%m%d_%H%M%S).pdf"

    # Vérifier que tous les fichiers existent
    for fichier in "$@"; do
        if [[ ! -f "$fichier" ]]; then
            dire_msg "❌ Fichier '$fichier' introuvable" $ROUGE
            return 1
        fi
    done

    if command -v pdftk >/dev/null; then
        dire_msg "🔗 Fusion de $# fichiers PDF..." $CYAN
        if pdftk "$@" cat output "$fichier_sortie" 2>/dev/null; then
            dire_msg "✅ Fusion réussie: $fichier_sortie" $VERT
        else
            dire_msg "❌ Échec de la fusion" $ROUGE
        fi
    elif command -v gs >/dev/null; then
        dire_msg "🔗 Fusion avec Ghostscript..." $CYAN
        if gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$fichier_sortie" "$@" 2>/dev/null; then
            dire_msg "✅ Fusion réussie: $fichier_sortie" $VERT
        else
            dire_msg "❌ Échec de la fusion" $ROUGE
        fi
    else
        dire_msg "❌ Outil de fusion PDF non trouvé" $ROUGE
        dire_msg "💡 Installez pdftk ou ghostscript" $CYAN
    fi
}

# ========== NETTOYAGE MULTIMÉDIA ==========

nettoyer_multimedia() {
    local dossier="${1:-.}"

    dire_msg "🧹 NETTOYAGE FICHIERS MULTIMÉDIA" $BLEU
    echo "═══════════════════════════════════"

    dire_msg "📁 Dossier: $dossier" $CYAN

    local nettoye=0

    # Fichiers temporaires courants
    for pattern in "*.tmp" "Thumbs.db" ".DS_Store" "*.part" "*.crdownload"; do
        while IFS= read -r -d '' fichier; do
            rm -f "$fichier" && {
                dire_msg "🗑️ Supprimé: $(basename "$fichier")" $JAUNE
                ((nettoye++))
            }
        done < <(find "$dossier" -name "$pattern" -type f -print0 2>/dev/null)
    done

    # Doublons d'images (détection simple par taille)
    if command -v fdupes >/dev/null; then
        dire_msg "🔍 Recherche de doublons..." $CYAN
        local doublons=$(fdupes -r "$dossier" 2>/dev/null | wc -l)
        if [[ $doublons -gt 0 ]]; then
            dire_msg "⚠️ $doublons groupes de doublons trouvés" $JAUNE
            dire_msg "💡 Utilisez 'fdupes -r $dossier' pour les voir" $CYAN
        fi
    fi

    if [[ $nettoye -eq 0 ]]; then
        dire_msg "✅ Dossier déjà propre" $VERT
    else
        dire_msg "✅ $nettoye fichiers nettoyés" $VERT
    fi
}

# ========== RECHERCHE MULTIMÉDIA ==========

chercher_multimedia() {
    local terme="$1"
    local dossier="${2:-.}"

    if [[ -z "$terme" ]]; then
        dire_msg "❌ Usage: chercher_multimedia <terme> [dossier]" $ROUGE
        return 1
    fi

    dire_msg "🔍 Recherche multimédia: '$terme' dans $dossier" $CYAN
    echo "───────────────────────────────────────"

    # Extensions multimédia communes
    local extensions=("jpg" "jpeg" "png" "gif" "webp" "mp4" "avi" "mkv" "mov" "mp3" "wav" "flac" "ogg" "pdf")

    for ext in "${extensions[@]}"; do
        while IFS= read -r -d '' fichier; do
            dire_msg "📄 $fichier" $VERT
        done < <(find "$dossier" -iname "*$terme*.$ext" -type f -print0 2>/dev/null)
    done
}

# ========== ALIASES ==========

alias img-info='info_image'
alias vid-info='info_video'
alias audio-info='info_audio'
alias pdf-info='info_pdf'
alias convertir-img='convertir_image'
alias redim='redimensionner_image'
alias fusionner='fusionner_pdf'
alias nettoyer-media='nettoyer_multimedia'
alias chercher-media='chercher_multimedia'

# ========== AIDE ==========

aide_multimedia() {
    dire_msg "🎨 OUTILS MULTIMÉDIA" $BLEU
    echo "══════════════════════"
    echo
    dire_msg "📋 Informations:" $CYAN
    echo "  img-info <fichier>      # Infos image"
    echo "  vid-info <fichier>      # Infos vidéo"
    echo "  audio-info <fichier>    # Infos audio"
    echo "  pdf-info <fichier>      # Infos PDF"
    echo
    dire_msg "🔄 Conversions:" $CYAN
    echo "  convertir-img <fichier> <format>  # Convertir image"
    echo "  redim <fichier> <taille>          # Redimensionner image"
    echo "  fusionner <pdf1> <pdf2> ...       # Fusionner PDFs"
    echo
    dire_msg "🧹 Maintenance:" $CYAN
    echo "  nettoyer-media [dossier]          # Nettoyer fichiers"
    echo "  chercher-media <terme> [dossier]  # Rechercher fichiers"
    echo
    dire_msg "💡 Exemples:" $JAUNE
    echo "  img-info photo.jpg"
    echo "  convertir-img image.png jpg"
    echo "  redim photo.jpg 800x600"
    echo "  fusionner doc1.pdf doc2.pdf"
}

alias aide-multimedia='aide_multimedia'

dire_msg "✅ Outils multimédia chargés" $VERT
dire_msg "💡 Tapez 'aide-multimedia' pour voir toutes les commandes" $CYAN