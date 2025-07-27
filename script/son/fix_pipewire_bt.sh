#!/bin/bash
# ================================================
# Script : fix_pipewire_bt.sh
# Corrige les saccades audio Bluetooth sur PipeWire
# Compatibilité : Ubuntu ≥ 24.04 / Debian ≥ 12
# Auteur : Jean BoNoBo - 2025
# ================================================

set -e

echo "🔧 Création du dossier de configuration PipeWire local..."
mkdir -p ~/.config/pipewire/pipewire-pulse.conf.d

echo "✍️  Application des réglages optimisés dans ~/.config/pipewire/pipewire-pulse.conf.d/fix-bt-latence.conf..."
cat <<EOF > ~/.config/pipewire/pipewire-pulse.conf.d/fix-bt-latence.conf
pulse.properties = {
    pulse.min.req          = 512/48000
    pulse.default.req      = 1024/48000
    pulse.min.frag         = 1024/48000
    pulse.default.frag     = 4096/48000
    pulse.default.tlength  = 8192/48000
    pulse.min.quantum      = 1024/48000
    pulse.idle.timeout     = 0
}
EOF

echo "🔁 Redémarrage de PipeWire..."
systemctl --user daemon-reexec
systemctl --user restart pipewire.service pipewire-pulse.service

echo "✅ Correctif appliqué. Teste ton son Bluetooth !"
