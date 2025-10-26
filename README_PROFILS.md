# 🖥️ Système de Profils Multi-Machines

## Vue d'ensemble

Le système de profils multi-machines permet de gérer automatiquement différentes configurations selon la machine utilisée. Chaque profil définit :
- **Modules à charger** : Essentiels, standard ou complets selon les ressources
- **Mode adaptatif** : MINIMAL, STANDARD ou PERFORMANCE
- **Alias spécifiques** : Adaptés au type de machine (portable vs desktop)
- **Fonctions dédiées** : Outils spécifiques au matériel et usage

## 📁 Structure

```
profiles/
├── machine_detector.sh       # Détection automatique de la machine
├── profile_loader.sh          # Chargement orchestré des profils
├── TuF/                       # Profil desktop gaming/production
│   ├── config.sh              # Configuration TuF
│   └── scripts/
│       └── fix_pipewire_bt.sh # Fix audio Bluetooth
├── PcDeV/                     # Profil ultraportable
│   └── config.sh              # Configuration PcDeV optimisée batterie
└── default/                   # Profil universel par défaut
    └── config.sh              # Configuration standard
```

## 🎯 Profils Disponibles

### **TuF** (Desktop)
```yaml
Type: Desktop gaming/production
Mode: PERFORMANCE
RAM: 8GB+
Modules: Complets (tous les outils)
Spécificités:
  - Fix audio PipeWire Bluetooth
  - Outils développeur complets
  - Monitoring système avancé
  - Docker et virtualisation
```

**Commandes spéciales TuF:**
- `fix-audio` : Corriger les problèmes audio Bluetooth
- `restart-pipewire` : Redémarrer le service PipeWire
- `status-audio` : Vérifier l'état du système audio
- `system-monitor` : Monitoring système détaillé

### **PcDeV** (Ultraportable)
```yaml
Type: Ultraportable
Mode: MINIMAL
RAM: 1-4GB
Modules: Essentiels uniquement
Spécificités:
  - Optimisation batterie
  - Gestion WiFi/Bluetooth
  - Contrôle luminosité
  - Mode économie/performance
```

**Commandes spéciales PcDeV:**
- `battery` / `bat` : Statut batterie détaillé
- `eco-mode` : Activer mode économie d'énergie
- `perf-mode` : Activer mode performance (sur secteur)
- `wifi-on/off` : Gérer le WiFi rapidement
- `bt-on/off` : Gérer le Bluetooth rapidement
- `quick-status` : Statut système ultra-rapide

### **default** (Universel)
```yaml
Type: Universel (machine non identifiée)
Mode: STANDARD (détection auto)
RAM: Variable
Modules: Standard équilibrés
Spécificités:
  - Configuration équilibrée
  - Détection automatique des ressources
  - Compatible tout matériel
```

**Commandes spéciales default:**
- `system-info` : Informations système complètes
- `quick-monitor` : Monitoring rapide
- `set-profile [nom]` : Changer de profil manuellement
- `show-profile` : Afficher le profil actuel

## 🔍 Détection Automatique

Le système détecte automatiquement la machine selon l'ordre de priorité suivant :

### 1️⃣ **Configuration Manuelle** (priorité maximale)
```bash
# Définir un profil manuellement
set-profile TuF
# ou
switch-profile PcDeV
```

Le profil est enregistré dans `~/.config/ubuntu-configs/machine_profile`

### 2️⃣ **Hostname**
```bash
Hostname: TuF → Profil TuF
Hostname: PcDeV → Profil PcDeV
```

### 3️⃣ **Caractéristiques Matérielles**
```bash
Batterie présente + RAM ≤ 4GB → PcDeV
Pas de batterie + périphériques audio → TuF
```

### 4️⃣ **Scripts Spécifiques**
```bash
Présence de fix_pipewire_bt.sh → TuF
```

### 5️⃣ **Fallback**
```bash
Aucune correspondance → default
```

## 🚀 Utilisation

### Automatique (recommandé)

Le profil est chargé automatiquement à chaque ouverture de terminal (bash ou zsh). Aucune action requise !

```bash
# Ouvrir un nouveau terminal
→ Détection automatique du profil
→ Chargement des modules adaptés
→ Configuration spécifique appliquée
```

### Manuelle

```bash
# Voir le profil actuel
show-profile

# Lister les profils disponibles
list-profiles

# Changer de profil
set-profile TuF        # Pour le desktop
set-profile PcDeV      # Pour l'ultraportable
set-profile default    # Pour configuration standard

# Recharger le profil après modification
reload-profile
```

