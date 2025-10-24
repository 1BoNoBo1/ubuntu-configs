#!/usr/bin/env zsh
# --------------------------------------------------
# Fonctions WebDAV kDrive - Gestion avancée
# Intégration avec le système mon_shell existant
# --------------------------------------------------

# ---------- kdrive_status_complet ----------
unalias kdrive_status_complet 2>/dev/null
kdrive_status_complet() {
    echo_color "== Statut WebDAV kDrive ==" $CYAN

    # Vérifier le point de montage
    local KDRIVE_MOUNT="/home/$USER/SAUVEGARDE/kdrive"

    if mountpoint -q "$KDRIVE_MOUNT" 2>/dev/null; then
        echo_color "✅ kDrive monté dans: $KDRIVE_MOUNT" $VERT

        # Afficher l'espace disque
        echo_color "\n📊 Espace disque:" $BLEU
        df -h "$KDRIVE_MOUNT" 2>/dev/null | tail -1

        # Vérifier l'accès en écriture
        if touch "$KDRIVE_MOUNT/.test_write" 2>/dev/null; then
            rm -f "$KDRIVE_MOUNT/.test_write"
            echo_color "✅ Accès en écriture: OK" $VERT
        else
            echo_color "⚠️  Accès en écriture: Limité" $JAUNE
        fi

        # Lister le contenu
        echo_color "\n📁 Contenu du répertoire:" $BLEU
        ls -la "$KDRIVE_MOUNT" 2>/dev/null | head -10

    else
        echo_color "❌ kDrive non monté" $ROUGE

        # Vérifier si le service est actif
        if systemctl is-active --quiet kdrive-mount.service; then
            echo_color "🔧 Service systemd: actif" $JAUNE
        else
            echo_color "⚠️  Service systemd: inactif" $JAUNE
        fi
    fi

    # Vérifier la configuration
    local SECRETS_FILE="$HOME/.davfs2/secrets"
    if [[ -f "$SECRETS_FILE" ]]; then
        echo_color "\n🔐 Configuration credentials: présente" $VERT
        echo_color "   Permissions: $(stat -c %a "$SECRETS_FILE")" $BLEU
    else
        echo_color "\n❌ Configuration credentials: manquante" $ROUGE
    fi
}

# ---------- kdrive_mount_force ----------
unalias kdrive_mount_force 2>/dev/null
kdrive_mount_force() {
    echo_color "🔄 Montage forcé de kDrive..." $JAUNE

    local KDRIVE_MOUNT="/home/$USER/SAUVEGARDE/kdrive"

    # Démontage si déjà monté
    if mountpoint -q "$KDRIVE_MOUNT" 2>/dev/null; then
        echo_color "⚠️  Démontage de l'ancien point..." $JAUNE
        sudo umount "$KDRIVE_MOUNT" 2>/dev/null || true
        sleep 2
    fi

    # Vérifier que le répertoire existe
    mkdir -p "$KDRIVE_MOUNT"

    # Tentative de montage
    if sudo /usr/local/bin/kdrive-mount mount; then
        echo_color "✅ kDrive monté avec succès" $VERT
        kdrive_status_complet
    else
        echo_color "❌ Échec du montage kDrive" $ROUGE
        echo_color "💡 Suggestions:" $BLEU
        echo_color "   1. Vérifiez vos credentials: ~/.davfs2/secrets" $NC
        echo_color "   2. Testez la connectivité réseau" $NC
        echo_color "   3. Consultez les logs: journalctl -u kdrive-mount.service" $NC
    fi
}

# ---------- kdrive_sync_test ----------
unalias kdrive_sync_test 2>/dev/null
kdrive_sync_test() {
    echo_color "🧪 Test de synchronisation kDrive..." $CYAN

    local KDRIVE_MOUNT="/home/$USER/SAUVEGARDE/kdrive"
    local TEST_FILE="$KDRIVE_MOUNT/test_sync_$(date +%s).txt"

    if ! mountpoint -q "$KDRIVE_MOUNT" 2>/dev/null; then
        echo_color "❌ kDrive non monté. Montage automatique..." $ROUGE
        kdrive_mount_force
        return $?
    fi

    # Test d'écriture
    echo_color "📝 Test d'écriture..." $BLEU
    if echo "Test de synchronisation - $(date)" > "$TEST_FILE" 2>/dev/null; then
        echo_color "✅ Écriture: OK" $VERT

        # Test de lecture
        echo_color "📖 Test de lecture..." $BLEU
        if cat "$TEST_FILE" >/dev/null 2>&1; then
            echo_color "✅ Lecture: OK" $VERT

            # Nettoyage
            rm -f "$TEST_FILE" 2>/dev/null
            echo_color "✅ Test de synchronisation réussi" $VERT
        else
            echo_color "❌ Échec de lecture" $ROUGE
        fi
    else
        echo_color "❌ Échec d'écriture" $ROUGE
        echo_color "💡 Vérifiez les permissions et l'espace disponible" $JAUNE
    fi
}

