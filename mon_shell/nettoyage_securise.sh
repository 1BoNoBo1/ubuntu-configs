#!/usr/bin/env bash
# ============================================================
# Module : nettoyage_securise.sh
# Objectif : Nettoyage avec DOUBLE VÉRIFICATION obligatoire
# Usage : source nettoyage_securise.sh
# Sécurité : Mode liste + confirmation avant suppression
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

# ========== LISTE NOIRE - DOSSIERS PROTÉGÉS ==========

# Dossiers système ABSOLUMENT INTERDITS
DOSSIERS_INTERDITS=(
    "/"
    "/bin"
    "/boot"
    "/dev"
    "/etc"
    "/lib"
    "/lib32"
    "/lib64"
    "/libx32"
    "/proc"
    "/root"
    "/sbin"
    "/sys"
    "/usr"
    "/var"
    "/snap"
    "/run"
    "/opt"
    "/srv"
    "/mnt"
    "/media"
    "/lost+found"
)

# Dossiers utilisateur sensibles à protéger
DOSSIERS_SENSIBLES=(
    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.config"
    "$HOME/.local/share"
    "$HOME/.mozilla"
    "$HOME/.cache/mozilla"
    "$HOME/.thunderbird"
)

# Fonction de vérification des dossiers protégés
verifier_dossier_securise() {
    local dossier="$1"

    # Résoudre le chemin absolu (suivre les symlinks)
    local chemin_absolu=$(readlink -f "$dossier" 2>/dev/null || realpath "$dossier" 2>/dev/null || echo "$dossier")

    msg "🔒 Vérification sécurité du chemin..." $CYAN
    msg "   Chemin demandé: $dossier" $CYAN
    msg "   Chemin absolu: $chemin_absolu" $CYAN
    echo

    # Vérification 1: Dossiers système interdits
    for interdit in "${DOSSIERS_INTERDITS[@]}"; do
        # Vérification exacte
        if [[ "$chemin_absolu" == "$interdit" ]]; then
            msg "🚨 ALERTE SÉCURITÉ CRITIQUE !" $ROUGE
            msg "════════════════════════════" $ROUGE
            echo
            msg "❌ OPÉRATION INTERDITE" $ROUGE
            msg "   Dossier système protégé: $interdit" $ROUGE
            echo
            msg "🛡️  Protection activée: Impossible de nettoyer les dossiers système" $JAUNE
            msg "💡 Ce dossier contient des fichiers critiques du système" $CYAN
            echo
            return 1
        fi

        # Vérification si c'est un sous-dossier d'un dossier interdit
        if [[ "$chemin_absolu" == "$interdit"/* ]]; then
            msg "🚨 ALERTE SÉCURITÉ CRITIQUE !" $ROUGE
            msg "════════════════════════════" $ROUGE
            echo
            msg "❌ OPÉRATION INTERDITE" $ROUGE
            msg "   Sous-dossier d'un répertoire système: $interdit" $ROUGE
            msg "   Chemin demandé: $chemin_absolu" $ROUGE
            echo
            msg "🛡️  Protection activée: Zone système détectée" $JAUNE
            msg "💡 Le nettoyage dans /usr, /etc, /bin, etc. est INTERDIT" $CYAN
            echo
            return 1
        fi
    done

    # Vérification 2: Dossiers utilisateur sensibles
    for sensible in "${DOSSIERS_SENSIBLES[@]}"; do
        if [[ "$chemin_absolu" == "$sensible" ]] || [[ "$chemin_absolu" == "$sensible"/* ]]; then
            msg "⚠️  AVERTISSEMENT: Dossier sensible détecté" $JAUNE
            msg "════════════════════════════════════════" $JAUNE
            echo
            msg "📂 Dossier: $chemin_absolu" $CYAN
            msg "🔐 Type: Configuration/Données sensibles" $JAUNE
            echo
            msg "Ce dossier contient des données importantes:" $ROUGE
            msg "  • Clés SSH/GPG" $ROUGE
            msg "  • Configurations système" $ROUGE
            msg "  • Données applications" $ROUGE
            echo
            read -p "Êtes-vous ABSOLUMENT certain de vouloir nettoyer ici ? (oui/NON) : " confirm_sensible

            if [[ "$confirm_sensible" != "oui" ]]; then
                msg "❌ Opération annulée par sécurité" $ROUGE
                return 1
            fi

            msg "⚠️  Vous avez confirmé - Procédure continue avec EXTRÊME prudence" $JAUNE
            echo
        fi
    done

    # Vérification 3: Protection racine utilisateur complète
    if [[ "$chemin_absolu" == "$HOME" ]]; then
        msg "⚠️  ALERTE: Nettoyage de tout le dossier HOME" $JAUNE
        msg "═══════════════════════════════════════════" $JAUNE
        echo
        msg "📂 Vous tentez de nettoyer: $HOME" $ROUGE
        msg "⚠️  Ceci va analyser TOUS vos fichiers personnels !" $ROUGE
        echo
        msg "💡 Recommandation: Spécifiez un sous-dossier précis" $CYAN
        msg "   Exemples:" $CYAN
        msg "   • nettoyer-safe ~/Downloads" $VERT
        msg "   • nettoyer-safe ~/Documents" $VERT
        msg "   • nettoyer-safe ~/Bureau" $VERT
        echo
        read -p "Continuer malgré tout sur TOUT le HOME ? (oui/NON) : " confirm_home

        if [[ "$confirm_home" != "oui" ]]; then
            msg "❌ Opération annulée - Spécifiez un dossier précis" $ROUGE
            return 1
        fi

        msg "⚠️  Analyse complète du HOME confirmée" $JAUNE
        echo
    fi

    # Vérification 4: Permissions d'écriture
    if [[ ! -w "$chemin_absolu" ]]; then
        msg "❌ ERREUR: Pas de permissions d'écriture" $ROUGE
        msg "   Dossier: $chemin_absolu" $ROUGE
        echo
        msg "💡 Vous n'avez pas les droits pour modifier ce dossier" $CYAN
        return 1
    fi

    # Si tout est OK
    msg "✅ Vérifications de sécurité: OK" $VERT
    msg "   Le dossier peut être nettoyé en toute sécurité" $VERT
    echo
    return 0
}

# ========== NETTOYAGE SÉCURISÉ AVEC DOUBLE VÉRIFICATION ==========

nettoyer_securise() {
    local dossier="${1:-$PWD}"

    msg "🔍 NETTOYAGE SÉCURISÉ - MODE ANALYSE" $BLEU
    msg "═══════════════════════════════════════" $BLEU
    echo

    msg "📁 Dossier cible: $dossier" $CYAN
    echo

    # Vérifier que le dossier existe
    if [[ ! -d "$dossier" ]]; then
        msg "❌ Erreur: Le dossier '$dossier' n'existe pas" $ROUGE
        return 1
    fi

    # 🛡️ VÉRIFICATION SÉCURITÉ CRITIQUE
    if ! verifier_dossier_securise "$dossier"; then
        msg "🚫 Nettoyage refusé pour raisons de sécurité" $ROUGE
        return 1
    fi

    # Patterns de fichiers temporaires à rechercher
    local patterns=("*.tmp" "*.temp" "*~" ".DS_Store" "Thumbs.db" "*.part" "*.crdownload")

    msg "🔎 PHASE 1: ANALYSE DES FICHIERS" $CYAN
    msg "─────────────────────────────────" $CYAN
    echo

    # Tableau pour stocker les fichiers trouvés
    local fichiers_trouves=()
    local total_taille=0

    # Recherche des fichiers
    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d '' fichier; do
            if [[ -f "$fichier" ]]; then
                fichiers_trouves+=("$fichier")
                local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
                total_taille=$((total_taille + taille))
            fi
        done < <(find "$dossier" -name "$pattern" -type f -print0 2>/dev/null)
    done

    # Si aucun fichier trouvé
    if [[ ${#fichiers_trouves[@]} -eq 0 ]]; then
        msg "✅ Aucun fichier temporaire trouvé" $VERT
        msg "💡 Le dossier est déjà propre !" $CYAN
        return 0
    fi

    # Affichage des fichiers trouvés
    msg "📊 FICHIERS TEMPORAIRES TROUVÉS: ${#fichiers_trouves[@]}" $JAUNE
    echo

    # Convertir taille en format lisible
    local taille_mb=$(echo "scale=2; $total_taille / 1024 / 1024" | bc 2>/dev/null || echo "0")
    msg "💾 Espace total à libérer: ${taille_mb} MB" $CYAN
    echo

    # Afficher liste détaillée
    msg "📋 LISTE DES FICHIERS (premiers 20):" $CYAN
    echo "────────────────────────────────────"

    local count=0
    for fichier in "${fichiers_trouves[@]}"; do
        ((count++))
        if [[ $count -le 20 ]]; then
            local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
            local taille_kb=$(echo "scale=1; $taille / 1024" | bc 2>/dev/null || echo "0")
            printf "  %3d. %-60s %8s KB\n" "$count" "$(basename "$fichier")" "$taille_kb"
        fi
    done

    if [[ ${#fichiers_trouves[@]} -gt 20 ]]; then
        msg "  ... et $((${#fichiers_trouves[@]} - 20)) autres fichiers" $JAUNE
    fi

    echo
    echo "════════════════════════════════════════════════════════"
    echo

    # ========== PREMIÈRE VÉRIFICATION ==========
    msg "⚠️  VÉRIFICATION 1/2: CONFIRMATION INITIALE" $JAUNE
    msg "───────────────────────────────────────────" $JAUNE
    echo

    msg "Vous êtes sur le point de supprimer ${#fichiers_trouves[@]} fichier(s)" $ROUGE
    msg "Espace à libérer: ${taille_mb} MB" $CYAN
    echo

    read -p "Voulez-vous continuer ? (oui/NON) : " reponse1

    if [[ ! "$reponse1" =~ ^[Oo][Uu][Ii]$ ]]; then
        msg "❌ Opération annulée (réponse: '$reponse1')" $ROUGE
        msg "💡 Pour confirmer, vous devez taper exactement: oui" $CYAN
        return 0
    fi

    echo

    # ========== DEUXIÈME VÉRIFICATION ==========
    msg "⚠️  VÉRIFICATION 2/2: CONFIRMATION FINALE" $ROUGE
    msg "─────────────────────────────────────────" $ROUGE
    echo

    msg "⚠️  DERNIÈRE CHANCE D'ANNULER !" $ROUGE
    msg "Cette action est IRRÉVERSIBLE" $ROUGE
    echo
    msg "Dossier: $dossier" $JAUNE
    msg "Fichiers: ${#fichiers_trouves[@]}" $JAUNE
    echo

    read -p "Tapez SUPPRIMER pour confirmer définitivement : " reponse2

    if [[ "$reponse2" != "SUPPRIMER" ]]; then
        msg "❌ Opération annulée (réponse: '$reponse2')" $ROUGE
        msg "💡 Pour confirmer, vous devez taper exactement: SUPPRIMER" $CYAN
        return 0
    fi

    echo

    # ========== SUPPRESSION EFFECTIVE ==========
    msg "🗑️  SUPPRESSION EN COURS..." $CYAN
    msg "═══════════════════════════" $CYAN
    echo

    local fichiers_supprimes=0
    local fichiers_echecs=0

    for fichier in "${fichiers_trouves[@]}"; do
        if rm -f "$fichier" 2>/dev/null; then
            ((fichiers_supprimes++))
            msg "  ✅ $(basename "$fichier")" $VERT
        else
            ((fichiers_echecs++))
            msg "  ❌ Échec: $(basename "$fichier")" $ROUGE
        fi
    done

    echo
    msg "════════════════════════════════════════════════════════" $BLEU
    msg "📊 RÉSULTAT FINAL" $BLEU
    msg "════════════════════════════════════════════════════════" $BLEU
    echo
    msg "✅ Fichiers supprimés: $fichiers_supprimes" $VERT

    if [[ $fichiers_echecs -gt 0 ]]; then
        msg "❌ Échecs: $fichiers_echecs" $ROUGE
    fi

    msg "💾 Espace libéré: ${taille_mb} MB" $CYAN
    echo
}

# ========== MODE LISTE UNIQUEMENT (sans suppression) ==========

lister_fichiers_temporaires() {
    local dossier="${1:-$PWD}"

    msg "📋 ANALYSE FICHIERS TEMPORAIRES (MODE LECTURE SEULE)" $BLEU
    msg "════════════════════════════════════════════════════" $BLEU
    echo

    msg "📁 Dossier analysé: $dossier" $CYAN
    echo

    if [[ ! -d "$dossier" ]]; then
        msg "❌ Erreur: Le dossier '$dossier' n'existe pas" $ROUGE
        return 1
    fi

    # 🛡️ VÉRIFICATION SÉCURITÉ (même en mode lecture seule pour informer)
    if ! verifier_dossier_securise "$dossier"; then
        msg "⚠️  Analyse refusée - Dossier système protégé" $ROUGE
        return 1
    fi

    local patterns=("*.tmp" "*.temp" "*~" ".DS_Store" "Thumbs.db" "*.part" "*.crdownload")
    local fichiers_trouves=()
    local total_taille=0

    # Recherche
    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d '' fichier; do
            if [[ -f "$fichier" ]]; then
                fichiers_trouves+=("$fichier")
                local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
                total_taille=$((total_taille + taille))
            fi
        done < <(find "$dossier" -name "$pattern" -type f -print0 2>/dev/null)
    done

    if [[ ${#fichiers_trouves[@]} -eq 0 ]]; then
        msg "✅ Aucun fichier temporaire trouvé" $VERT
        return 0
    fi

    # Affichage
    local taille_mb=$(echo "scale=2; $total_taille / 1024 / 1024" | bc 2>/dev/null || echo "0")

    msg "📊 RÉSUMÉ:" $CYAN
    msg "  Fichiers trouvés: ${#fichiers_trouves[@]}" $JAUNE
    msg "  Espace occupé: ${taille_mb} MB" $JAUNE
    echo

    msg "📄 LISTE COMPLÈTE:" $CYAN
    echo "─────────────────"

    for fichier in "${fichiers_trouves[@]}"; do
        local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
        local taille_kb=$(echo "scale=1; $taille / 1024" | bc 2>/dev/null || echo "0")
        printf "  %-70s %10s KB\n" "$fichier" "$taille_kb"
    done

    echo
    msg "💡 Pour supprimer ces fichiers:" $CYAN
    msg "   nettoyer_securise $dossier" $VERT
}

# ========== MODE INTERACTIF - CHOIX FICHIER PAR FICHIER ==========

nettoyer_interactif() {
    local dossier="${1:-$PWD}"

    msg "🎯 NETTOYAGE INTERACTIF (choix fichier par fichier)" $BLEU
    msg "═══════════════════════════════════════════════════" $BLEU
    echo

    if [[ ! -d "$dossier" ]]; then
        msg "❌ Erreur: Le dossier '$dossier' n'existe pas" $ROUGE
        return 1
    fi

    # 🛡️ VÉRIFICATION SÉCURITÉ CRITIQUE
    if ! verifier_dossier_securise "$dossier"; then
        msg "🚫 Nettoyage interactif refusé pour raisons de sécurité" $ROUGE
        return 1
    fi

    local patterns=("*.tmp" "*.temp" "*~" ".DS_Store" "Thumbs.db" "*.part" "*.crdownload")
    local fichiers_trouves=()

    # Recherche
    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d '' fichier; do
            if [[ -f "$fichier" ]]; then
                fichiers_trouves+=("$fichier")
            fi
        done < <(find "$dossier" -name "$pattern" -type f -print0 2>/dev/null)
    done

    if [[ ${#fichiers_trouves[@]} -eq 0 ]]; then
        msg "✅ Aucun fichier temporaire trouvé" $VERT
        return 0
    fi

    msg "📊 ${#fichiers_trouves[@]} fichiers temporaires trouvés" $CYAN
    echo

    local supprimes=0
    local conserves=0
    local num=0

    for fichier in "${fichiers_trouves[@]}"; do
        ((num++))

        local taille=$(stat -f%z "$fichier" 2>/dev/null || stat -c%s "$fichier" 2>/dev/null)
        local taille_kb=$(echo "scale=1; $taille / 1024" | bc 2>/dev/null || echo "0")

        echo
        msg "═══════════════════════════════════════════" $CYAN
        msg "Fichier $num/${#fichiers_trouves[@]}" $CYAN
        msg "═══════════════════════════════════════════" $CYAN
        echo
        msg "📄 Nom: $(basename "$fichier")" $JAUNE
        msg "📁 Chemin: $fichier" $CYAN
        msg "💾 Taille: ${taille_kb} KB" $CYAN
        echo

        read -p "Supprimer ce fichier ? (o/N) : " reponse

        if [[ "$reponse" =~ ^[OoYy]$ ]]; then
            if rm -f "$fichier" 2>/dev/null; then
                msg "✅ Supprimé" $VERT
                ((supprimes++))
            else
                msg "❌ Échec suppression" $ROUGE
            fi
        else
            msg "➡️  Conservé" $BLEU
            ((conserves++))
        fi
    done

    echo
    msg "════════════════════════════════════════════" $BLEU
    msg "📊 RÉSULTAT" $BLEU
    msg "════════════════════════════════════════════" $BLEU
    echo
    msg "✅ Fichiers supprimés: $supprimes" $VERT
    msg "➡️  Fichiers conservés: $conserves" $BLEU
    msg "📊 Total traité: ${#fichiers_trouves[@]}" $CYAN
}

# ========== ALIASES ==========

alias lister-temp='lister_fichiers_temporaires'
alias nettoyer-safe='nettoyer_securise'
alias nettoyer-interactif='nettoyer_interactif'

# ========== AIDE ==========

aide_nettoyage_securise() {
    msg "🛡️  NETTOYAGE SÉCURISÉ" $BLEU
    msg "════════════════════" $BLEU
    echo
    msg "🔍 Modes disponibles:" $CYAN
    echo
    msg "1️⃣  MODE LISTE (lecture seule):" $YELLOW
    echo "   lister_fichiers_temporaires [dossier]"
    echo "   → Analyse sans rien supprimer"
    echo "   → Affiche ce qui serait nettoyé"
    echo
    msg "2️⃣  MODE SÉCURISÉ (double confirmation):" $YELLOW
    echo "   nettoyer_securise [dossier]"
    echo "   → Liste tous les fichiers"
    echo "   → Demande 'oui' pour continuer"
    echo "   → Demande 'SUPPRIMER' pour confirmer"
    echo "   → Supprime avec rapport détaillé"
    echo
    msg "3️⃣  MODE INTERACTIF (fichier par fichier):" $YELLOW
    echo "   nettoyer_interactif [dossier]"
    echo "   → Demande confirmation pour CHAQUE fichier"
    echo "   → Contrôle total sur ce qui est supprimé"
    echo
    msg "📝 Exemples:" $CYAN
    echo "   lister-temp                    # Liste dans dossier actuel"
    echo "   lister-temp ~/Downloads        # Liste dans Downloads"
    echo "   nettoyer-safe ~/Documents      # Nettoyage sécurisé Documents"
    echo "   nettoyer-interactif ~/Images   # Mode interactif Images"
    echo
    msg "🎯 Fichiers ciblés:" $CYAN
    echo "   *.tmp, *.temp, *~, .DS_Store, Thumbs.db, *.part, *.crdownload"
    echo
    msg "🛡️  Sécurité:" $GREEN
    echo "   ✅ Double vérification obligatoire"
    echo "   ✅ Mode liste pour voir avant suppression"
    echo "   ✅ Mode interactif pour contrôle total"
    echo "   ✅ Rapport détaillé après opération"
}

alias aide-nettoyage='aide_nettoyage_securise'

msg "✅ Module nettoyage sécurisé chargé" $VERT
msg "💡 Tapez 'aide-nettoyage' pour voir toutes les commandes" $CYAN