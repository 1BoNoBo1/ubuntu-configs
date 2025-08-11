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


# Aliases et Fonctions de Vérification pour Borg Backup

# Aliases pratiques (à ajouter dans votre mon_shell ou ~/.bashrc)
alias borg-backup-now='sudo systemctl start borg-backup.service' # Démarre immédiatement la sauvegarde Borg
alias borg-backup-status='sudo systemctl status borg-backup.service' # Vérifie l'état du service de sauvegarde Borg
alias borg-backup-log='sudo tail -n 50 /var/log/borg_backup.log'
alias borg-list='borg list /home/jim/kDrive/INFORMATIQUE/PC_TUF/borgrepo'
alias borg-restore-last='LATEST=$(borg list /home/jim/kDrive/INFORMATIQUE/PC_TUF/borgrepo --format="{archive}\n" | tail -n1) && sudo /usr/local/sbin/borg_restore.sh "$LATEST"'
alias borg-check-timer='systemctl status borg-backup.timer'
alias borg-check-repo='ls -ld /home/jim/kDrive/INFORMATIQUE/PC_TUF/borgrepo'

# aliases  pour recupération de données
alias ccxt_universel_v2='( cd "$HOME/DEV/CODE_PERSO/DEV/trading/ccxt_universel_v2" && docker compose up --build )'