# ---------- kdrive_backup_prepare ----------
unalias kdrive_backup_prepare 2>/dev/null
kdrive_backup_prepare() {
    echo_color "🎯 Préparation de l'environnement de sauvegarde..." $CYAN

    local SAUVEGARDE_DIR="/home/$USER/SAUVEGARDE"
    local KDRIVE_MOUNT="$SAUVEGARDE_DIR/kdrive"
    local RESTIC_DIR="$SAUVEGARDE_DIR/restic-repo"
    local LOCAL_BACKUP="$SAUVEGARDE_DIR/local-backup"

    # Mode adaptatif : kDrive ou local
    if mountpoint -q "$KDRIVE_MOUNT" 2>/dev/null; then
        echo_color "☁️  Mode kDrive: Sauvegarde distante activée" $VERT

        # Créer la structure sur kDrive
        mkdir -p "$KDRIVE_MOUNT/restic-repo"
        mkdir -p "$KDRIVE_MOUNT/archives"
        mkdir -p "$KDRIVE_MOUNT/config"

        # Lien vers kDrive
        if [[ ! -L "$RESTIC_DIR" ]]; then
            ln -sf "$KDRIVE_MOUNT/restic-repo" "$RESTIC_DIR"
            echo_color "🔗 Lien symbolique créé: $RESTIC_DIR → kDrive" $VERT
        fi

        echo_color "📍 Répertoires kDrive:" $BLEU
        echo_color "   - kDrive:      $KDRIVE_MOUNT" $NC
        echo_color "   - Restic repo: $RESTIC_DIR (→ kDrive)" $NC
        echo_color "   - Archives:    $KDRIVE_MOUNT/archives" $NC

    else
        echo_color "💾 Mode Local: Sauvegarde locale activée" $JAUNE
        echo_color "   (kDrive sera utilisé quand disponible)" $NC

        # Créer la structure locale
        mkdir -p "$LOCAL_BACKUP/restic-repo"
        mkdir -p "$LOCAL_BACKUP/archives"
        mkdir -p "$LOCAL_BACKUP/config"

        # Lien vers local
        if [[ ! -L "$RESTIC_DIR" ]]; then
            ln -sf "$LOCAL_BACKUP/restic-repo" "$RESTIC_DIR"
            echo_color "🔗 Lien symbolique créé: $RESTIC_DIR → local" $VERT
        fi

        echo_color "📍 Répertoires locaux:" $BLEU
        echo_color "   - Local backup: $LOCAL_BACKUP" $NC
        echo_color "   - Restic repo:  $RESTIC_DIR (→ local)" $NC
        echo_color "   - Archives:     $LOCAL_BACKUP/archives" $NC
    fi

    echo_color "✅ Environnement de sauvegarde prêt" $VERT
}

# ---------- kdrive_switch_mode ----------
unalias kdrive_switch_mode 2>/dev/null
kdrive_switch_mode() {
    local mode="${1:-auto}"
    local SAUVEGARDE_DIR="/home/$USER/SAUVEGARDE"
    local KDRIVE_MOUNT="$SAUVEGARDE_DIR/kdrive"
    local RESTIC_DIR="$SAUVEGARDE_DIR/restic-repo"
    local LOCAL_BACKUP="$SAUVEGARDE_DIR/local-backup"

    echo_color "🔄 Commutation du mode de sauvegarde..." $CYAN

    case "$mode" in
        "kdrive"|"remote")
            if mountpoint -q "$KDRIVE_MOUNT" 2>/dev/null; then
                rm -f "$RESTIC_DIR"
                ln -sf "$KDRIVE_MOUNT/restic-repo" "$RESTIC_DIR"
                echo_color "☁️  Mode kDrive activé" $VERT
            else
                echo_color "❌ kDrive non monté. Montez d'abord avec: kdrive-mount" $ROUGE
                return 1
            fi
            ;;
        "local")
            rm -f "$RESTIC_DIR"
            ln -sf "$LOCAL_BACKUP/restic-repo" "$RESTIC_DIR"
            echo_color "💾 Mode local activé" $VERT
            ;;
        "auto")
            kdrive_backup_prepare
            return $?
            ;;
        *)
            echo_color "Usage: kdrive_switch_mode {kdrive|local|auto}" $ROUGE
            return 1
            ;;
    esac

    echo_color "✅ Mode commutré: $mode" $VERT
    echo_color "📍 Restic repo: $(readlink "$RESTIC_DIR")" $BLEU
}

# ---------- kdrive_maintenance ----------
unalias kdrive_maintenance 2>/dev/null
kdrive_maintenance() {
    echo_color "🔧 Maintenance WebDAV kDrive..." $CYAN

    local KDRIVE_MOUNT="/home/$USER/SAUVEGARDE/kdrive"

    # Nettoyer le cache davfs2
    echo_color "🧹 Nettoyage du cache davfs2..." $BLEU
    rm -rf ~/.davfs2/cache/* 2>/dev/null || true

    # Redémarrer le service
    echo_color "🔄 Redémarrage du service..." $BLEU
    sudo systemctl restart kdrive-mount.service

    # Attendre le montage
    sleep 3

    # Vérifier le statut
    kdrive_status_complet

    echo_color "✅ Maintenance terminée" $VERT
}

# ---------- kdrive_logs ----------
unalias kdrive_logs 2>/dev/null
kdrive_logs() {
    echo_color "📋 Logs WebDAV kDrive..." $CYAN

    # Logs systemd
    echo_color "== Logs Service systemd ==" $BLEU
    sudo journalctl -u kdrive-mount.service -n 20 --no-pager

    # Logs davfs2 (si disponibles)
    echo_color "\n== Logs davfs2 ==" $BLEU
    if [[ -f /var/log/davfs2.log ]]; then
        sudo tail -20 /var/log/davfs2.log
    else
        echo_color "Pas de logs davfs2 spécifiques trouvés" $JAUNE
    fi

    # Messages kernel relatifs au montage
    echo_color "\n== Messages kernel (mount) ==" $BLEU
    sudo dmesg | grep -i "davfs\|fuse" | tail -10 || echo_color "Aucun message kernel récent" $JAUNE
}