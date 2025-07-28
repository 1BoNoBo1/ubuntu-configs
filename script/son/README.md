# 🔊 Correctif PipeWire Bluetooth

Ce script corrige les coupures et latences audio rencontrées avec les casques
Bluetooth lorsque PipeWire est utilisé (Ubuntu 24.04+ / Debian 12+).

## Installation rapide

```bash
# Depuis la racine du dépôt
./script/son/fix_pipewire_bt.sh
```

Le script crée un fichier `fix-bt-latence.conf` dans
`~/.config/pipewire/pipewire-pulse.conf.d/` puis redémarre les services PipeWire
pour appliquer les réglages.

Ces paramètres sont stockés dans votre dossier utilisateur et seront conservés
lors des mises à jour du système.

_Auteur : Jean BoNoBo, 2025._
