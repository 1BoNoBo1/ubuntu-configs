# Exemples d'Utilisation - Système de Profils

Exemples pratiques et scénarios d'usage réels du système de profils.

## Table des Matières

- [Scénarios Utilisateur](#scénarios-utilisateur)
- [Exemples par Profil](#exemples-par-profil)
- [Intégration avec Autres Systèmes](#intégration-avec-autres-systèmes)
- [Cas d'Usage Avancés](#cas-dusage-avancés)
- [Dépannage Courant](#dépannage-courant)
- [Workflows Quotidiens](#workflows-quotidiens)

---

## Scénarios Utilisateur

### Scénario 1: Développeur Multi-Machines

**Contexte:** Développeur avec desktop bureau (TuF) et ultraportable (PcDeV)

**Configuration Desktop (TuF):**
```bash
# Détection automatique par hostname
hostname
# → TuF

# Premier lancement terminal
source ~/.bashrc
# Sortie:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖥️  Profil TuF (Desktop) - Mode PERFORMANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#    🔊 Fix audio Bluetooth disponible: fix-audio
#    ⚡ Mode: PERFORMANCE (tous les outils chargés)
#    🛠️  Outils développeur: disponibles

# Vérifier profil
show-profile
# Sortie:
# 📋 Profil Actuel
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Nom: TuF
#   Type: desktop
#   Mode: PERFORMANCE

# Utilisation quotidienne
dev                           # Accès rapide projets
analyser_projet              # Analyse projet courant
serveur_simple 8080          # Serveur dev rapide
system-monitor               # Monitoring complet
```

**Configuration Ultraportable (PcDeV):**
```bash
# Sur l'ultraportable
hostname
# → PcDeV

source ~/.bashrc
# Sortie:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💻 Profil PcDeV (Ultraportable) - Mode MINIMAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#    📦 Modules: Essentiels uniquement (économie mémoire)
#    🔋 Mode: MINIMAL (optimisé batterie)
#    ⚠️  Sur batterie - Mode économie recommandé (eco-mode)

# Optimisation batterie
battery                      # Statut batterie
eco-mode                     # Mode économie
wifi-off                     # Désactiver WiFi

# Travail léger
quick-status                 # Monitoring léger
cd ~/Documents
chercher rapport.pdf         # Recherche fichiers
```

---

### Scénario 2: Machine Partagée / Multi-Boot

**Contexte:** Machine avec plusieurs OS ou utilisateurs

**Configuration Manuelle:**
```bash
# Utilisateur 1 préfère profil TuF
switch-profile TuF
source ~/.bashrc

# Utilisateur 2 préfère profil PcDeV (économie ressources)
switch-profile PcDeV
source ~/.bashrc

# Vérifier configuration persistante
cat ~/.config/ubuntu-configs/machine_profile
# → TuF (ou PcDeV selon utilisateur)

# Chaque utilisateur a son profil indépendant
# Pas de conflit entre utilisateurs
```

---

### Scénario 3: Nouvelle Machine Non Identifiée

**Contexte:** Première utilisation sur machine jamais configurée

```bash
# Premier lancement
source ~/.bashrc
# Sortie:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 Profil Default (Universel) - Mode STANDARD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#    🌐 Mode: STANDARD (détection automatique)
#    💡 Pour utiliser un profil spécifique:
#       set-profile TuF      (Desktop avec audio)
#       set-profile PcDeV    (Ultraportable)

# Analyser la machine
system-info
# Sortie:
# 🖥️  Informations Système
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Machine: ubuntu-laptop
#   OS: Ubuntu 24.04.1 LTS
#   Kernel: 6.14.0-33-generic
#   CPU: Intel Core i5-8250U @ 1.60GHz
#   RAM: 3.8Gi / 8Gi
#   Disque: 45G / 256G (18%)
#   Type: Portable
#   🔋 Batterie: 68%

# Décider du profil approprié (portable léger)
set-profile PcDeV
source ~/.bashrc
# Maintenant profil PcDeV chargé
```

---

## Exemples par Profil

### Profil TuF - Workflow Development

```bash
# ========================================
# Journée type développeur desktop
# ========================================

# Matin: Vérification système
system-monitor
# CPU: 8.2% | RAM: 6.5Gi / 16Gi | Disque: 27%

# Problème audio Bluetooth casque
fix-audio
# 🔄 Correction audio Bluetooth en cours...
# ✅ Services redémarrés
# ✅ Configuration appliquée
# ✅ Audio Bluetooth opérationnel

# Développement
dev                           # cd ~/Projets && ls
cd mon-projet
analyser_projet
# 📊 Analyse du Projet: mon-projet
# Type: Node.js application
# Fichiers: 143
# Lignes de code: 8,521

# Lancement serveur dev
serveur_simple 8080
# 🌐 Serveur HTTP démarré sur port 8080
# 📂 Répertoire: /home/user/Projets/mon-projet
# 🔗 URL: http://localhost:8080

# Git workflow
gs                            # git status -sb
gl                            # git log graph
gd                            # git diff

# Docker
dps                           # docker ps -a
dlog container-name           # docker logs -f

# Fin journée: Monitoring final
system-monitor
```

### Profil PcDeV - Workflow Mobile

```bash
# ========================================
# Journée type ultraportable
# ========================================

# Matin: Check batterie
battery
# 🔋 Statut Batterie - PcDeV
# state: full
# percentage: 100%
# time to empty: N/A
# energy-rate: 0W

# Trajet: Mode économie
eco-mode
# 🌿 Activation Mode Économie...
#   ✅ Luminosité: 30%
#   ✅ Bluetooth: Désactivé
#   🌿 Mode économie activé

wifi-off                      # Économiser batterie
# 📡 WiFi désactivé

# Travail offline
cd ~/Documents
chercher contrat.pdf
# 📄 contrat_2024.pdf (256 KB)
# 📄 contrat_v2.pdf (198 KB)

editer contrat_2024.pdf

# Monitoring léger
quick-status
# ⚡ Statut Rapide - PcDeV
# CPU: 4.2% | RAM: 2.1Gi / 4.0Gi
# Disque: 38% utilisé | 🔋 Batterie: 85%
# 📡 WiFi: Désactivé

# Arrivée bureau (secteur disponible)
perf-mode
# ⚡ Activation Mode Performance...
#   ✅ Luminosité: 80%
#   ✅ WiFi et Bluetooth: Activés

wifi-on
# 📡 WiFi activé

# Synchronisation
cd ~/Projets
git pull
git push

# Fin journée
battery
# 🔋 Batterie: 42%
# Mode économie pour le trajet retour
eco-mode
```

### Profil Default - Workflow Découverte

```bash
# ========================================
# Exploration machine inconnue
# ========================================

# Analyser le système
system-info
# 🖥️  Informations Système
# Machine: test-vm
# OS: Ubuntu 24.04 LTS
# RAM: 4Gi / 4Gi
# Type: Desktop

# Monitoring
quick-monitor
# 📊 Monitoring Rapide
# CPU: 15% | RAM: 2.1Gi / 4Gi
# Top 5 processus:
#   gnome-shell: 8.2%
#   firefox: 6.1%

# Tester fonctionnalités disponibles
aide
# 📚 Aide Rapide
# Modules chargés: utilitaires_systeme, outils_fichiers...

raccourcis
# 🔖 Raccourcis Disponibles
# Navigation: ll, la, cd-, ..., ...
# Système: update, clean, disk, mem

# Décider du profil permanent
list-profiles
# 📋 Profils Disponibles
# TuF, PcDeV, default

set-profile TuF
source ~/.bashrc
```

---

## Intégration avec Autres Systèmes

### Intégration avec Backup Restic

```bash
# ========================================
# Profil TuF: Backup complet
# ========================================

# Backup automatique avec tous les modules
backup-now
# Configuration adaptée au mode PERFORMANCE
# Compression maximale, tous fichiers

# ========================================
# Profil PcDeV: Backup minimal
# ========================================

# Backup uniquement essentiel
backup-now --exclude multimedia
# Mode MINIMAL: Backup rapide, moins de ressources
```

### Intégration avec WebDAV kDrive

```bash
# ========================================
# Profil TuF: Montage automatique
# ========================================

# Mount WebDAV au démarrage (resources disponibles)
# Auto-configuré dans profil

# ========================================
# Profil PcDeV: Montage à la demande
# ========================================

# Sur batterie: Pas de mount automatique
# Sur secteur: Mount disponible
kdrive_mount
```

### Intégration Système Adaptatif

```bash
# ========================================
# Profil TuF force PERFORMANCE
# ========================================

adaptive-status
# Mode Adaptatif: PERFORMANCE (forcé par profil TuF)
# RAM: 16GB → Tous modules chargés
# CPU: 8 cœurs → Pas de limitation

# ========================================
# Profil PcDeV force MINIMAL
# ========================================

adaptive-status
# Mode Adaptatif: MINIMAL (forcé par profil PcDeV)
# RAM: 4GB → Modules essentiels uniquement
# Optimisations batterie actives

# ========================================
# Profil default: Détection auto
# ========================================

adaptive-status
# Mode Adaptatif: STANDARD (détection automatique)
# RAM: 8GB → Modules standard
# Configuration équilibrée
```

---

## Cas d'Usage Avancés

### Profil Temporaire pour Session Spécifique

```bash
# Session de développement intensive temporaire
# Sur machine habituellement PcDeV

# Basculer temporairement vers mode PERFORMANCE
export FORCE_ADAPTIVE_MODE="PERFORMANCE"
source ~/ubuntu-configs/mon_shell/adaptive_detection.sh

# OU créer profil temporaire
mkdir -p /tmp/temp_profile
cat > /tmp/temp_profile/config.sh << 'EOF'
export PROFILE_NAME="TempDev"
export PROFILE_MODE="PERFORMANCE"
MODULES_TEMPDEV=(
    "utilitaires_systeme.sh:Système"
    "outils_developpeur.sh:Dev"
)
EOF

# Pas persistant, disparaît au reboot
```

### Profil Conditionnel selon Heure

```bash
# Dans custom config.sh

# Mode économie la nuit
current_hour=$(date +%H)
if [[ $current_hour -ge 22 ]] || [[ $current_hour -lt 6 ]]; then
    export PROFILE_MODE="MINIMAL"
    eco-mode &>/dev/null
else
    export PROFILE_MODE="STANDARD"
fi
```

### Multi-Profils pour Différents Projets

```bash
# Profil Web Development
cat > ~/ubuntu-configs/profiles/WebDev/config.sh << 'EOF'
export PROFILE_NAME="WebDev"
export PROFILE_MODE="PERFORMANCE"
MODULES_WEBDEV=(
    "outils_developpeur.sh:Dev tools"
    "outils_reseau.sh:Network"
)
alias serve='python3 -m http.server'
alias npm-dev='npm run dev'
EOF

# Profil Data Science
cat > ~/ubuntu-configs/profiles/DataSci/config.sh << 'EOF'
export PROFILE_NAME="DataSci"
export PROFILE_MODE="PERFORMANCE"
MODULES_DATASCI=(
    "outils_developpeur.sh:Dev"
    "outils_multimedia.sh:Media"
)
alias jupyter='jupyter lab'
alias py='python3'
EOF

# Basculer selon projet
cd ~/Projets/webapp && switch-profile WebDev
cd ~/Projets/ml-model && switch-profile DataSci
```

---

## Dépannage Courant

### Profil Incorrect Chargé

```bash
# Vérifier profil actuel
show-profile
# Nom: default  (devrait être TuF)

# Vérifier hostname
hostname
# ubuntu-desktop  (pas TuF)

# Solution 1: Renommer machine
sudo hostnamectl set-hostname TuF
source ~/.bashrc

# Solution 2: Configuration manuelle
switch-profile TuF
source ~/.bashrc

# Vérifier persistance
cat ~/.config/ubuntu-configs/machine_profile
# TuF
```

### Modules ne se Chargent Pas

```bash
# Symptôme: Commandes manquantes
analyser_projet
# Command not found

# Diagnostic
show-profile
# Vérifier modules chargés

# Solution: Vérifier profil et modules
cat ~/ubuntu-configs/profiles/$PROFILE_NAME/config.sh | grep MODULES
# Vérifier que module est listé

# Recharger
reload-profile

# Test direct module
source ~/ubuntu-configs/mon_shell/outils_developpeur.sh
analyser_projet
# Si fonctionne: Problème dans profil
# Si ne fonctionne pas: Problème dans module
```

### Conflit Profils Multi-Boot

```bash
# Problème: Profil desktop chargé sur laptop boot

# Identifier le boot
uname -r
# 6.14.0-33-generic

# Vérifier config
cat ~/.config/ubuntu-configs/machine_profile
# TuF  (incorrect pour laptop boot)

# Solution: Profil automatique par OS
# Créer script dans .bashrc avant source profils

if [[ "$(uname -r)" =~ "generic" ]]; then
    # Boot laptop
    rm ~/.config/ubuntu-configs/machine_profile
elif [[ "$(uname -r)" =~ "lowlatency" ]]; then
    # Boot desktop
    echo "TuF" > ~/.config/ubuntu-configs/machine_profile
fi

source ~/ubuntu-configs/profiles/profile_loader.sh
```

---

## Workflows Quotidiens

### Workflow Développeur Full-Stack

```bash
# Matin (Desktop TuF)
system-monitor                # Check système
dev                          # cd ~/Projets
cd fullstack-app

# Frontend
cd frontend
npm-dev &                    # Alias npm run dev
serveur_simple 3000          # Vite dev server

# Backend
cd ../backend
serveur_simple 8080          # API server

# Database
docker-compose up -d
dps                          # Vérifier containers
dlog api-container           # Suivre logs

# Git workflow
gs                           # Status rapide
gl                           # Log graph
gd                           # Diff changes

# Tests
npm test
npm run build

# Fin journée
git add .
git commit -m "feat: Add new feature"
git push
system-monitor               # Check final
```

### Workflow Sysadmin

```bash
# Monitoring système (Profil TuF ou default)
system-monitor               # Vue générale

# Maintenance
maj_ubuntu                   # Updates système
nettoyer_logs               # Cleanup logs
analyse_disque              # Disk analysis

# Backup
backup-now                  # Restic backup
backup-check                # Verify integrity

# Services
systemctl status nginx
systemctl restart apache2

# Réseau
verifier_ports              # Check open ports
tester_connexion google.com # Network test

# Docker
docker_mise_a_jour          # Docker maintenance

# Logs
journalctl -f               # Follow system logs
journalctl -p err           # Errors only
```

### Workflow Étudiant Mobile

```bash
# Trajet université (PcDeV sur batterie)
battery                      # 95%
eco-mode                     # Économie
wifi-off                     # Offline

cd ~/Cours
chercher "Machine Learning"
# Lecture documents offline

# Arrivée université (WiFi + secteur)
perf-mode                    # Performance
wifi-on

# Synchronisation
cd ~/Projets/TP1
git pull
code .                       # VSCode

# Travail
quick-status                 # Monitoring léger

# Pause
wifi-off                     # Économie
bright-low                   # Luminosité basse

# Retour actif
wifi-on
bright-med

# Fin journée
git add .
git commit -m "TP: Progress"
git push

battery                      # Check pour trajet retour
# 45% → Suffisant
wifi-off
eco-mode
```

---

## Références

- **API Reference:** [API_PROFILS.md](API_PROFILS.md)
- **Architecture:** [ARCHITECTURE_PROFILS.md](ARCHITECTURE_PROFILS.md)
- **Sécurité:** [SECURITE_PROFILS.md](SECURITE_PROFILS.md)
- **Guide Développeur:** [DEVELOPPEUR_PROFILS.md](DEVELOPPEUR_PROFILS.md)
- **Migration:** [MIGRATION_PROFILS.md](MIGRATION_PROFILS.md)
- **Documentation Principale:** [README_PROFILS.md](../README_PROFILS.md)

---

**Version:** 1.0
**Dernière mise à jour:** Octobre 2025
