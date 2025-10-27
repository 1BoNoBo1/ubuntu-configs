# Architecture du Système de Profils Multi-Machines

Documentation détaillée de l'architecture, des flux de données et des patterns de conception.

## Table des Matières

- [Vue d'Ensemble](#vue-densemble)
- [Architecture des Composants](#architecture-des-composants)
- [Flux de Données](#flux-de-données)
- [Diagrammes d'Architecture](#diagrammes-darchitecture)
- [Sécurité Architecturale](#sécurité-architecturale)
- [Points d'Extension](#points-dextension)
- [Intégration avec le Système Adaptatif](#intégration-avec-le-système-adaptatif)
- [Patterns de Conception](#patterns-de-conception)

---

## Vue d'Ensemble

Le système de profils multi-machines est conçu selon une architecture modulaire en couches permettant:

- **Détection automatique** de la machine avec hiérarchie de priorités
- **Chargement sélectif** des modules selon les ressources disponibles
- **Sécurité renforcée** avec validation multi-niveaux
- **Extensibilité** via un système de plugins
- **Intégration** avec le système adaptatif ubuntu-configs

### Principes Architecturaux

1. **Séparation des Responsabilités**: Chaque composant a un rôle unique et bien défini
2. **Sécurité par Conception**: Validation et isolation à chaque niveau
3. **Fail-Safe**: Retour automatique à un état sûr en cas d'erreur
4. **Modularité**: Composants indépendants et interchangeables
5. **Découplage**: Interfaces claires entre les composants

---

## Architecture des Composants

### Vue en Couches

```
┌─────────────────────────────────────────────────────────┐
│              Couche Utilisateur (Shell)                 │
│  .bashrc / .zshrc → Commandes utilisateur               │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│         Couche Orchestration (profile_loader.sh)        │
│  • load_complete_environment()                          │
│  • Coordination du chargement                           │
│  • Gestion des erreurs globales                         │
└────────────────────┬────────────────────────────────────┘
                     │
          ┌──────────┴──────────┬──────────────┐
          │                     │              │
┌─────────▼──────────┐ ┌────────▼────────┐ ┌──▼──────────┐
│   Couche Détection │ │ Couche Profils  │ │Couche Modules│
│machine_detector.sh │ │  config.sh      │ │ mon_shell/*  │
│• Détection auto    │ │• Variables env  │ │• Utilitaires │
│• Validation profil │ │• Fonctions      │ │• Outils      │
│• Config manuelle   │ │• Alias          │ │• Aide        │
└────────────────────┘ └─────────────────┘ └──────────────┘
          │                     │              │
          └──────────┬──────────┴──────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│           Couche Sécurité (Transversale)                │
│  • Validation whitelist                                 │
│  • Protection traversée de chemin                       │
│  • Vérification permissions                             │
└─────────────────────────────────────────────────────────┘
```

---

### Composants Principaux

#### 1. Machine Detector (machine_detector.sh)

**Responsabilités:**
- Détection automatique de la machine
- Validation des profils
- Gestion de la configuration manuelle
- Information sur le type de machine

**Dépendances:**
- Système de fichiers (`/sys/`, `/etc/`)
- Commandes système (`hostname`, `free`, `lspci`)

**Interfaces:**
```bash
# Entrée: Aucune
# Sortie: Nom du profil (string)
detecter_machine() → "TuF" | "PcDeV" | "default"

# Entrée: Nom de profil
# Sortie: Code de retour + fichier de config
definir_profil_manuel(PROFIL) → 0 | 1
```

**État:**
- Variable globale: `MACHINE_PROFILE`
- Fichier persistant: `~/.config/ubuntu-configs/machine_profile`

---

#### 2. Profile Loader (profile_loader.sh)

**Responsabilités:**
- Orchestration du chargement complet
- Coordination entre détection, profils et modules
- Gestion des erreurs et fallback
- Validation de sécurité

**Dépendances:**
- `machine_detector.sh`
- Profils (`*/config.sh`)
- Modules (`mon_shell/*.sh`)

**Interfaces:**
```bash
# Chargement complet orchestré
load_complete_environment() → 0 | 1

# Sous-fonctions appelées dans l'ordre
load_colors()
load_machine_profile()
load_profile_modules()
load_aliases()
```

**État:**
- Variables globales: `CURRENT_PROFILE`, `CURRENT_PROFILE_DIR`
- Modules chargés en mémoire (fonctions et alias)

---

#### 3. Profile Configs (TuF/PcDeV/default)

**Responsabilités:**
- Définition des variables de profil
- Déclaration des modules à charger
- Fonctions spécifiques au profil
- Alias personnalisés

**Structure Standard:**
```bash
# 1. Variables de profil
export PROFILE_NAME="..."
export PROFILE_TYPE="..."
export PROFILE_MODE="..."

# 2. Configuration système
export FORCE_ADAPTIVE_MODE="..."
export HISTSIZE=...

# 3. Modules à charger
MODULES_PROFIL=(...)

# 4. Fonctions spécifiques
function_specifique_profil() { ... }

# 5. Alias personnalisés
alias commande="..."

# 6. Messages de bienvenue
echo "Profil chargé"
```

**État:**
- Variables exportées globalement
- Fonctions disponibles dans le shell
- Alias définis pour l'utilisateur

---

#### 4. Modules mon_shell

**Responsabilités:**
- Fonctionnalités réutilisables
- Outils système et développement
- Aide et documentation
- Utilitaires spécialisés

**Catégories:**
```
utilitaires_systeme.sh      → Gestion système
outils_fichiers.sh          → Manipulation fichiers
outils_productivite.sh      → Productivité (notes, tasks)
outils_developpeur.sh       → Développement (git, serveurs)
outils_reseau.sh            → Diagnostics réseau
outils_multimedia.sh        → Traitement média
aide_memoire.sh             → Système d'aide interactif
raccourcis_pratiques.sh     → Navigation rapide
nettoyage_securise.sh       → Nettoyage sécurisé
```

**Chargement:**
- Sélectif selon le profil
- Validation whitelist
- Protection contre injection

---

## Flux de Données

### 1. Flux d'Initialisation (Ouverture de Shell)

```
┌─────────────────────────────────────────────────────────┐
│ 1. Démarrage Shell (.bashrc / .zshrc)                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 2. Source profile_loader.sh                             │
│    → Déclenche load_complete_environment()              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 3. load_colors()                                        │
│    → Charge mon_shell/colors.sh                         │
│    → Définit variables de couleurs                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 4. load_machine_profile()                               │
│    ┌──────────────────────────────────────────────┐    │
│    │ 4.1. Source machine_detector.sh              │    │
│    │ 4.2. Appel detecter_machine()                │    │
│    │      • Vérifie config manuelle               │    │
│    │      • Vérifie hostname                      │    │
│    │      • Détecte matériel                      │    │
│    │      • Scripts spécifiques                   │    │
│    │      • Fallback default                      │    │
│    │ 4.3. Validation nom profil (regex)           │    │
│    │ 4.4. Protection traversée (realpath)         │    │
│    │ 4.5. Source config.sh du profil              │    │
│    │ 4.6. Export CURRENT_PROFILE variables        │    │
│    └──────────────────────────────────────────────┘    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 5. load_profile_modules()                               │
│    ┌──────────────────────────────────────────────┐    │
│    │ 5.1. Vérifie PROFILE_NAME défini            │    │
│    │ 5.2. Source chargeur_modules.sh             │    │
│    │ 5.3. Sélection modules selon profil:        │    │
│    │      • TuF → MODULES_TUF (complets)          │    │
│    │      • PcDeV → MODULES_PCDEV (essentiels)    │    │
│    │      • default → MODULES_DEFAULT (standard)  │    │
│    │ 5.4. Boucle sur chaque module:              │    │
│    │      • Validation whitelist                  │    │
│    │      • Validation format nom (regex)         │    │
│    │      • Protection traversée (realpath)       │    │
│    │      • Source module si valide               │    │
│    └──────────────────────────────────────────────┘    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 6. load_aliases()                                       │
│    → Charge mon_shell/aliases.sh                        │
│    → Définit alias communs                              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 7. Système Adaptatif (optionnel)                        │
│    → Source adaptive_detection.sh si présent            │
│    → Intègre avec FORCE_ADAPTIVE_MODE                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 8. Shell Prêt                                           │
│    • Profil chargé: $CURRENT_PROFILE                    │
│    • Modules actifs selon profil                        │
│    • Fonctions et alias disponibles                     │
└─────────────────────────────────────────────────────────┘
```

---

### 2. Flux de Détection de Machine

```
┌─────────────────────────────────────────────────────────┐
│ Appel: detecter_machine()                               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │ Priorité 1: Manuel    │
         │ Fichier config existe?│
         └───────┬───────────────┘
                 │
         ┌───────▼────────┐
         │ Oui            │ Non
         │                │
┌────────▼────────┐      │
│ Lire fichier    │      │
│ Valider contre  │      │
│ whitelist       │      │
└────────┬────────┘      │
         │               │
    ┌────▼────┐          │
    │ Valide? │          │
    └────┬────┘          │
         │               │
    ┌────▼────┐          │
    │ Oui     │ Non      │
    │         │          │
┌───▼───┐     │          │
│Return │     │          │
│profil │     │          │
└───────┘     │          │
              │          │
              ▼          │
         ┌────────────────▼──────────┐
         │ Priorité 2: Hostname      │
         │ hostname match pattern?   │
         └────────────┬──────────────┘
                      │
              ┌───────▼────────┐
              │ Match?         │
              └───────┬────────┘
                      │
              ┌───────▼────────┐
              │ Oui            │ Non
              │                │
         ┌────▼─────┐          │
         │Return    │          │
         │profil    │          │
         └──────────┘          │
                               │
                    ┌──────────▼──────────────┐
                    │ Priorité 3: Matériel    │
                    │ Détection matérielle    │
                    └──────────┬──────────────┘
                               │
                  ┌────────────▼────────────┐
                  │ Batterie présente?      │
                  └────────────┬────────────┘
                               │
                  ┌────────────▼────────────┐
                  │ Oui                     │ Non
                  │ RAM ≤ 4GB?              │ Audio?
                  │                         │
         ┌────────▼────────┐    ┌──────────▼────────┐
         │Return PcDeV     │    │Return TuF         │
         └─────────────────┘    └───────────────────┘
                  │                         │
                  │                         │
                  │          ┌──────────────▼──────────────┐
                  │          │ Priorité 4: Scripts spéc.   │
                  │          │ fix_pipewire_bt.sh existe?  │
                  │          └──────────────┬──────────────┘
                  │                         │
                  │              ┌──────────▼────────┐
                  │              │ Oui               │ Non
                  │              │                   │
                  │         ┌────▼─────┐             │
                  │         │Return TuF│             │
                  │         └──────────┘             │
                  │                                  │
                  └──────────────────────────────────┘
                                   │
                       ┌───────────▼───────────┐
                       │ Priorité 5: Fallback  │
                       │ Return default        │
                       └───────────────────────┘
```

---

### 3. Flux de Changement de Profil

```
┌─────────────────────────────────────────────────────────┐
│ Utilisateur: switch-profile TuF                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ switch-profile() → definir_profil_manuel()              │
│ 1. Validation paramètre                                 │
│ 2. Validation whitelist                                 │
└────────────────────┬────────────────────────────────────┘
                     │
                ┌────▼─────┐
                │ Valide?  │
                └────┬─────┘
                     │
         ┌───────────┴───────────┐
         │ Oui                   │ Non
         │                       │
         ▼                       ▼
┌────────────────────┐  ┌────────────────────┐
│ Création atomique  │  │ Message d'erreur   │
│ du fichier config  │  │ + liste profils    │
│ Permissions 700    │  │ Return 1           │
│ umask 077          │  └────────────────────┘
└────────┬───────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│ Fichier créé: ~/.config/ubuntu-configs/machine_profile│
│ Contenu: "TuF"                                         │
└────────┬───────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│ Message confirmation                                    │
│ "Rechargez votre shell"                                │
└────────┬───────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│ Utilisateur: source ~/.bashrc                          │
│ → Reprend flux d'initialisation                        │
│ → Détection lit fichier manuel (priorité 1)            │
│ → Charge profil TuF                                    │
└────────────────────────────────────────────────────────┘
```

---

## Diagrammes d'Architecture

### Architecture de Déploiement

```
Système de Fichiers
│
├── ~/ubuntu-configs/
│   │
│   ├── profiles/                    ← Répertoire des profils
│   │   ├── machine_detector.sh      ← Module de détection
│   │   ├── profile_loader.sh        ← Orchestrateur principal
│   │   │
│   │   ├── TuF/                     ← Profil Desktop
│   │   │   ├── config.sh            ← Configuration TuF
│   │   │   └── scripts/
│   │   │       └── fix_pipewire_bt.sh
│   │   │
│   │   ├── PcDeV/                   ← Profil Ultraportable
│   │   │   └── config.sh            ← Configuration PcDeV
│   │   │
│   │   └── default/                 ← Profil Universel
│   │       └── config.sh            ← Configuration default
│   │
│   └── mon_shell/                   ← Modules réutilisables
│       ├── colors.sh
│       ├── aliases.sh
│       ├── chargeur_modules.sh
│       ├── utilitaires_systeme.sh
│       ├── outils_fichiers.sh
│       ├── outils_productivite.sh
│       ├── outils_developpeur.sh
│       ├── outils_reseau.sh
│       ├── outils_multimedia.sh
│       ├── aide_memoire.sh
│       ├── raccourcis_pratiques.sh
│       └── nettoyage_securise.sh
│
├── ~/.config/ubuntu-configs/        ← Configuration utilisateur
│   └── machine_profile              ← Profil manuel (optionnel)
│
└── ~/.bashrc / ~/.zshrc             ← Points d'entrée
    └── source ~/ubuntu-configs/profiles/profile_loader.sh
```

---

### Architecture de Communication

```
┌─────────────────────────────────────────────────────────┐
│                     Utilisateur                         │
│              (Interaction Shell)                        │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌───────────┐ ┌──────────┐ ┌─────────────┐
│Commandes  │ │ Alias    │ │ Fonctions   │
│utilisateur│ │ profil   │ │ profil      │
└─────┬─────┘ └────┬─────┘ └──────┬──────┘
      │            │              │
      └────────────┼──────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │  Profile Loader │
         │  Orchestrateur  │
         └────────┬────────┘
                  │
      ┌───────────┼───────────┬──────────┐
      │           │           │          │
      ▼           ▼           ▼          ▼
┌──────────┐ ┌────────┐ ┌────────┐ ┌─────────┐
│Détecteur │ │Profil  │ │Modules │ │Adaptatif│
│Machine   │ │Config  │ │Shell   │ │(opt)    │
└────┬─────┘ └───┬────┘ └───┬────┘ └────┬────┘
     │           │          │           │
     └───────────┼──────────┼───────────┘
                 │          │
                 ▼          ▼
         ┌────────────────────┐
         │   Système Linux    │
         │ • /sys/            │
         │ • /proc/           │
         │ • Commandes        │
         └────────────────────┘
```

---

## Sécurité Architecturale

### Modèle de Menaces

**Menaces Identifiées:**
1. **Injection de code** via profils malveillants
2. **Traversée de chemin** pour accéder à fichiers non autorisés
3. **Hijacking de fonctions** via export -f
4. **Escalade de privilèges** via scripts malicieux
5. **Déni de service** via boucles infinies ou consommation ressources

---

### Contrôles de Sécurité par Couche

#### Couche Détection

**Menace:** Injection de nom de profil malveillant

**Contrôles:**
1. **Whitelist stricte:** Seuls `TuF`, `PcDeV`, `default` autorisés
2. **Validation regex:** `^[a-zA-Z0-9_]+$`
3. **Messages d'erreur:** Avertissement si profil invalide
4. **Fallback sécurisé:** Retour au profil default

```bash
# Validation multi-niveaux
local valid_profiles=("TuF" "PcDeV" "default")
for valid_profile in "${valid_profiles[@]}"; do
    if [[ "$machine_name" == "$valid_profile" ]]; then
        is_valid=true
        break
    fi
done
```

---

#### Couche Chargement

**Menace:** Traversée de chemin pour charger fichiers arbitraires

**Contrôles:**
1. **Validation nom profil:** Regex alphanumeric
2. **Resolution realpath:** Détection de symlinks et ..
3. **Vérification containment:** Profil doit être dans PROFILES_DIR
4. **Fallback:** Retour à default si chemin invalide

```bash
# Protection traversée
local profile_realpath=$(realpath -m "$profile_config")
local profiles_realpath=$(realpath "$PROFILES_DIR")

if [[ ! "$profile_realpath" == "$profiles_realpath"/* ]]; then
    echo "⚠️  Tentative de traversée de chemin détectée" >&2
    profile="default"
fi
```

---

#### Couche Modules

**Menace:** Chargement de modules non autorisés

**Contrôles:**
1. **Whitelist modules:** Associative array de modules autorisés
2. **Validation format:** Regex `^[a-zA-Z0-9_.-]+\.sh$`
3. **Protection traversée:** Vérification realpath dans mon_shell/
4. **Ignorer modules invalides:** Pas de chargement si non validé

```bash
# Whitelist stricte
declare -A VALID_MODULES=(
    ["utilitaires_systeme.sh"]=1
    ["outils_fichiers.sh"]=1
    # ... autres modules autorisés
)

# Validation
if [[ ! "${VALID_MODULES[$module]}" ]]; then
    echo "⚠️  Module non autorisé ignoré: $module" >&2
    continue
fi
```

---

#### Couche Exécution

**Menace:** Hijacking de fonctions

**Contrôle:**
1. **Pas d'export -f:** Fonctions non exportées vers sous-shells
2. **Définition locale:** Fonctions disponibles uniquement dans shell courant
3. **Documentation:** Note explicite dans chaque fichier

```bash
# Note de sécurité dans tous les fichiers
# Note: Les fonctions sont disponibles sans export dans les fichiers sourcés
# Export -f retiré pour des raisons de sécurité (risque d'hijacking)
```

---

### Principe de Moindre Privilège

**Fichiers de Configuration:**
- Permissions: `700` (répertoire), `600` (fichiers)
- Umask: `077` lors de création
- Écriture atomique: Évite race conditions

**Exécution:**
- Pas de `sudo` dans les scripts de profils
- Validation avant toute opération système
- Isolation des fonctions critiques

---

## Points d'Extension

### 1. Ajout d'un Nouveau Profil

**Emplacement:** `~/ubuntu-configs/profiles/NouveauProfil/`

**Étapes:**
1. Créer répertoire profil
2. Créer `config.sh` avec structure standard
3. Définir `MODULES_NOUVEAUPROFIL`
4. Ajouter à whitelist dans `machine_detector.sh` et `profile_loader.sh`
5. Implémenter logique de détection (optionnel)

**Interface à respecter:**
```bash
# Variables obligatoires
export PROFILE_NAME="NouveauProfil"
export PROFILE_TYPE="type_machine"
export PROFILE_MODE="MINIMAL|STANDARD|PERFORMANCE"

# Modules à charger
MODULES_NOUVEAUPROFIL=(
    "module1.sh:Description"
    "module2.sh:Description"
)

# Fonctions et alias personnalisés
# ...
```

---

### 2. Ajout d'un Nouveau Module

**Emplacement:** `~/ubuntu-configs/mon_shell/nouveau_module.sh`

**Étapes:**
1. Créer fichier module avec fonctions
2. Ajouter à whitelist dans `profile_loader.sh`
3. Référencer dans `MODULES_*` des profils concernés
4. Documenter dans aide_memoire.sh

**Interface à respecter:**
```bash
#!/bin/bash
# Description du module
# Usage: Chargé automatiquement par profile_loader

# Fonctions publiques (pas d'export -f)
function_publique() {
    # Code
}

# Variables locales au module
local_var="valeur"
```

---

### 3. Ajout de Critères de Détection

**Emplacement:** `machine_detector.sh` fonction `detecter_machine()`

**Étapes:**
1. Ajouter nouvelle priorité dans la cascade if/elif
2. Implémenter logique de détection
3. Retourner nom du profil si match
4. Tester avec différentes configurations

**Exemple:**
```bash
# Nouvelle priorité: Détection par UUID matériel
if [[ -f /sys/class/dmi/id/product_uuid ]]; then
    local uuid=$(cat /sys/class/dmi/id/product_uuid)
    case "$uuid" in
        XXXX-YYYY-ZZZZ)
            echo "MonProfil"
            return 0
            ;;
    esac
fi
```

---

### 4. Extension du Système Adaptatif

**Intégration:** Variable `FORCE_ADAPTIVE_MODE` dans config.sh

**Modes disponibles:**
- `MINIMAL`: Ressources limitées (< 4GB RAM)
- `STANDARD`: Ressources moyennes (4-8GB RAM)
- `PERFORMANCE`: Ressources élevées (> 8GB RAM)

**Extension:**
```bash
# Dans config.sh
export FORCE_ADAPTIVE_MODE="CUSTOM"

# Définir comportement custom dans adaptive_detection.sh
if [[ "$FORCE_ADAPTIVE_MODE" == "CUSTOM" ]]; then
    # Logique personnalisée
fi
```

---

## Intégration avec le Système Adaptatif

### Architecture d'Intégration

```
┌──────────────────────────────────────────────────────────┐
│              Système de Profils                          │
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │ Profil TuF                                 │         │
│  │ FORCE_ADAPTIVE_MODE="PERFORMANCE"          │         │
│  └───────────────────┬────────────────────────┘         │
│                      │                                   │
│  ┌───────────────────▼────────────────────────┐         │
│  │ Profil PcDeV                               │         │
│  │ FORCE_ADAPTIVE_MODE="MINIMAL"              │         │
│  └───────────────────┬────────────────────────┘         │
│                      │                                   │
│  ┌───────────────────▼────────────────────────┐         │
│  │ Profil default                             │         │
│  │ Pas de FORCE_ADAPTIVE_MODE                 │         │
│  │ → Détection automatique                    │         │
│  └───────────────────┬────────────────────────┘         │
└──────────────────────┼──────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│         Système Adaptatif (adaptive_detection.sh)        │
│                                                          │
│  if [[ -n "$FORCE_ADAPTIVE_MODE" ]]; then               │
│      MODE=$FORCE_ADAPTIVE_MODE                          │
│  else                                                    │
│      MODE=$(detect_resources)                           │
│  fi                                                      │
│                                                          │
│  ┌─────────────┬─────────────┬─────────────┐           │
│  │ MINIMAL     │ STANDARD    │ PERFORMANCE │           │
│  │ RAM < 4GB   │ 4GB ≤ RAM   │ RAM > 8GB   │           │
│  │ Modules: 3  │ Modules: 6  │ Modules: 9  │           │
│  └─────────────┴─────────────┴─────────────┘           │
└──────────────────────────────────────────────────────────┘
```

### Variables Partagées

```bash
# Profil → Adaptatif
FORCE_ADAPTIVE_MODE      # Surcharge détection auto
PROFILE_MODE             # Mode recommandé du profil

# Adaptatif → Profil
ADAPTIVE_MODE            # Mode détecté/forcé
ADAPTIVE_RAM_GB          # RAM disponible
ADAPTIVE_CPU_CORES       # Cœurs CPU
```

### Flux d'Intégration

1. **Chargement profil:** Définit `FORCE_ADAPTIVE_MODE` (optionnel)
2. **Chargement adaptatif:** Vérifie `FORCE_ADAPTIVE_MODE`
3. **Décision mode:**
   - Si `FORCE_ADAPTIVE_MODE` défini → Utilise cette valeur
   - Sinon → Détection automatique basée sur matériel
4. **Application:** Charge modules selon mode final

---

## Patterns de Conception

### 1. Strategy Pattern (Détection de Machine)

**Objectif:** Permettre différentes stratégies de détection

**Implémentation:**
```bash
detecter_machine() {
    # Stratégie 1: Configuration manuelle
    strategy_manual && return 0

    # Stratégie 2: Hostname
    strategy_hostname && return 0

    # Stratégie 3: Matériel
    strategy_hardware && return 0

    # Stratégie 4: Scripts
    strategy_scripts && return 0

    # Stratégie 5: Default
    echo "default"
}
```

---

### 2. Template Method Pattern (Profils)

**Objectif:** Structure commune avec personnalisations

**Template (structure config.sh):**
```bash
# 1. Variables (obligatoire)
export PROFILE_NAME="..."
export PROFILE_TYPE="..."
export PROFILE_MODE="..."

# 2. Configuration système (personnalisable)
# ...

# 3. Modules (personnalisable)
MODULES_X=(...)

# 4. Fonctions (personnalisable)
# ...

# 5. Alias (personnalisable)
# ...

# 6. Messages (personnalisable)
echo "..."
```

---

### 3. Chain of Responsibility (Validation Sécurité)

**Objectif:** Chaîne de validations indépendantes

**Implémentation:**
```bash
load_machine_profile() {
    # Handler 1: Validation nom
    validate_profile_name || return 1

    # Handler 2: Protection traversée
    validate_path_containment || return 1

    # Handler 3: Vérification existence
    validate_file_exists || return 1

    # Handler 4: Chargement sécurisé
    safe_source_profile || return 1
}
```

---

### 4. Facade Pattern (load_complete_environment)

**Objectif:** Interface simple pour système complexe

**Implémentation:**
```bash
# Interface simple
load_complete_environment()

# Masque complexité
load_complete_environment() {
    load_colors
    load_machine_profile
    load_profile_modules
    load_aliases
    # ... orchestration complexe
}
```

---

### 5. Observer Pattern (Messages et Logs)

**Objectif:** Notification des événements système

**Implémentation:**
```bash
# Événement: Profil chargé
echo "🖥️  Profil $PROFILE_NAME chargé" | tee -a "$LOG_FILE"

# Événement: Module chargé
echo "✅ Module $module chargé" >&2

# Événement: Erreur
echo "❌ Erreur: $message" >&2 | logger -t "ubuntu-configs"
```

---

## Évolutions Futures

### Roadmap Architecture

**Version 1.1:**
- Support profils utilisateur personnalisés en dehors du dépôt
- Cache de détection pour améliorer performance
- Hooks pré/post chargement profil

**Version 1.2:**
- Support multi-profils (combinaison de profils)
- Profiles héritables (base + spécialisations)
- Configuration YAML/TOML alternative

**Version 2.0:**
- API REST pour gestion profils
- Interface graphique de configuration
- Synchronisation profils multi-machines

---

## Références

- **API Reference:** [API_PROFILS.md](API_PROFILS.md)
- **Guide Sécurité:** [SECURITE_PROFILS.md](SECURITE_PROFILS.md)
- **Guide Développeur:** [DEVELOPPEUR_PROFILS.md](DEVELOPPEUR_PROFILS.md)
- **Exemples:** [EXEMPLES_PROFILS.md](EXEMPLES_PROFILS.md)
- **Migration:** [MIGRATION_PROFILS.md](MIGRATION_PROFILS.md)
- **Documentation Principale:** [README_PROFILS.md](../README_PROFILS.md)

---

**Version:** 1.0
**Dernière mise à jour:** Octobre 2025
**Mainteneur:** ubuntu-configs team
