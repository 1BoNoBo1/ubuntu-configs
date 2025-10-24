#!/usr/bin/env zsh
# ~/.mon_shell/colors.sh
# Fichier de couleurs pour le shell.
# Chargé par le fichier .zshrc.
# --------------------------------------------------
# ---------- Couleurs de zsh ----------
# Chargement des couleurs de zsh
# Utilise les couleurs prédéfinies de zsh.
# Pour les couleurs personnalisées, on utilise les variables de couleur.
# --------------------------------------------------

autoload -Uz colors && colors   # Charge les couleurs de zsh
RESET=${reset_color}            # Couleur de réinitialisation

VERT=$fg[green];   ROUGE=$fg[red];     JAUNE=$fg[yellow]
BLEU=$fg[blue];    CYAN=$fg[cyan];     MAGENTA=$fg[magenta]
GRIS=$fg_bold[black]

export RESET VERT ROUGE JAUNE BLEU CYAN MAGENTA GRIS

# Pour les messages d'erreur en rouge et gras
ERREUR="${ROUGE}\e[1mErreur : ${RESET}"