## 📋 Commandes Universelles

Ces commandes sont disponibles dans **tous les profils** :

```bash
# Gestion des profils
list-profiles          # Lister tous les profils
show-profile           # Afficher profil actuel
set-profile [nom]      # Changer de profil
reload-profile         # Recharger le profil

# Système adaptatif
adaptive-status        # État du système adaptatif
detect_and_classify    # Détecter ressources

# Aide
aide                   # Aide-mémoire interactif
raccourcis             # Liste des raccourcis
```

## ⚙️ Personnalisation

### Créer un Nouveau Profil

```bash
# 1. Créer la structure
mkdir -p ~/ubuntu-configs/profiles/MonProfil/{scripts,config}

# 2. Créer config.sh
cat > ~/ubuntu-configs/profiles/MonProfil/config.sh << 'EOF'
#!/bin/bash
export PROFILE_NAME="MonProfil"
export PROFILE_TYPE="custom"
export PROFILE_MODE="STANDARD"

# ... configuration personnalisée ...
EOF

# 3. Activer le profil
set-profile MonProfil
```

### Modifier un Profil Existant

```bash
# Éditer le profil
nano ~/ubuntu-configs/profiles/TuF/config.sh

# Recharger pour appliquer
reload-profile
```

### Ajouter des Scripts au Profil

```bash
# Placer le script dans le dossier scripts/
cp mon_script.sh ~/ubuntu-configs/profiles/TuF/scripts/

# Créer un alias dans config.sh
echo "alias mon-cmd='bash ~/ubuntu-configs/profiles/TuF/scripts/mon_script.sh'" \
  >> ~/ubuntu-configs/profiles/TuF/config.sh

# Recharger
reload-profile
```

## 🔧 Modules par Profil

### Profil TuF (Mode PERFORMANCE)
```
✅ utilitaires_systeme.sh      # Outils système complets
✅ outils_fichiers.sh          # Gestion avancée fichiers
✅ outils_productivite.sh      # Notes, Pomodoro, tasks, etc.
✅ outils_developpeur.sh       # Git, projets, serveurs
✅ outils_reseau.sh            # Diagnostics réseau
✅ outils_multimedia.sh        # Images, vidéos, audio, PDF
✅ aide_memoire.sh             # Aide interactive complète
✅ raccourcis_pratiques.sh     # Navigation ultra-rapide
✅ nettoyage_securise.sh       # Nettoyage avec 4 niveaux protection
```

### Profil PcDeV (Mode MINIMAL)
```
✅ utilitaires_systeme.sh      # Outils système de base
✅ outils_fichiers.sh          # Gestion fichiers
✅ aide_memoire.sh             # Aide rapide
✅ raccourcis_pratiques.sh     # Navigation rapide
❌ Modules lourds désactivés   # Économie mémoire
```

### Profil default (Mode STANDARD)
```
✅ utilitaires_systeme.sh      # Outils système
✅ outils_fichiers.sh          # Gestion fichiers
✅ outils_productivite.sh      # Productivité
✅ aide_memoire.sh             # Aide
✅ raccourcis_pratiques.sh     # Navigation
✅ nettoyage_securise.sh       # Nettoyage
```

## 📊 Variables d'Environnement

Chaque profil exporte ces variables :

```bash
PROFILE_NAME="TuF"              # Nom du profil actif
PROFILE_TYPE="desktop"          # Type de machine
PROFILE_MODE="PERFORMANCE"      # Mode adaptatif forcé
CURRENT_PROFILE="TuF"           # Profil en cours
CURRENT_PROFILE_DIR="..."       # Chemin du profil
MACHINE_PROFILE="TuF"           # Profil détecté
```

Utilisation dans vos scripts :
```bash
if [[ "$PROFILE_NAME" == "TuF" ]]; then
    # Code spécifique au desktop
fi
```

## 🐛 Dépannage

### Le mauvais profil est chargé

```bash
# Vérifier la détection
show-profile

# Forcer manuellement
set-profile [nom_correct]

# Vérifier le hostname
hostname
# Si besoin, renommer la machine
sudo hostnamectl set-hostname TuF
```

### Les modules ne se chargent pas

```bash
# Vérifier que le répertoire existe
ls -la ~/ubuntu-configs/mon_shell/

# Recharger manuellement
source ~/ubuntu-configs/profiles/profile_loader.sh

# Vérifier les erreurs
bash -x ~/ubuntu-configs/profiles/profile_loader.sh 2>&1 | less
```

