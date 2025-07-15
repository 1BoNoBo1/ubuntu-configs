# ~/.mon_shell/colors.sh
# Définition des codes couleur ANSI‑C et exportation.
# Utilisation : printf "$${VERT}Texte coloré$${RESET}\n"
RESET=$'\e[0m'    # $${RESET}
VERT=$'\e[32m'    # $${VERT}...$${RESET}
ROUGE=$'\e[31m'   # $${ROUGE}...$${RESET}
JAUNE=$'\e[33m'   # $${JAUNE}...$${RESET}
BLEU=$'\e[34m'    # $${BLEU}...$${RESET}
CYAN=$'\e[36m'    # $${CYAN}...$${RESET}
MAGENTA=$'\e[35m' # $${MAGENTA}...$${RESET}
GRIS=$'\e[90m'    # $${GRIS}...$${RESET}
export RESET VERT ROUGE JAUNE BLEU CYAN MAGENTA GRIS
