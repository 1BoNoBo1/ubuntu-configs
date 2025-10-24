# Configuration WebDAV kDrive Infomaniak

Guide d'installation et d'utilisation du montage WebDAV pour Infomaniak kDrive avec auto-montage et gestion avancée.

## Installation Rapide

```bash
# Exécuter le script d'installation
sudo ./setup_webdav_kdrive.sh
```

Le script configure automatiquement :
- Installation de `davfs2`
- Configuration sécurisée des credentials
- Création du service systemd d'auto-montage
- Intégration avec le système `mon_shell`

## Structure des Répertoires

```
~/SAUVEGARDE/
├── kdrive/              # Point de montage WebDAV kDrive
└── restic-repo/         # Lien symbolique vers kdrive/restic-repo/
```

## Commandes Disponibles

### Gestion de Base
```bash
kdrive-mount         # Monte kDrive WebDAV
kdrive-unmount       # Démonte kDrive WebDAV
kdrive-status        # Statut simple du montage
sauvegarde          # Accès rapide à ~/SAUVEGARDE
```

### Fonctions Avancées (mon_shell)
```bash
kdrive_status_complet    # Diagnostic complet (espace, permissions, contenu)
kdrive_mount_force       # Montage forcé avec diagnostic
kdrive_sync_test         # Test de synchronisation lecture/écriture
kdrive_backup_prepare    # Préparation environnement sauvegarde
kdrive_maintenance       # Maintenance (cache, redémarrage service)
kdrive_logs              # Affichage des logs (systemd, davfs2, kernel)
```

### Service Systemd
```bash
sudo systemctl start kdrive-mount.service    # Démarrer le montage
sudo systemctl stop kdrive-mount.service     # Arrêter le montage
sudo systemctl enable kdrive-mount.service   # Auto-démarrage au boot
sudo systemctl status kdrive-mount.service   # Statut du service
```

## Configuration

### Credentials Sécurisés
- **Fichier**: `~/.davfs2/secrets` (permissions 600)
- **Format**: `URL username password`
- **Sécurité**: Accessible uniquement à votre utilisateur

### Configuration davfs2
- **Optimisations**: Cache, locks, uploads différés
- **Compatibilité**: Infomaniak kDrive spécifique
- **Performance**: Configuration optimisée pour WebDAV

## Intégration avec Restic

Le système prépare l'environnement pour la migration Borg → Restic :

```bash
# Préparer l'environnement de sauvegarde
kdrive_backup_prepare

# Structure automatique créée :
~/SAUVEGARDE/kdrive/restic-repo/    # Dépôt restic sur kDrive
~/SAUVEGARDE/kdrive/archives/       # Archives de sauvegarde
~/SAUVEGARDE/kdrive/config/         # Configurations
~/SAUVEGARDE/restic-repo/           # Lien symbolique local
```

## Diagnostic et Dépannage

### Tests de Fonctionnement
```bash
# Test complet de la configuration
kdrive_status_complet

# Test de synchronisation
kdrive_sync_test

# Consultation des logs
kdrive_logs
```

### Problèmes Courants

**Montage échoue** :
```bash
# Vérifier les credentials
cat ~/.davfs2/secrets

# Forcer un nouveau montage
kdrive_mount_force

# Redémarrer le service
sudo systemctl restart kdrive-mount.service
```

**Permissions insuffisantes** :
```bash
# Vérifier l'appartenance au groupe davfs2
groups | grep davfs2

# Rejoindre le groupe (puis se reconnecter)
sudo usermod -a -G davfs2 $USER
```

**Cache corrompus** :
```bash
# Nettoyage et maintenance
kdrive_maintenance
```

## Sécurité

### Bonnes Pratiques
- **Credentials** : Ne jamais partager le fichier `~/.davfs2/secrets`
- **Permissions** : Répertoire de montage accessible uniquement à votre utilisateur
- **Réseau** : Connexion HTTPS sécurisée avec Infomaniak

### Monitoring
- **Logs** : Surveillance via `journalctl -u kdrive-mount.service`
- **Espace** : Monitoring automatique de l'espace disponible
- **Connectivité** : Test périodique avec `kdrive_sync_test`

## Migration depuis BorgBackup

Le système WebDAV prépare la transition :

1. **Phase actuelle** : BorgBackup → `~/kDrive/INFORMATIQUE/PC_TUF/borgrepo`
2. **Phase transition** : WebDAV → `~/SAUVEGARDE/kdrive/`
3. **Phase finale** : Restic → `~/SAUVEGARDE/kdrive/restic-repo/`

Les alias Borg existants restent fonctionnels pendant la transition.

## Support et Documentation

- **Logs détaillés** : `kdrive_logs`
- **Status complet** : `kdrive_status_complet`
- **Documentation davfs2** : `man davfs2`
- **Configuration Infomaniak** : [Documentation kDrive](https://www.infomaniak.com/fr/support/faq/2370)

---

**Auteur** : Configuration générée par Claude Code
**Compatibilité** : Ubuntu ≥ 20.04, Debian ≥ 11
**Date** : 2025