# ~/.mon_setup/aliases.sh
# Fichier d'alias pour le shell.
# Chargé par le fichier .zshrc.
# --------------------------------------------------
# ---------- alias de base ----------
alias ll='ls -la --color=auto'          # Liste détaillée avec couleurs
alias l='ls -CF'                        # Liste courte avec couleurs
# ========== fonctions système ==========

alias reload='source ~/.zshrc && printf "${VERT}RECHARGEMENT SHELL${RESET}\n"'  # Alias pour recharger le shell avec un message de confirmation.
alias disque_UUID='lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,LABEL,UUID && '    # Affiche les UUID des disques
alias disque_usage='df -hT && echo && sudo du -sh /home/*'                      # Affiche l'utilisation des disques et des répertoires home
alias flatup='flatpak update -y && printf "${VERT}✔ Flatpak à jour${RESET}\n"'  # Met à jour les flatpaks avec un message de confirmation.
alias snapup='sudo snap refresh && printf "${VERT}✔ Snap à jour${RESET}\n"'     # Met à jour les snaps avec un message de confirmation.


# ========== Backup Management (Restic) ==========
# Modern backup system with restic
alias backup-now='restic-backup-now'
alias backup-list='restic-list'
alias backup-status='restic-timer'
alias backup-restore='restic-restore'
alias backup-check='restic-check'

# aliases  pour recupération de données
alias ccxt_universel_v2='( cd "$HOME/DEV/CODE_PERSO/DEV/trading/ccxt_universel_v2" && docker compose up --build )'

