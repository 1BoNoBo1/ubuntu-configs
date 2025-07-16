# ~/.mon_setup/aliases.sh
# Mise à jour complète du système puis confirmation verte.
#alias maj_systeme='sudo apt update && sudo apt upgrade -y && printf "${VERT}✔ Mise à jour terminée${RESET}\n"'

# Message de bienvenue bleu gras.
# EX: alias hello='printf "${BLEU}\e[1mSalut, $USER${RESET}\n"'
alias ll='ls -la --color=auto'
alias l='ls -CF'
# ========== fonctions système ==========

alias reload='source ~/.zshrc && printf "${VERT}RECHARGEMENT SHELL${RESET}\n"'
alias disque_UUID='lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,LABEL,UUID && '
alias disque_usage='df -hT && echo && sudo du -sh /home/*'
alias flatup='flatpak update -y && printf "${VERT}✔ Flatpak à jour${RESET}\n"'
alias snapup='sudo snap refresh && printf "${VERT}✔ Snap à jour${RESET}\n"'
alias essai='echo hello; printf "${BLEU}on dirait que cela fonctionne${RESET}\n"'
