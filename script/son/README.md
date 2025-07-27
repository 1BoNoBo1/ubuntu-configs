# 🔊 PipeWire Bluetooth Fix – Ubuntu 24.04+ / Debian 12+

Corrige les problèmes de saccades ou coupures de son lors de l’utilisation de casques ou enceintes Bluetooth sous PipeWire.

## 📦 Installation

```bash
git clone https://github.com/1BoNoBo1/ubuntu-configs/script/son/fix_pipewire_bt.sh
cd pipewire_fix_bluetooth
chmod +x fix_pipewire_bt.sh
./fix_pipewire_bt.sh


✅ Ce que fait le script
Crée une configuration locale dans ~/.config/pipewire/pipewire-pulse.conf.d

Fixe les buffers audio à des valeurs stables (tlength, frag, quantum…)

Redémarre PipeWire proprement

🛡️ Persistant
Les réglages sont stockés dans ton dossier utilisateur et ne seront pas écrasés par les mises à jour système.

👤 Auteur
Jean BoNoBo, 2025.
