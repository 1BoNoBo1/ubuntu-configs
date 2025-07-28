
# .mon_shell

**.mon_shell** est un ensemble de scripts, fonctions et alias pour personnaliser et automatiser votre shell Zsh sous Linux (Ubuntu/Debian).  
Il centralise la gestion des couleurs, des alias dynamiques, de la maintenance système, de la sécurité (UFW), des snapshots, des sauvegardes et bien plus.

## Structure

```
.mon_shell/
├── aliases.sh              # Alias courants et utilitaires
├── colors.sh               # Variables de couleurs pour le shell
├── functions_utils.sh      # Fonctions utilitaires (couleurs, alias dynamiques, backup)
├── functions_system.sh     # Maintenance système, snapshots, logs, Docker, disques
├── functions_security.sh   # Fonctions de gestion du pare-feu UFW
```

## Installation

1. **Cloner ou copier** ce dossier dans `~/.mon_shell`
2. **Ajouter dans votre `~/.zshrc`** :
    ```zsh
    # Chargement des scripts .mon_shell
    for f in ~/.mon_shell/*.sh; do source "$f"; done
    ```

## Principales fonctionnalités

- **Alias pratiques** : `ll`, `reload`, `flatup`, `snapup`, etc.
- **Couleurs personnalisées** pour vos messages shell (`$VERT`, `$ROUGE`, etc.)
- **Fonctions système** :  
  - `maj_ubuntu` : mise à jour complète du système  
  - `snapshot_rapide` : snapshot Timeshift  
  - `nettoyer_logs`, `docker_mise_a_jour`, `analyse_disque`, etc.
- **Sécurité** :  
  - `activer_ufw`, `desactiver_ufw`, `status_ufw`, `bloquer_tout`
- **Utilitaires** :  
  - `echo_color` : messages colorés  
  - `mkalias_color` : création d’alias dynamiques colorés  
  - `backup_mon_shell` : sauvegarde vers un dépôt GitHub

## Exemple d’utilisation

```zsh
maj_ubuntu
# 🔄 Mise à jour complète du système...
# ✅ Système à jour et propre.

mkalias_color bonjour VERT "echo Salut" "Coucou en vert !"
# Crée un alias 'bonjour' qui affiche un message vert.
```

## Sauvegarde

Pour sauvegarder vos scripts sur GitHub :
```zsh
backup_mon_shell ~/ubuntu-configs
```

## Personnalisation

Ajoutez vos propres alias ou fonctions dans des fichiers séparés pour garder la maintenance facile.

---

**Auteur** : Jim  
**Licence** : MIT  