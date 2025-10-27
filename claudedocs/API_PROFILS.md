# API de Référence - Système de Profils Multi-Machines

Documentation complète de l'API du système de profils ubuntu-configs.

## Table des Matières

- [machine_detector.sh](#machine_detectorsh)
- [profile_loader.sh](#profile_loadersh)
- [Profils - TuF](#profil-tuf)
- [Profils - PcDeV](#profil-pcdev)
- [Profils - default](#profil-default)
- [Variables d'Environnement](#variables-denvironnement)
- [Codes de Retour](#codes-de-retour)

---

## machine_detector.sh

Module de détection automatique de la machine basé sur une hiérarchie de 5 niveaux de priorité.

### detecter_machine()

Détecte automatiquement la machine et retourne le nom du profil approprié.

**Syntaxe:**
```bash
detecter_machine
```

**Paramètres:** Aucun

**Retour:**
- **stdout**: Nom du profil détecté (`TuF`, `PcDeV`, ou `default`)
- **Code de retour**: `0` (succès)

**Algorithme de Détection (ordre de priorité):**

1. **Configuration manuelle** (priorité 1 - maximale)
   - Fichier: `~/.config/ubuntu-configs/machine_profile`
   - Validation: Whitelist stricte (`TuF`, `PcDeV`, `default`)
   - Sécurité: Affichage d'avertissement si profil invalide

2. **Hostname** (priorité 2)
   - Patterns reconnus:
     - `TuF|tuf|TUF` → Profil TuF
     - `PcDeV|pcdev|PCDEV|ultraportable` → Profil PcDeV

3. **Caractéristiques matérielles** (priorité 3)
   - Détection batterie: `/sys/class/power_supply/BAT*`
   - Si portable + RAM ≤ 4GB → Profil PcDeV
   - Si desktop + périphériques audio → Profil TuF

4. **Scripts spécifiques** (priorité 4)
   - Présence de `~/ubuntu-configs/script/son/fix_pipewire_bt.sh` → Profil TuF

5. **Fallback** (priorité 5 - défaut)
   - Aucune correspondance → Profil default

**Exemple:**
```bash
# Détection automatique
profile=$(detecter_machine)
echo "Profil détecté: $profile"

# Utilisation dans un script
case "$(detecter_machine)" in
    TuF)
        echo "Desktop détecté"
        ;;
    PcDeV)
        echo "Ultraportable détecté"
        ;;
    default)
        echo "Machine générique"
        ;;
esac
```

**Notes de Sécurité:**
- Validation stricte contre whitelist pour prévenir l'injection
- Pas de confiance aveugle du contenu du fichier de configuration
- Messages d'erreur envoyés sur stderr

---

### afficher_info_machine()

Affiche des informations détaillées sur la machine et le profil détecté.

**Syntaxe:**
```bash
afficher_info_machine PROFIL
```

**Paramètres:**
- `PROFIL`: Nom du profil à afficher (string)

**Retour:**
- **stdout**: Informations formatées
- **Code de retour**: `0`

**Sortie:**
```
🖥️  Détection de machine:
   Hostname: TuF
   Type: Desktop
   RAM: 16Gi
   Profil sélectionné: TuF
```

**Exemple:**
```bash
profile=$(detecter_machine)
afficher_info_machine "$profile"
```

---

### detecter_type_machine()

Détermine si la machine est un portable ou un desktop.

**Syntaxe:**
```bash
detecter_type_machine
```

**Paramètres:** Aucun

**Retour:**
- **stdout**: `Portable` ou `Desktop`
- **Code de retour**: `0`

**Méthode de Détection:**
- Recherche de `/sys/class/power_supply/BAT*` ou `/sys/class/power_supply/battery`
- Présence de batterie → Portable
- Absence de batterie → Desktop

**Exemple:**
```bash
type=$(detecter_type_machine)
if [[ "$type" == "Portable" ]]; then
    echo "Configuration pour portable"
fi
```

---

### definir_profil_manuel()

Définit manuellement le profil à utiliser avec validation et sécurité.

**Syntaxe:**
```bash
definir_profil_manuel PROFIL
```

**Paramètres:**
- `PROFIL`: Nom du profil (`TuF`, `PcDeV`, ou `default`)

**Retour:**
- **Code 0**: Profil défini avec succès
- **Code 1**: Profil invalide ou paramètre manquant

**Validation:**
- Vérification contre whitelist stricte
- Rejet de profils non autorisés
- Messages d'erreur explicites

**Sécurité:**
- Création atomique du fichier avec umask 077
- Permissions restrictives (700) sur le répertoire
- Écriture sécurisée sans risque de race condition

**Exemple:**
```bash
# Définir le profil TuF
definir_profil_manuel TuF

# Sortie:
# ✅ Profil manuel défini: TuF
#    Rechargez votre shell pour appliquer les changements.

# Tentative avec profil invalide
definir_profil_manuel MonProfil

# Sortie:
# ❌ Profil invalide: MonProfil
#    Profils valides: TuF PcDeV default
```

---

## profile_loader.sh

Module de chargement orchestré des profils avec sécurité renforcée.

### load_machine_profile()

Charge le profil machine approprié avec validations de sécurité multiples.

**Syntaxe:**
```bash
load_machine_profile
```

**Paramètres:** Aucun

**Retour:**
- **Code 0**: Profil chargé avec succès
- **Code 1**: Erreur de chargement

**Variables exportées:**
- `CURRENT_PROFILE`: Nom du profil chargé
- `CURRENT_PROFILE_DIR`: Chemin absolu du répertoire du profil

**Sécurité:**
- **Validation du nom**: Regex `^[a-zA-Z0-9_]+$` uniquement
- **Protection traversée**: Utilisation de `realpath` pour validation de chemin
- **Vérification whitelist**: Profils autorisés uniquement
- **Fallback sécurisé**: Retour au profil default en cas de problème
- **Isolation**: Pas d'export de fonctions (prévention hijacking)

**Exemple:**
```bash
if load_machine_profile; then
    echo "Profil chargé: $CURRENT_PROFILE"
    echo "Répertoire: $CURRENT_PROFILE_DIR"
else
    echo "Erreur de chargement du profil" >&2
    exit 1
fi
```

**Messages d'Erreur:**
```bash
⚠️  Répertoire des profils introuvable
⚠️  Détecteur de machine introuvable
⚠️  Nom de profil invalide détecté, utilisation du profil default
⚠️  Tentative de traversée de chemin détectée
⚠️  Configuration du profil introuvable
❌ Profil default introuvable - installation corrompue
❌ Erreur critique de chargement du profil
```

---

### load_profile_modules()

Charge les modules spécifiques au profil avec validation de sécurité.

**Syntaxe:**
```bash
load_profile_modules
```

**Paramètres:** Aucun

**Retour:**
- **Code 0**: Modules chargés avec succès
- **Code 1**: Profil non défini

**Prérequis:**
- Variable `PROFILE_NAME` doit être définie
- Module `chargeur_modules.sh` doit exister

**Whitelist des Modules Autorisés:**
```bash
utilitaires_systeme.sh
outils_fichiers.sh
outils_productivite.sh
outils_developpeur.sh
outils_reseau.sh
outils_multimedia.sh
aide_memoire.sh
raccourcis_pratiques.sh
nettoyage_securise.sh
chargeur_modules.sh
```

**Sécurité:**
- Validation stricte contre whitelist
- Validation du format de nom (regex `^[a-zA-Z0-9_.-]+\.sh$`)
- Protection contre traversée de chemin avec `realpath`
- Messages d'avertissement pour modules non autorisés

**Chargement par Profil:**

**TuF** (Mode PERFORMANCE):
```bash
MODULES_TUF=(
    "utilitaires_systeme.sh:Utilitaires système complets"
    "outils_fichiers.sh:Gestion avancée de fichiers"
    "outils_productivite.sh:Outils de productivité"
    "outils_developpeur.sh:Outils développeur complets"
    "outils_reseau.sh:Diagnostics réseau"
    "outils_multimedia.sh:Traitement multimédia"
    "aide_memoire.sh:Système d'aide complet"
    "raccourcis_pratiques.sh:Navigation rapide"
    "nettoyage_securise.sh:Nettoyage sécurisé"
)
```

**PcDeV** (Mode MINIMAL):
```bash
MODULES_PCDEV=(
    "utilitaires_systeme.sh:Utilitaires système de base"
    "outils_fichiers.sh:Gestion de fichiers"
    "aide_memoire.sh:Aide rapide"
    "raccourcis_pratiques.sh:Navigation rapide"
)
```

**default** (Mode STANDARD):
```bash
MODULES_DEFAULT=(
    "utilitaires_systeme.sh:Utilitaires système"
    "outils_fichiers.sh:Gestion de fichiers"
    "outils_productivite.sh:Outils de productivité"
    "aide_memoire.sh:Système d'aide"
    "raccourcis_pratiques.sh:Navigation rapide"
    "nettoyage_securise.sh:Nettoyage sécurisé"
)
```

**Exemple:**
```bash
# Chargement automatique
if load_profile_modules; then
    echo "Modules chargés pour profil $PROFILE_NAME"
fi
```

---

### load_colors()

Charge le système de couleurs standardisé.

**Syntaxe:**
```bash
load_colors
```

**Paramètres:** Aucun

**Retour:** `0` (toujours)

**Variables Exportées:**
```bash
VERT, ROUGE, BLEU, JAUNE, CYAN, MAGENTA, BLANC, GRIS, NC
```

**Fichier Source:** `~/ubuntu-configs/mon_shell/colors.sh`

---

### load_aliases()

Charge les alias communs à tous les profils.

**Syntaxe:**
```bash
load_aliases
```

**Paramètres:** Aucun

**Retour:** `0` (toujours)

**Fichier Source:** `~/ubuntu-configs/mon_shell/aliases.sh`

---

### load_complete_environment()

Fonction maître orchestrant le chargement complet de l'environnement.

**Syntaxe:**
```bash
load_complete_environment
```

**Paramètres:** Aucun

**Retour:**
- **Code 0**: Environnement chargé avec succès
- **Code 1**: Erreur lors du chargement

**Séquence d'Exécution:**
1. Chargement des couleurs (`load_colors`)
2. Chargement du profil machine (`load_machine_profile`)
3. Chargement des modules du profil (`load_profile_modules`)
4. Chargement des alias communs (`load_aliases`)
5. Chargement du système adaptatif (si disponible)

**Exemple:**
```bash
# Dans .bashrc ou .zshrc
if [[ -f ~/ubuntu-configs/profiles/profile_loader.sh ]]; then
    source ~/ubuntu-configs/profiles/profile_loader.sh
    # load_complete_environment est appelé automatiquement
fi
```

---

### reload-profile()

Recharge l'environnement complet du profil.

**Syntaxe:**
```bash
reload-profile
```

**Paramètres:** Aucun

**Retour:** `0` (succès) ou `1` (erreur)

**Utilisation:**
```bash
# Après modification d'un profil
nano ~/ubuntu-configs/profiles/TuF/config.sh
reload-profile
```

---

### list-profiles()

Liste tous les profils disponibles avec leurs descriptions.

**Syntaxe:**
```bash
list-profiles
```

**Paramètres:** Aucun

**Retour:** `0` (toujours)

**Sortie:**
```
📋 Profils Disponibles
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📁 TuF
     Configuration pour PC desktop TuF avec fix audio PipeWire
     Mode: PERFORMANCE

  📁 PcDeV
     Configuration optimisée pour PC ultraportable
     Mode: MINIMAL

  📁 default
     Configuration par défaut pour machines non identifiées
     Mode: STANDARD

Profil actuel: TuF
```

---

### switch-profile()

Change de profil manuellement.

**Syntaxe:**
```bash
switch-profile PROFIL
```

**Paramètres:**
- `PROFIL`: Nom du profil (`TuF`, `PcDeV`, `default`)

**Retour:**
- **Code 0**: Profil changé avec succès
- **Code 1**: Paramètre manquant ou erreur

**Alias:** Utilise `set-profile` ou `definir_profil_manuel` selon disponibilité

**Exemple:**
```bash
# Changer vers profil TuF
switch-profile TuF

# Sans paramètre, affiche l'aide
switch-profile
# Sortie: Usage: switch-profile [TuF|PcDeV|default]
#         + liste des profils
```

---

## Profil TuF

Configuration pour desktop gaming/production avec optimisations audio.

### Variables Exportées

```bash
PROFILE_NAME="TuF"
PROFILE_TYPE="desktop"
PROFILE_MODE="PERFORMANCE"
FORCE_ADAPTIVE_MODE="PERFORMANCE"
HISTSIZE=10000
HISTFILESIZE=20000
EDITOR="nano"
VISUAL="nano"
```

### Fonctions Spécifiques

#### restart-pipewire()

Redémarre tous les services PipeWire.

**Syntaxe:**
```bash
restart-pipewire
```

**Services redémarrés:**
- `pipewire`
- `pipewire-pulse`
- `wireplumber`

**Exemple:**
```bash
restart-pipewire
# Sortie:
# 🔄 Redémarrage de PipeWire...
# ✅ PipeWire redémarré
```

---

#### status-audio()

Vérifie l'état du système audio PipeWire.

**Syntaxe:**
```bash
status-audio
```

**Informations Affichées:**
- Statut service PipeWire
- Liste des périphériques audio (sinks)

**Exemple:**
```bash
status-audio
# Sortie:
# 🔊 Statut Audio PipeWire:
# ● pipewire.service - PipeWire Multimedia Service
# ...
# 0   alsa_output.pci-0000_00_1f.3.analog-stereo
```

---

#### system-monitor()

Monitoring système complet optimisé pour desktop.

**Syntaxe:**
```bash
system-monitor
```

**Métriques Affichées:**
- Utilisation CPU (%)
- Utilisation RAM (utilisée/totale)
- Utilisation disque (/)
- Température CPU (si `sensors` installé)

**Exemple:**
```bash
system-monitor
# Sortie:
# 🖥️  Monitoring Système - TuF
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CPU:
#   Utilisation: 15.2%
# RAM:
#   Utilisée: 8.2Gi / 16Gi (51%)
# Disque:
#   Utilisé: 124G / 476G (27%)
# Température CPU:
#   Core 0: +42.0°C
```

---

### Alias Spécifiques

```bash
# Audio
fix-audio="bash ~/ubuntu-configs/profiles/TuF/scripts/fix_pipewire_bt.sh"
fix-bt-audio="fix-audio"
fix-pipewire="fix-audio"

# Développement
dev="cd ~/Projets && ls -la"
projets="cd ~/Projets && ls -la"

# Système
monitor="htop"
disk="df -h && echo && du -sh * | sort -h"
ports="sudo netstat -tulpn"

# Docker (si installé)
dps="docker ps -a"
dim="docker images"
dlog="docker logs -f"

# Git avancé
gs="git status -sb"
gl="git log --oneline --graph --decorate --all -10"
gd="git diff"
```

---

## Profil PcDeV

Configuration pour ultraportable avec optimisations batterie.

### Variables Exportées

```bash
PROFILE_NAME="PcDeV"
PROFILE_TYPE="laptop"
PROFILE_MODE="MINIMAL"
FORCE_ADAPTIVE_MODE="MINIMAL"
HISTSIZE=1000
HISTFILESIZE=2000
EDITOR="nano"
VISUAL="nano"
```

### Fonctions Spécifiques

#### battery-status()

Affiche le statut détaillé de la batterie.

**Syntaxe:**
```bash
battery-status
```

**Informations Affichées:**
- État de charge (charging/discharging/full)
- Pourcentage de charge
- Temps restant estimé
- Consommation énergétique actuelle

**Exemple:**
```bash
battery-status
# Sortie:
# 🔋 Statut Batterie - PcDeV
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   state: discharging
#   percentage: 78%
#   time to empty: 3.2 hours
#   energy-rate: 12.5W
```

---

#### quick-status()

Monitoring système ultra-léger pour économiser les ressources.

**Syntaxe:**
```bash
quick-status
```

**Métriques Affichées:**
- CPU (%)
- RAM (utilisée/totale)
- Disque (% utilisé)
- Batterie (%)
- État WiFi

**Exemple:**
```bash
quick-status
# Sortie:
# ⚡ Statut Rapide - PcDeV
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   CPU: 8.3%
#   RAM: 2.1Gi / 4.0Gi
#   Disque: 45% utilisé
#   🔋 Batterie: 78%
#   📡 WiFi: Activé
```

---

#### eco-mode()

Active le mode économie d'énergie maximale.

**Syntaxe:**
```bash
eco-mode
```

**Actions:**
- Réduit luminosité à 30%
- Désactive Bluetooth si non utilisé
- Affiche confirmation des actions

**Exemple:**
```bash
eco-mode
# Sortie:
# 🌿 Activation Mode Économie...
#   ✅ Luminosité: 30%
#   ✅ Bluetooth: Désactivé
#   🌿 Mode économie activé
```

---

#### perf-mode()

Active le mode performance (recommandé sur secteur).

**Syntaxe:**
```bash
perf-mode
```

**Actions:**
- Augmente luminosité à 80%
- Active WiFi et Bluetooth
- Affiche confirmation des actions

**Exemple:**
```bash
perf-mode
# Sortie:
# ⚡ Activation Mode Performance...
#   ✅ Luminosité: 80%
#   ✅ WiFi et Bluetooth: Activés
#   ⚡ Mode performance activé
```

---

#### on_battery()

Détecte si la machine fonctionne sur batterie.

**Syntaxe:**
```bash
on_battery
```

**Retour:**
- **Code 0**: Sur batterie
- **Code 1**: Sur secteur ou non applicable

**Exemple:**
```bash
if on_battery; then
    echo "Mode batterie - activation économie d'énergie"
    eco-mode
fi
```

---

### Alias Spécifiques

```bash
# Batterie
battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E 'state|percentage|time'"
bat="battery"

# Économie d'énergie
wifi-off="nmcli radio wifi off && echo '📡 WiFi désactivé'"
wifi-on="nmcli radio wifi on && echo '📡 WiFi activé'"
bt-off="bluetoothctl power off && echo '🔵 Bluetooth désactivé'"
bt-on="bluetoothctl power on && echo '🔵 Bluetooth activé'"

# Luminosité
bright-low="brightnessctl set 30% && echo '💡 Luminosité: 30%'"
bright-med="brightnessctl set 60% && echo '💡 Luminosité: 60%'"
bright-high="brightnessctl set 100% && echo '💡 Luminosité: 100%'"

# Monitoring
cpu="top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print \"CPU: \" 100 - \$1\"%\"}'"
mem="free -h | awk '/^Mem:/ {print \"RAM: \"\$3\" / \"\$2}'"
temp="sensors | grep -i 'core 0' | awk '{print \"CPU: \"\$3}'"

# Navigation
ll="ls -lah"
la="ls -A"
l="ls -CF"
```

---

## Profil default

Configuration universelle pour machines non identifiées.

### Variables Exportées

```bash
PROFILE_NAME="default"
PROFILE_TYPE="universal"
PROFILE_MODE="STANDARD"
HISTSIZE=5000
HISTFILESIZE=10000
EDITOR="${EDITOR:-nano}"
VISUAL="${VISUAL:-nano}"
```

### Fonctions Spécifiques

#### system-info()

Affiche des informations système complètes.

**Syntaxe:**
```bash
system-info
```

**Informations Affichées:**
- Hostname
- Système d'exploitation (nom complet)
- Version kernel
- Modèle CPU
- RAM (utilisée/totale)
- Disque (/)
- Type de machine (Portable/Desktop)
- Batterie (si portable)

**Exemple:**
```bash
system-info
# Sortie:
# 🖥️  Informations Système
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Machine: ubuntu-desktop
#   OS: Ubuntu 24.04.1 LTS
#   Kernel: 6.14.0-33-generic
#   CPU: Intel Core i7-10700K @ 3.80GHz
#   RAM: 8.2Gi / 16Gi
#   Disque: 124G / 476G (27%)
#   Type: Desktop
```

---

#### quick-monitor()

Monitoring rapide avec top 5 des processus.

**Syntaxe:**
```bash
quick-monitor
```

**Métriques Affichées:**
- CPU (%)
- RAM (utilisée/totale)
- Disque (% utilisé)
- Top 5 processus par utilisation mémoire

**Exemple:**
```bash
quick-monitor
# Sortie:
# 📊 Monitoring Rapide
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   CPU: 12.5%
#   RAM: 8.2Gi / 16Gi
#   Disque: 27% utilisé
#   Top 5 processus:
#     /usr/bin/chrome: 15.2%
#     /usr/lib/firefox: 8.4%
#     /usr/bin/code: 6.1%
#     /usr/bin/gnome-shell: 3.9%
#     /usr/lib/systemd: 2.8%
```

---

#### set-profile()

Définit manuellement le profil à utiliser.

**Syntaxe:**
```bash
set-profile PROFIL
```

**Paramètres:**
- `PROFIL`: Nom du profil (`TuF`, `PcDeV`, `default`)

**Retour:**
- **Code 0**: Profil défini avec succès
- **Code 1**: Paramètre manquant

**Exemple:**
```bash
set-profile TuF
# Sortie:
# ✅ Profil manuel défini: TuF
#    Rechargez votre shell: source ~/.bashrc (ou ~/.zshrc)
```

---

#### show-profile()

Affiche le profil actuellement chargé.

**Syntaxe:**
```bash
show-profile
```

**Informations Affichées:**
- Nom du profil
- Type de profil
- Mode adaptatif
- Informations machine (si disponible)

**Exemple:**
```bash
show-profile
# Sortie:
# 📋 Profil Actuel
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Nom: default
#   Type: universal
#   Mode: STANDARD
#
# 🖥️  Détection de machine:
#    Hostname: ubuntu-desktop
#    Type: Desktop
#    RAM: 16Gi
#    Profil sélectionné: default
```

---

### Alias Spécifiques

```bash
# Navigation
ll="ls -lah"
la="ls -A"
l="ls -CF"
..="cd .."
...="cd ../.."

# Sécurité
rm="rm -i"
cp="cp -i"
mv="mv -i"

# Système
update="sudo apt update && sudo apt upgrade -y"
clean="sudo apt autoremove -y && sudo apt autoclean"
disk="df -h"
mem="free -h"

# Réseau
ping="ping -c 5"
myip="curl -s ifconfig.me && echo"
```

---

## Variables d'Environnement

### Variables Globales

Définies par le système de profils et disponibles dans tous les shells.

#### MACHINE_PROFILE

**Description:** Profil détecté par le système
**Défini par:** `machine_detector.sh`
**Valeurs possibles:** `TuF`, `PcDeV`, `default`
**Scope:** Global (export)

```bash
echo "Profil détecté: $MACHINE_PROFILE"
```

---

#### CURRENT_PROFILE

**Description:** Profil actuellement chargé
**Défini par:** `profile_loader.sh` (fonction `load_machine_profile`)
**Valeurs possibles:** `TuF`, `PcDeV`, `default`
**Scope:** Global (export)

```bash
if [[ "$CURRENT_PROFILE" == "TuF" ]]; then
    # Code spécifique TuF
fi
```

---

#### CURRENT_PROFILE_DIR

**Description:** Chemin absolu du répertoire du profil
**Défini par:** `profile_loader.sh` (fonction `load_machine_profile`)
**Exemple:** `/home/user/ubuntu-configs/profiles/TuF`
**Scope:** Global (export)

```bash
# Charger un script du profil
source "$CURRENT_PROFILE_DIR/scripts/mon_script.sh"
```

---

### Variables de Profil

Définies par chaque fichier `config.sh` de profil.

#### PROFILE_NAME

**Description:** Nom du profil
**Défini par:** Chaque `config.sh`
**Valeurs:** `TuF`, `PcDeV`, `default`
**Scope:** Global (export)

---

#### PROFILE_TYPE

**Description:** Type de machine du profil
**Défini par:** Chaque `config.sh`
**Valeurs:** `desktop`, `laptop`, `universal`
**Scope:** Global (export)

---

#### PROFILE_MODE

**Description:** Mode adaptatif du profil
**Défini par:** Chaque `config.sh`
**Valeurs:** `PERFORMANCE`, `STANDARD`, `MINIMAL`
**Scope:** Global (export)

---

#### FORCE_ADAPTIVE_MODE

**Description:** Force un mode adaptatif spécifique
**Défini par:** Profils TuF et PcDeV
**Valeurs:** `PERFORMANCE`, `MINIMAL`
**Usage:** Surcharge la détection automatique
**Scope:** Global (export)

```bash
# Dans config.sh TuF
export FORCE_ADAPTIVE_MODE="PERFORMANCE"
```

---

### Variables de Configuration

#### PROFILES_DIR

**Description:** Répertoire racine des profils
**Défini par:** `profile_loader.sh`
**Valeur:** `$HOME/ubuntu-configs/profiles`
**Scope:** Local au script

---

#### MODULES_TUF / MODULES_PCDEV / MODULES_DEFAULT

**Description:** Tableaux de modules à charger par profil
**Défini par:** Chaque `config.sh`
**Format:** `"fichier.sh:Description"`
**Scope:** Local au profil

```bash
MODULES_TUF=(
    "utilitaires_systeme.sh:Utilitaires système complets"
    "outils_fichiers.sh:Gestion avancée de fichiers"
)
```

---

## Codes de Retour

Documentation des codes de retour standard utilisés dans l'API.

### Codes Standard

| Code | Signification | Utilisation |
|------|---------------|-------------|
| `0` | Succès | Opération réussie |
| `1` | Erreur générale | Échec de l'opération |

### Fonctions et Codes de Retour

#### detecter_machine()
- `0`: Profil détecté avec succès

#### afficher_info_machine()
- `0`: Informations affichées avec succès

#### detecter_type_machine()
- `0`: Type de machine détecté avec succès

#### definir_profil_manuel()
- `0`: Profil défini avec succès
- `1`: Paramètre manquant ou profil invalide

#### load_machine_profile()
- `0`: Profil chargé avec succès
- `1`: Erreur de chargement (répertoire, fichier, ou script manquant)

#### load_profile_modules()
- `0`: Modules chargés avec succès
- `1`: Variable PROFILE_NAME non définie

#### load_complete_environment()
- `0`: Environnement chargé avec succès
- `1`: Erreur lors du chargement du profil

#### switch-profile()
- `0`: Profil changé avec succès
- `1`: Paramètre manquant

---

## Conventions de Nommage

### Fonctions

- **Détection/Information:** `detecter_*`, `afficher_*`
- **Chargement:** `load_*`
- **Actions utilisateur:** `nom-avec-tirets` (kebab-case)
- **Internes:** `nom_avec_underscores` (snake_case)

### Variables

- **Export global:** `MAJUSCULES_AVEC_UNDERSCORES`
- **Local script:** `minuscules_avec_underscores`
- **Tableaux:** `NOM_TABLEAU` (majuscules)

### Fichiers

- **Profils:** `config.sh` (nom standard)
- **Scripts:** `nom_descriptif.sh` (snake_case)
- **Modules:** `categorie_fonction.sh`

---

## Bonnes Pratiques d'Utilisation de l'API

### 1. Toujours Vérifier les Codes de Retour

```bash
# ✅ Bon
if load_machine_profile; then
    echo "Profil chargé"
else
    echo "Erreur de chargement" >&2
    exit 1
fi

# ❌ Mauvais
load_machine_profile
echo "Profil chargé"  # Peut être faux
```

### 2. Utiliser les Variables Exportées

```bash
# ✅ Bon
if [[ "$PROFILE_NAME" == "TuF" ]]; then
    fix-audio
fi

# ❌ Mauvais
if [[ "$(hostname)" == "TuF" ]]; then  # Moins fiable
    fix-audio
fi
```

### 3. Validation des Entrées

```bash
# ✅ Bon
definir_profil_manuel "$user_input"  # Validation intégrée

# ❌ Mauvais
echo "$user_input" > ~/.config/ubuntu-configs/machine_profile  # Pas de validation
```

### 4. Gestion des Erreurs

```bash
# ✅ Bon
profile=$(detecter_machine) || {
    echo "Détection échouée" >&2
    exit 1
}

# ❌ Mauvais
profile=$(detecter_machine)
# Continue sans vérification
```

### 5. Isolation des Fonctions

```bash
# ✅ Bon - Pas d'export -f
function ma_fonction() {
    # Code
}

# ❌ Mauvais - Risque de hijacking
export -f ma_fonction
```

---

## Exemples d'Intégration

### Intégration dans .bashrc

```bash
# Chargement automatique du profil
if [[ -f ~/ubuntu-configs/profiles/profile_loader.sh ]]; then
    source ~/ubuntu-configs/profiles/profile_loader.sh
fi
```

### Script Personnalisé Utilisant l'API

```bash
#!/bin/bash

# Charger les fonctions de détection
source ~/ubuntu-configs/profiles/machine_detector.sh

# Détecter la machine
profile=$(detecter_machine)

# Action selon le profil
case "$profile" in
    TuF)
        echo "Configuration desktop"
        # Commandes spécifiques desktop
        ;;
    PcDeV)
        echo "Configuration portable"
        # Activer mode économie si sur batterie
        source ~/ubuntu-configs/profiles/PcDeV/config.sh
        on_battery && eco-mode
        ;;
    default)
        echo "Configuration standard"
        ;;
esac
```

### Vérification de Profil dans un Script

```bash
#!/bin/bash

# Vérifier que le profil est chargé
if [[ -z "$PROFILE_NAME" ]]; then
    echo "Erreur: Profil non chargé" >&2
    exit 1
fi

# Fonctionnalité selon le profil
if [[ "$PROFILE_MODE" == "PERFORMANCE" ]]; then
    # Opérations lourdes autorisées
    traitement_complet
else
    # Version allégée
    traitement_leger
fi
```

---

## Références

- **Documentation Principale:** [README_PROFILS.md](../README_PROFILS.md)
- **Architecture:** [ARCHITECTURE_PROFILS.md](ARCHITECTURE_PROFILS.md)
- **Sécurité:** [SECURITE_PROFILS.md](SECURITE_PROFILS.md)
- **Guide Développeur:** [DEVELOPPEUR_PROFILS.md](DEVELOPPEUR_PROFILS.md)
- **Exemples:** [EXEMPLES_PROFILS.md](EXEMPLES_PROFILS.md)
- **Migration:** [MIGRATION_PROFILS.md](MIGRATION_PROFILS.md)

---

**Version:** 1.0
**Dernière mise à jour:** Octobre 2025
**Mainteneur:** ubuntu-configs team
