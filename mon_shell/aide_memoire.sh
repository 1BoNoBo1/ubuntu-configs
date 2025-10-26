#!/usr/bin/env bash
# ============================================================
# Module : aide_memoire.sh
# Objectif : Aide-mémoire interactif pour commandes courantes
# Usage : source aide_memoire.sh
# Style : Interface simple, exemples pratiques, français
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[0;35m'
NC='\033[0m'

afficher() {
    local message="$1"
    local couleur="${2:-$NC}"
    echo -e "${couleur}${message}${NC}"
}

# ========== AIDE MÉMOIRE PRINCIPAL ==========

aide_git() {
    afficher "🔧 AIDE-MÉMOIRE GIT" $BLEU
    echo "═══════════════════"
    echo
    afficher "📋 Commandes de base:" $CYAN
    echo "  git status                    # État du dépôt"
    echo "  git add fichier.txt           # Ajouter un fichier"
    echo "  git add .                     # Ajouter tous les fichiers"
    echo "  git commit -m 'message'       # Valider les changements"
    echo "  git push                      # Envoyer vers le serveur"
    echo "  git pull                      # Récupérer du serveur"
    echo
    afficher "🌿 Branches:" $CYAN
    echo "  git branch                    # Lister les branches"
    echo "  git branch nouvelle-branche   # Créer une branche"
    echo "  git checkout nom-branche      # Changer de branche"
    echo "  git merge autre-branche       # Fusionner une branche"
    echo
    afficher "📜 Historique:" $CYAN
    echo "  git log --oneline             # Historique condensé"
    echo "  git log --graph               # Historique graphique"
    echo "  git diff                      # Voir les modifications"
    echo
    afficher "🆘 Annulations:" $CYAN
    echo "  git restore fichier.txt       # Annuler modification"
    echo "  git reset HEAD~1              # Annuler dernier commit"
    echo "  git checkout -- .             # Restaurer tout"
}

aide_fichiers() {
    afficher "📁 AIDE-MÉMOIRE FICHIERS" $BLEU
    echo "════════════════════════"
    echo
    afficher "📋 Navigation:" $CYAN
    echo "  ls -la                        # Lister avec détails"
    echo "  cd dossier/                   # Aller dans dossier"
    echo "  cd ..                         # Dossier parent"
    echo "  pwd                           # Dossier actuel"
    echo "  tree                          # Arborescence"
    echo
    afficher "📄 Manipulation:" $CYAN
    echo "  mkdir nouveau_dossier         # Créer dossier"
    echo "  touch nouveau_fichier.txt     # Créer fichier vide"
    echo "  cp source.txt destination.txt # Copier fichier"
    echo "  mv ancien.txt nouveau.txt     # Renommer/déplacer"
    echo "  rm fichier.txt                # Supprimer fichier"
    echo "  rm -r dossier/                # Supprimer dossier"
    echo
    afficher "🔍 Recherche:" $CYAN
    echo "  find . -name '*.txt'          # Chercher fichiers .txt"
    echo "  grep 'texte' fichier.txt      # Chercher dans fichier"
    echo "  grep -r 'texte' dossier/      # Chercher récursivement"
    echo
    afficher "👁️ Affichage:" $CYAN
    echo "  cat fichier.txt               # Afficher contenu"
    echo "  less fichier.txt              # Afficher avec pagination"
    echo "  head -10 fichier.txt          # 10 premières lignes"
    echo "  tail -10 fichier.txt          # 10 dernières lignes"
}

aide_systeme() {
    afficher "⚙️ AIDE-MÉMOIRE SYSTÈME" $BLEU
    echo "═══════════════════════"
    echo
    afficher "📊 Surveillance:" $CYAN
    echo "  htop                          # Processus interactif"
    echo "  ps aux                        # Liste processus"
    echo "  free -h                       # Utilisation mémoire"
    echo "  df -h                         # Espace disque"
    echo "  uptime                        # Temps de fonctionnement"
    echo
    afficher "🔧 Services:" $CYAN
    echo "  systemctl status nom-service  # État service"
    echo "  systemctl start nom-service   # Démarrer service"
    echo "  systemctl stop nom-service    # Arrêter service"
    echo "  systemctl restart nom-service # Redémarrer service"
    echo
    afficher "👥 Utilisateurs:" $CYAN
    echo "  whoami                        # Utilisateur actuel"
    echo "  who                           # Utilisateurs connectés"
    echo "  id                            # Informations utilisateur"
    echo "  groups                        # Groupes utilisateur"
    echo
    afficher "🌐 Réseau:" $CYAN
    echo "  ping google.com               # Test connectivité"
    echo "  wget URL                      # Télécharger fichier"
    echo "  curl URL                      # Requête HTTP"
    echo "  ip addr                       # Adresses IP"
}

aide_permissions() {
    afficher "🔐 AIDE-MÉMOIRE PERMISSIONS" $BLEU
    echo "═══════════════════════════"
    echo
    afficher "📋 Lecture permissions:" $CYAN
    echo "  ls -l fichier.txt             # Voir permissions"
    echo "  stat fichier.txt              # Détails complets"
    echo
    afficher "🔧 Modification permissions:" $CYAN
    echo "  chmod +x script.sh            # Rendre exécutable"
    echo "  chmod 755 script.sh           # rwxr-xr-x"
    echo "  chmod 644 fichier.txt         # rw-r--r--"
    echo "  chmod -R 755 dossier/         # Récursif"
    echo
    afficher "👤 Propriétaire:" $CYAN
    echo "  chown user fichier.txt        # Changer propriétaire"
    echo "  chgrp group fichier.txt       # Changer groupe"
    echo "  chown user:group fichier.txt  # Changer les deux"
    echo
    afficher "🔢 Codes permissions:" $CYAN
    echo "  4 = lecture (r)    2 = écriture (w)    1 = exécution (x)"
    echo "  755 = rwxr-xr-x   644 = rw-r--r--   600 = rw-------"
}

aide_reseau() {
    afficher "🌐 AIDE-MÉMOIRE RÉSEAU" $BLEU
    echo "══════════════════════"
    echo
    afficher "🔍 Diagnostic:" $CYAN
    echo "  ping -c4 8.8.8.8              # Test DNS Google"
    echo "  traceroute google.com         # Tracer route"
    echo "  nslookup google.com           # Résolution DNS"
    echo "  netstat -tulpn                # Ports ouverts"
    echo
    afficher "📶 WiFi:" $CYAN
    echo "  iwconfig                      # État WiFi"
    echo "  nmcli dev status              # État connexions"
    echo "  nmcli dev wifi list           # Réseaux disponibles"
    echo
    afficher "🔗 Connexions:" $CYAN
    echo "  ss -tulpn                     # Connexions actives"
    echo "  lsof -i                       # Fichiers réseau ouverts"
    echo "  iftop                         # Trafic réseau temps réel"
}

aide_archive() {
    afficher "📦 AIDE-MÉMOIRE ARCHIVES" $BLEU
    echo "════════════════════════"
    echo
    afficher "📁 TAR (sans compression):" $CYAN
    echo "  tar -cf archive.tar dossier/  # Créer archive"
    echo "  tar -tf archive.tar           # Lister contenu"
    echo "  tar -xf archive.tar           # Extraire"
    echo
    afficher "🗜️ TAR.GZ (avec compression):" $CYAN
    echo "  tar -czf archive.tar.gz doss/ # Créer compressé"
    echo "  tar -tzf archive.tar.gz       # Lister compressé"
    echo "  tar -xzf archive.tar.gz       # Extraire compressé"
    echo
    afficher "📋 ZIP:" $CYAN
    echo "  zip -r archive.zip dossier/   # Créer ZIP"
    echo "  unzip archive.zip             # Extraire ZIP"
    echo "  unzip -l archive.zip          # Lister contenu ZIP"
    echo
    afficher "🔧 Autres:" $CYAN
    echo "  gzip fichier.txt              # Compresser en .gz"
    echo "  gunzip fichier.txt.gz         # Décompresser .gz"
    echo "  7z a archive.7z dossier/      # Créer 7zip"
}

# ========== AIDE INTERACTIVE ==========

aide_interactive() {
    afficher "📚 AIDE-MÉMOIRE INTERACTIF" $VIOLET
    echo "═══════════════════════════"
    echo
    afficher "Choisissez une catégorie:" $CYAN
    echo "1) Git - Gestion de versions"
    echo "2) Fichiers - Navigation et manipulation"
    echo "3) Système - Surveillance et services"
    echo "4) Permissions - Droits et propriétés"
    echo "5) Réseau - Connectivité et diagnostic"
    echo "6) Archives - Compression et extraction"
    echo "7) Tout afficher"
    echo "q) Quitter"
    echo

    read -p "Votre choix [1-7,q]: " choix

    case "$choix" in
        1) aide_git ;;
        2) aide_fichiers ;;
        3) aide_systeme ;;
        4) aide_permissions ;;
        5) aide_reseau ;;
        6) aide_archive ;;
        7)
            aide_git; echo
            aide_fichiers; echo
            aide_systeme; echo
            aide_permissions; echo
            aide_reseau; echo
            aide_archive
            ;;
        q|Q) afficher "👋 Au revoir!" $VERT ;;
        *) afficher "❌ Choix invalide" $ROUGE ;;
    esac
}

