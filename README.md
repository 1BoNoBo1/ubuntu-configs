# ubuntu-configs

Ce dépôt contient divers scripts et configurations destinés à Ubuntu/Debian.
Vous y trouverez notamment :

- **mon_shell/** : ensemble de fonctions et alias pour personnaliser votre shell.
- **borg_setup.sh** : installation automatisée de Borg Backup avec systemd.
- **script/son/** : correctif PipeWire pour le Bluetooth.

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

## Mise en place de Borg Backup

Exécutez le script d'installation en tant que root :

```bash
sudo ./borg_setup.sh
```

Le script crée un dépôt chiffré dans `~/kDrive/INFORMATIQUE/PC_TUF/borgrepo`,
installe les scripts de sauvegarde/restauration dans `/usr/local/sbin/` et active
le timer systemd `borg-backup.timer` (tous les jours à 02:30).
Les journaux se trouvent dans `/var/log/borg_backup.log`.

## Correctif PipeWire Bluetooth

Dans `script/son/`, le script `fix_pipewire_bt.sh` applique des réglages pour les
casques Bluetooth instables sous PipeWire :

```bash
./script/son/fix_pipewire_bt.sh
```

Ce script crée un fichier de configuration dans `~/.config/pipewire` et redémarre
les services audio de l'utilisateur.

---

Ce dépôt est libre et ouvert aux améliorations.
