#!/bin/bash
# ------------------------------------------------------------
# Script : ~/.mon_setup/aliases.sh
# Installe et configure Borg Backup avec systemd
# Dépôt chiffré local dans un dossier synchronisé avec kDrive
# Usage : sudo ./borg_setup.sh [chemin/vers/repo/local]
# Compatibilité : Ubuntu ≥ 24.04 / Debian ≥ 12 && bash/zsh
# Auteur : Jean BoNoBo - 2025
# ------------------------------------------------------------

# ---------- alias de base ----------
alias ll='ls -la --color=auto'          # Liste détaillée avec couleurs
alias l='ls -CF'                        # Liste courte avec couleurs
alias grep='grep --color=auto'          # grep avec couleurs
alias cp='cp -i'                        # cp interactif pour éviter les écrasements
alias mv='mv -i'                        # mv interactif pour éviter les écrasements
alias rm='rm -i'                        # rm interactif pour éviter les suppressions accidentelles
alias h='history'                       # Alias pour history
# ========== fonctions système ==========

alias reload='source ~/.zshrc && printf "${VERT}RECHARGEMENT SHELL${RESET}\n"'  # Alias pour recharger le shell avec un message de confirmation.
alias disque_UUID='lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,LABEL,UUID && '    # Affiche les UUID des disques
alias disque_usage='df -hT && echo && sudo du -sh /home/*'                      # Affiche l'utilisation des disques et des répertoires home
alias flatup='flatpak update -y && printf "${VERT}✔ Flatpak à jour${RESET}\n"'  # Met à jour les flatpaks avec un message de confirmation.
alias snapup='sudo snap refresh && printf "${VERT}✔ Snap à jour${RESET}\n"'     # Met à jour les snaps avec un message de confirmation.