### Profil manuel ignoré

```bash
# Vérifier le fichier de config manuel
cat ~/.config/ubuntu-configs/machine_profile

# Si vide ou incorrect, redéfinir
set-profile TuF
```

### Commandes spéciales absentes

```bash
# Vérifier que le profil est bien chargé
echo $PROFILE_NAME

# Vérifier que les fonctions sont chargées
type eco-mode        # Pour PcDeV
type fix-audio       # Pour TuF
type system-info     # Pour default
```

## 🔄 Migration depuis l'Ancien Système

L'ancien système chargeait tous les modules de `~/.mon_shell/*.sh` pour toutes les machines.

**Avantages du nouveau système :**
- ✅ Chargement adapté aux ressources disponibles
- ✅ Outils spécifiques au matériel (audio, batterie, etc.)
- ✅ Meilleure performance (modules essentiels uniquement sur PcDeV)
- ✅ Configuration centralisée et maintenable
- ✅ Support multi-machines sans duplication

**Pas de migration nécessaire :** Le système détecte et configure automatiquement !

## 📚 Exemples d'Usage

### Scénario 1 : Travail sur le Desktop (TuF)

```bash
# Ouverture du terminal → Profil TuF chargé automatiquement
🖥️ Profil TuF (Desktop) - Mode PERFORMANCE

# Problème audio Bluetooth
fix-audio

# Monitoring système complet
system-monitor

# Développement
cd ~/Projets
analyser_projet
serveur_simple 8080
```

### Scénario 2 : Déplacement avec Ultraportable (PcDeV)

```bash
# Ouverture du terminal → Profil PcDeV chargé automatiquement
💻 Profil PcDeV (Ultraportable) - Mode MINIMAL

# Vérifier la batterie
battery

# Activer mode économie
eco-mode

# Travail léger
cd ~/Documents
chercher rapport.pdf

# Désactiver WiFi pour économiser
wifi-off

# Plus tard, sur secteur
perf-mode
wifi-on
```

### Scénario 3 : Nouvelle Machine Non Configurée

```bash
# Ouverture du terminal → Profil default chargé
🌐 Profil Default (Universel) - Mode STANDARD

# Voir les infos système
system-info

# Décider du profil approprié
set-profile TuF  # Si desktop
# ou
set-profile PcDeV  # Si portable

# Recharger
source ~/.bashrc
```

## 🎓 Bonnes Pratiques

### 1. Configuration Manuelle pour Multi-Boot
```bash
# Sur chaque OS, définir le profil approprié
set-profile TuF
```

### 2. Scripts Portables
```bash
# Utiliser les variables de profil
if [[ "$PROFILE_MODE" == "MINIMAL" ]]; then
    # Version légère
else
    # Version complète
fi
```

### 3. Personnalisation Progressive
```bash
# Commencer avec le profil default
# Observer l'usage
# Migrer vers TuF ou PcDeV selon les besoins
# Personnaliser finement
```

### 4. Backup de Configuration
```bash
# Sauvegarder les personnalisations
cp -r ~/ubuntu-configs/profiles ~/backup/

# Version git (recommandé)
cd ~/ubuntu-configs
git add profiles/
git commit -m "Personnalisation profils"
git push
```

## 📖 Références

- **Documentation principale** : [CLAUDE.md](CLAUDE.md)
- **Architecture multi-machines** : [ARCHITECTURE_MULTI_MACHINES.md](ARCHITECTURE_MULTI_MACHINES.md)
- **Système adaptatif** : [README_Adaptive.md](README_Adaptive.md)
- **Sécurité nettoyage** : [SECURITE_NETTOYAGE.md](SECURITE_NETTOYAGE.md)
- **Guide modules** : [GUIDE_MODULES_SIMPLES.md](GUIDE_MODULES_SIMPLES.md)

## 🔗 Intégration

Le système de profils s'intègre avec :
- ✅ **Système adaptatif** : Détection ressources (MINIMAL/STANDARD/PERFORMANCE)
- ✅ **Modules mon_shell** : Chargement sélectif selon profil
- ✅ **Aliases** : Commandes communes + spécifiques au profil
- ✅ **Backup restic** : Configuration adaptée par profil
- ✅ **WebDAV kDrive** : Montage selon ressources disponibles

---

**Version :** 1.0
**Dernière mise à jour :** Octobre 2025
**Auteur :** ubuntu-configs team
**Licence :** Projet personnel
