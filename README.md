# ubuntu-configs

Ce dépôt contient divers scripts et configurations destinés à Ubuntu/Debian.
Vous y trouverez notamment :

- **adaptive_ubuntu.sh** : **🆕 système adaptatif intelligent** qui configure Ubuntu selon vos ressources
- **mon_shell/** : ensemble de fonctions et alias pour personnaliser votre shell.
- **setup_restic_modern.sh** : installation moderne de restic avec outils CLI.
- **script/son/** : correctif PipeWire pour le Bluetooth.
- **enhance_ubuntu_geek.sh** : transformation complète Ubuntu → Système Geek.

## Installation du shell personnalisé

```bash
git clone https://github.com/1BoNoBo1/ubuntu-configs.git
cd ubuntu-configs
stow mon_shell
```

Ajoutez ensuite dans votre `~/.zshrc` :

```zsh
for f in ~/.mon_shell/*.sh; do source "$f"; done
```

## Système de Sauvegarde Moderne

Exécutez le script d'installation en tant que root :

```bash
sudo ./setup_restic_modern.sh
```

Le système utilise restic avec stockage adaptatif (local/cloud via WebDAV).
Le script installe restic, les outils CLI modernes (fzf, ripgrep, etc.) et
configure le service systemd `restic-backup.timer` (tous les jours à 03:00).
Les journaux se trouvent dans `/var/log/restic_backup.log`.

## 🎯 Système Adaptatif Intelligent (NOUVEAU)

Configuration Ubuntu qui s'adapte automatiquement à vos ressources matérielles :

```bash
# Détection automatique et configuration optimale
sudo ./adaptive_ubuntu.sh install
```

**Niveaux automatiques :**
- **⚡ MINIMAL** : Systèmes contraints (1-2GB RAM) - Économie maximale
- **📈 STANDARD** : Systèmes équilibrés (2-8GB RAM) - Équilibre optimal
- **🚀 PERFORMANCE** : Systèmes puissants (>8GB RAM) - Performance maximale

**Fonctionnalités :**
- Détection matérielle intelligente (RAM, CPU, stockage)
- Sélection d'outils selon les capacités
- Optimisations mémoire et kernel adaptatives
- Surveillance ajustée aux ressources
- Intégration parfaite avec mon_shell

📋 **Documentation complète :** [README_Adaptive.md](README_Adaptive.md)

## Transformation Complète du Système

Pour une transformation complète Ubuntu → Système Geek :

```bash
sudo ./enhance_ubuntu_geek.sh
```

Ce script installe et configure automatiquement :
- WebDAV kDrive avec montage adaptatif
- Système de sauvegarde restic moderne
- Outils CLI modernes (fzf, ripgrep, bat, exa, zoxide)
- Shell avancé (Oh My Zsh + plugins + Starship)
- Sécurisation système (UFW, Fail2Ban, SSH)
- Environnement de développement (Docker, Node.js)

## Correctif PipeWire Bluetooth

Dans `script/son/`, le script `fix_pipewire_bt.sh` applique des réglages pour les
casques Bluetooth instables sous PipeWire :

```bash
./script/son/fix_pipewire_bt.sh
```

Ce script crée un fichier de configuration dans `~/.config/pipewire` et redémarre
les services audio de l'utilisateur.

---

Ce dépôt est libre et ouvert aux améliorations.