# ~/.mon_shell/colors.sh  – remplace le contenu par ceci
autoload -Uz colors && colors   # palette Zsh
RESET=${reset_color}

VERT=$fg[green];   ROUGE=$fg[red];     JAUNE=$fg[yellow]
BLEU=$fg[blue];    CYAN=$fg[cyan];     MAGENTA=$fg[magenta]
GRIS=$fg_bold[black]

export RESET VERT ROUGE JAUNE BLEU CYAN MAGENTA GRIS

# Pour les messages d'erreur en rouge et gras
ERREUR="${ROUGE}\e[1mErreur : ${RESET}"