rechercher_commande() {
    local terme="$1"

    if [[ -z "$terme" ]]; then
        afficher "❌ Usage: rechercher_commande <terme>" $ROUGE
        return 1
    fi

    afficher "🔍 Recherche de '$terme' dans l'aide-mémoire..." $CYAN
    echo

    # Rechercher dans toutes les fonctions d'aide
    {
        aide_git
        aide_fichiers
        aide_systeme
        aide_permissions
        aide_reseau
        aide_archive
    } | grep -i "$terme" | while read ligne; do
        echo "$ligne"
    done
}

conseil_du_jour() {
    local conseils=(
        "💡 Utilisez 'Ctrl+R' pour chercher dans l'historique des commandes"
        "💡 'Ctrl+A' va au début de ligne, 'Ctrl+E' à la fin"
        "💡 'Ctrl+U' efface depuis le curseur jusqu'au début"
        "💡 'Ctrl+K' efface depuis le curseur jusqu'à la fin"
        "💡 'Ctrl+L' efface l'écran (équivalent à 'clear')"
        "💡 'Tab' pour l'autocomplétion, 'Tab Tab' pour les options"
        "💡 'history' affiche l'historique des commandes"
        "💡 '!!' répète la dernière commande"
        "💡 'sudo !!' répète la dernière commande avec sudo"
        "💡 'cd -' retourne au dossier précédent"
    )

    local index=$((RANDOM % ${#conseils[@]}))
    afficher "${conseils[$index]}" $JAUNE
}

# ========== ALIASES ==========

alias aide='aide_interactive'
alias aide-git='aide_git'
alias aide-fichiers='aide_fichiers'
alias aide-systeme='aide_systeme'
alias aide-permissions='aide_permissions'
alias aide-reseau='aide_reseau'
alias aide-archives='aide_archive'
alias chercher-aide='rechercher_commande'
alias conseil='conseil_du_jour'
alias memo='aide_interactive'

# Export des fonctions
export -f afficher aide_git aide_fichiers aide_systeme aide_permissions
export -f aide_reseau aide_archive aide_interactive rechercher_commande conseil_du_jour

afficher "✅ Aide-mémoire chargé" $VERT
afficher "💡 Tapez 'aide' pour l'aide interactive" $CYAN
conseil_du_jour