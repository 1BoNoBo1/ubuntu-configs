#!/usr/bin/env bash
# ~/.mon_shell/colors.sh
# Fichier de couleurs pour le shell (compatible bash/zsh).
# Chargé par les fichiers de configuration shell.
# --------------------------------------------------
# ---------- Couleurs ANSI universelles ----------
# Compatible bash et zsh
# --------------------------------------------------

# Couleurs de base ANSI
RESET='\033[0m'
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRIS='\033[1;30m'

# Couleurs étendues
BLANC='\033[1;37m'
NOIR='\033[0;30m'

# Styles
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

# Export pour compatibilité inter-shells
export RESET VERT ROUGE JAUNE BLEU CYAN MAGENTA GRIS
export BLANC NOIR BOLD DIM UNDERLINE

# Fonction d'affichage coloré
echo_color() {
    echo -e "${2}${1}${RESET}"
}

# Pour les messages d'erreur en rouge et gras
ERREUR="${ROUGE}\e[1mErreur : ${RESET}"
