# Guide Développeur - Système de Profils

Guide pratique pour contribuer au système de profils multi-machines.

## Table des Matières

- [Configuration Développement](#configuration-développement)
- [Créer un Nouveau Profil](#créer-un-nouveau-profil)
- [Créer un Nouveau Module](#créer-un-nouveau-module)
- [Ajouter des Critères de Détection](#ajouter-des-critères-de-détection)
- [Guidelines de Code](#guidelines-de-code)
- [Tests et Validation](#tests-et-validation)
- [Workflow de Contribution](#workflow-de-contribution)

---

## Configuration Développement

### Prérequis

```bash
# Outils nécessaires
sudo apt install git shellcheck bash-completion

# Clone du projet
git clone https://github.com/user/ubuntu-configs.git
cd ubuntu-configs

# Configuration git
git config user.name "Votre Nom"
git config user.email "votre@email.com"
```

### Structure de Développement

```bash
ubuntu-configs/
├── profiles/                  # Système de profils
│   ├── machine_detector.sh    # À modifier pour détection
│   ├── profile_loader.sh      # Core (rarement modifié)
│   ├── TuF/                   # Profil exemple
│   ├── PcDeV/                 # Profil exemple
│   └── default/               # Profil exemple
├── mon_shell/                 # Modules
│   ├── utilitaires_systeme.sh
│   └── ...
├── tests/                     # Tests
│   └── profile_system_tests.sh
└── claudedocs/                # Documentation
    ├── API_PROFILS.md
    ├── ARCHITECTURE_PROFILS.md
    └── ...
```

---

## Créer un Nouveau Profil

### Étape 1: Structure de Base

```bash
# Créer le répertoire
mkdir -p ~/ubuntu-configs/profiles/MonProfil/{scripts,config}

# Créer config.sh
cat > ~/ubuntu-configs/profiles/MonProfil/config.sh << 'EOF'
#!/bin/bash
# ==============================================================================
# Profil : MonProfil
# Description : Description courte du profil
# Mode Adaptatif : MINIMAL|STANDARD|PERFORMANCE
# ==============================================================================

# Informations du profil
export PROFILE_NAME="MonProfil"
export PROFILE_TYPE="desktop|laptop|server|universal"
export PROFILE_MODE="MINIMAL|STANDARD|PERFORMANCE"

# Couleurs pour les messages
source ~/ubuntu-configs/mon_shell/colors.sh 2>/dev/null || {
    VERT='\033[0;32m'
    BLEU='\033[0;34m'
    NC='\033[0m'
}

echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${VERT}📦 Profil MonProfil - Mode XXX${NC}"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Configuration Système Adaptative
export FORCE_ADAPTIVE_MODE="PERFORMANCE"  # Optionnel

# Modules à Charger
MODULES_MONPROFIL=(
    "utilitaires_systeme.sh:Utilitaires système"
    "outils_fichiers.sh:Gestion de fichiers"
    "aide_memoire.sh:Aide rapide"
)

# Configuration Système
export HISTSIZE=5000
export HISTFILESIZE=10000
export EDITOR="nano"

# Alias Spécifiques
alias mon-alias="commande"

# Fonctions Spécifiques
ma-fonction() {
    echo "Fonction du profil MonProfil"
}

# Messages de Bienvenue
echo "   📦 Mode: XXX"
echo "   📊 Commandes spéciales:"
echo "      • ma-fonction : Description"
echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
EOF

chmod 755 ~/ubuntu-configs/profiles/MonProfil/config.sh
```

### Étape 2: Ajouter à la Whitelist

**Fichier:** `machine_detector.sh`

```bash
# Dans detecter_machine()
local valid_profiles=("TuF" "PcDeV" "default" "MonProfil")

# Dans definir_profil_manuel()
local valid_profiles=("TuF" "PcDeV" "default" "MonProfil")
```

**Fichier:** `profile_loader.sh`

```bash
# Dans load_profile_modules()
case "$PROFILE_NAME" in
    TuF)
        # ...
        ;;
    PcDeV)
        # ...
        ;;
    MonProfil)
        if [[ -n "${MODULES_MONPROFIL[@]}" ]]; then
            modules_to_load=("${MODULES_MONPROFIL[@]}")
        fi
        ;;
    default)
        # ...
        ;;
esac
```

### Étape 3: Implémenter Détection (Optionnel)

```bash
# Dans machine_detector.sh, fonction detecter_machine()

# Ajouter critère de détection spécifique
# Exemple: Par fichier marqueur
if [[ -f "$HOME/.monprofil_marker" ]]; then
    echo "MonProfil"
    return 0
fi

# Exemple: Par caractéristique matérielle
if lspci | grep -q "Specific Hardware"; then
    echo "MonProfil"
    return 0
fi
```

### Étape 4: Tester

```bash
# Test manuel
switch-profile MonProfil
source ~/.bashrc

# Vérifier profil chargé
show-profile

# Tester fonctions
ma-fonction

# Vérifier modules
aide
```

---

## Créer un Nouveau Module

### Structure Template

```bash
#!/bin/bash
# ==============================================================================
# Module : mon_nouveau_module.sh
# Catégorie : Outils système / Développement / Productivité / etc.
# Description : Description du module
# Usage : Chargé automatiquement par profile_loader selon profil
# ==============================================================================

# Protection contre double chargement
if [[ -n "$MON_MODULE_LOADED" ]]; then
    return 0
fi
export MON_MODULE_LOADED=1

# ==========================================
# Configuration
# ==========================================

# Variables de configuration du module
MODULE_CONFIG_VAR="valeur"

# ==========================================
# Fonctions Publiques
# ==========================================

# Fonction principale du module
ma_fonction_publique() {
    local param="$1"

    # Validation paramètre
    if [[ -z "$param" ]]; then
        echo "Usage: ma_fonction_publique <param>" >&2
        return 1
    fi

    # Logique de la fonction
    echo "Traitement de: $param"

    return 0
}

# Autre fonction publique
autre_fonction() {
    # Code
    return 0
}

# ==========================================
# Fonctions Privées (Convention: Préfixe _)
# ==========================================

_fonction_privee() {
    # Fonction helper interne
    return 0
}

# ==========================================
# Alias du Module
# ==========================================

alias mon-cmd='ma_fonction_publique'

# Note: Pas d'export -f pour raisons de sécurité
# Les fonctions sont disponibles dans le shell courant uniquement
```

### Ajouter à la Whitelist

**Fichier:** `profile_loader.sh`

```bash
# Whitelist des modules autorisés
declare -A VALID_MODULES=(
    ["utilitaires_systeme.sh"]=1
    ["outils_fichiers.sh"]=1
    # ... autres modules
    ["mon_nouveau_module.sh"]=1  # Ajouter ici
)
```

### Intégrer dans Profils

```bash
# Dans profiles/TuF/config.sh (exemple)
MODULES_TUF=(
    "utilitaires_systeme.sh:Utilitaires système complets"
    # ... autres modules
    "mon_nouveau_module.sh:Description de mon module"
)
```

### Documentation

```bash
# Ajouter dans aide_memoire.sh
echo "📦 Mon Nouveau Module"
echo "  • ma_fonction_publique : Description"
echo "  • autre_fonction       : Description"
```

---

## Ajouter des Critères de Détection

### Types de Critères

#### 1. Détection par Fichier Marqueur

```bash
# Dans detecter_machine()
# Après hostname, avant matériel

# Méthode 3.5: Fichier marqueur spécifique
if [[ -f "$HOME/.profile_marker" ]]; then
    local marker=$(cat "$HOME/.profile_marker" 2>/dev/null | tr -d '[:space:]')
    case "$marker" in
        MonProfil)
            echo "MonProfil"
            return 0
            ;;
    esac
fi
```

#### 2. Détection par Matériel Spécifique

```bash
# Détection par GPU
if lspci | grep -qi "NVIDIA GeForce RTX"; then
    echo "Gaming"
    return 0
fi

# Détection par CPU
if lscpu | grep -q "Model name.*Ryzen"; then
    echo "AMD"
    return 0
fi

# Détection par carte réseau
if lspci | grep -q "Intel.*Wi-Fi 6"; then
    echo "ModernLaptop"
    return 0
fi
```

#### 3. Détection par Variable d'Environnement

```bash
# Variable personnalisée
if [[ -n "$MY_PROFILE" ]]; then
    case "$MY_PROFILE" in
        MonProfil)
            echo "MonProfil"
            return 0
            ;;
    esac
fi
```

#### 4. Détection par Caractéristiques Combinées

```bash
# Portable gaming (batterie + GPU puissant)
if [[ -d /sys/class/power_supply/BAT* ]]; then
    if lspci | grep -qi "NVIDIA GeForce RTX"; then
        local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
        if [[ $ram_gb -ge 16 ]]; then
            echo "GamingLaptop"
            return 0
        fi
    fi
fi
```

### Priorité de Détection

**Ordre recommandé:**
1. Configuration manuelle (toujours priorité 1)
2. Variables d'environnement
3. Fichiers marqueurs
4. Hostname
5. Matériel spécifique
6. Matériel générique
7. Scripts spécifiques
8. Fallback default

---

## Guidelines de Code

### Style Shell

```bash
# ✅ Bon
if [[ -f "$file" ]]; then
    source "$file"
fi

# ❌ Mauvais
if [ -f $file ]; then
  . $file
fi

# ✅ Bon - Double crochets
[[ "$var" == "value" ]]

# ❌ Mauvais - Simple crochets
[ "$var" = "value" ]

# ✅ Bon - Quotes pour variables
echo "$variable"
rm "$file_name"

# ❌ Mauvais - Pas de quotes
echo $variable
rm $file_name
```

### Conventions de Nommage

```bash
# Variables globales exportées
export PROFILE_NAME="TuF"
export MODULE_CONFIG="value"

# Variables locales
local file_path="/path/to/file"
local counter=0

# Fonctions publiques
function_publique() { ... }

# Fonctions privées (convention)
_fonction_privee() { ... }

# Constantes (convention)
readonly CONSTANT_VALUE="value"
```

### Gestion des Erreurs

```bash
# ✅ Bon - Vérification code retour
if command; then
    echo "Succès"
else
    echo "Erreur" >&2
    return 1
fi

# ✅ Bon - Validation paramètres
ma_fonction() {
    local param="$1"

    if [[ -z "$param" ]]; then
        echo "Erreur: Paramètre manquant" >&2
        echo "Usage: ma_fonction <param>" >&2
        return 1
    fi

    # Logique
}

# ✅ Bon - Protection contre erreurs
if [[ -f "$file" ]]; then
    source "$file"
else
    echo "Fichier introuvable: $file" >&2
    return 1
fi
```

### Sécurité

```bash
# ✅ Bon - Validation entrée
if [[ ! "$profile" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "Nom invalide" >&2
    return 1
fi

# ✅ Bon - Protection traversée
local realpath=$(realpath -m "$path")
if [[ "$realpath" != "$allowed_dir"/* ]]; then
    echo "Chemin non autorisé" >&2
    return 1
fi

# ✅ Bon - Permissions sécurisées
(umask 077 && echo "data" > "$file")

# ❌ Mauvais - Export fonctions
export -f ma_fonction  # Risque hijacking

# ❌ Mauvais - Pas de validation
source "$user_input"  # Injection possible
```

### Documentation

```bash
# ✅ Bon - En-tête fichier
#!/bin/bash
# ==============================================================================
# Fichier : mon_script.sh
# Description : Description claire et concise
# Usage : Comment utiliser le fichier
# Auteur : Nom (optionnel)
# Date : YYYY-MM-DD (optionnel)
# ==============================================================================

# ✅ Bon - Commentaire fonction
# Description de la fonction
# Arguments:
#   $1 - Premier paramètre
#   $2 - Second paramètre
# Retour:
#   0 - Succès
#   1 - Erreur
ma_fonction() {
    # ...
}

# ✅ Bon - Sections logiques
# ==========================================
# Configuration
# ==========================================
```

---

## Tests et Validation

### Tests Manuels

```bash
# 1. Test chargement profil
switch-profile MonProfil
source ~/.bashrc
show-profile

# 2. Test fonctions
ma_fonction_test

# 3. Test alias
mon-alias

# 4. Test modules
aide | grep "Mon Module"

# 5. Test détection
# Modifier critère et vérifier
detecter_machine
```

### Tests Automatisés

```bash
#!/bin/bash
# test_mon_profil.sh

# Setup
source ~/ubuntu-configs/profiles/machine_detector.sh
source ~/ubuntu-configs/profiles/profile_loader.sh

# Test 1: Détection profil
test_detection() {
    local result=$(detecter_machine)
    if [[ "$result" != "MonProfil" ]] && [[ "$result" != "default" ]]; then
        echo "FAIL: Détection invalide"
        return 1
    fi
    echo "PASS: Détection OK"
}

# Test 2: Chargement profil
test_loading() {
    if load_machine_profile; then
        echo "PASS: Chargement OK"
    else
        echo "FAIL: Erreur chargement"
        return 1
    fi
}

# Test 3: Variables exportées
test_variables() {
    if [[ -z "$PROFILE_NAME" ]]; then
        echo "FAIL: PROFILE_NAME non défini"
        return 1
    fi
    echo "PASS: Variables OK"
}

# Exécution tests
test_detection
test_loading
test_variables
```

### Validation Qualité

```bash
# Vérification syntaxe
bash -n ~/ubuntu-configs/profiles/MonProfil/config.sh

# Analyse statique
shellcheck ~/ubuntu-configs/profiles/MonProfil/config.sh

# Vérification permissions
stat -c "%a %n" ~/ubuntu-configs/profiles/MonProfil/config.sh

# Recherche problèmes courants
grep -r "export -f" ~/ubuntu-configs/profiles/MonProfil/
grep -r "sudo" ~/ubuntu-configs/profiles/MonProfil/config.sh
```

---

## Workflow de Contribution

### 1. Créer une Branche

```bash
git checkout -b feature/mon-profil
```

### 2. Développement

```bash
# Créer/modifier fichiers
# Tester localement
# Valider qualité
```

### 3. Commit

```bash
git add profiles/MonProfil/
git commit -m "feat(profiles): Add MonProfil for server environment

- Add profile configuration with STANDARD mode
- Implement hardware detection for server
- Add server-specific functions
- Update whitelist in detector and loader
"
```

**Format Commit:**
- `feat(scope): Description` - Nouvelle fonctionnalité
- `fix(scope): Description` - Correction bug
- `docs(scope): Description` - Documentation
- `test(scope): Description` - Tests
- `refactor(scope): Description` - Refactoring

### 4. Tests Complets

```bash
# Tests unitaires
bash tests/profile_system_tests.sh

# Tests manuels
switch-profile MonProfil
source ~/.bashrc
show-profile
```

### 5. Pull Request

```bash
git push origin feature/mon-profil
# Créer PR sur GitHub/GitLab
```

**Template PR:**
```markdown
## Description
Description claire des modifications

## Type de Changement
- [ ] Nouveau profil
- [ ] Nouveau module
- [ ] Correction bug
- [ ] Documentation
- [ ] Autre

## Tests Effectués
- [ ] Tests manuels
- [ ] Tests automatisés
- [ ] Validation sécurité
- [ ] Review code

## Checklist
- [ ] Code suit les guidelines
- [ ] Documentation à jour
- [ ] Tests passent
- [ ] Pas de régression
```

---

## Dépannage Développement

### Profil ne se Charge Pas

```bash
# Debug mode
bash -x ~/ubuntu-configs/profiles/profile_loader.sh 2>&1 | less

# Vérifier erreurs
journalctl -t ubuntu-configs --since "5 minutes ago"

# Vérifier syntaxe
bash -n ~/ubuntu-configs/profiles/MonProfil/config.sh
```

### Module ne se Charge Pas

```bash
# Vérifier whitelist
grep "mon_module" ~/ubuntu-configs/profiles/profile_loader.sh

# Vérifier référence dans profil
grep "mon_module" ~/ubuntu-configs/profiles/*/config.sh

# Test chargement direct
source ~/ubuntu-configs/mon_shell/mon_module.sh
```

### Détection Incorrecte

```bash
# Test détection seule
source ~/ubuntu-configs/profiles/machine_detector.sh
detecter_machine
afficher_info_machine "$(detecter_machine)"

# Debug logique
bash -x ~/ubuntu-configs/profiles/machine_detector.sh
```

---

## Ressources

- **API Reference:** [API_PROFILS.md](API_PROFILS.md)
- **Architecture:** [ARCHITECTURE_PROFILS.md](ARCHITECTURE_PROFILS.md)
- **Sécurité:** [SECURITE_PROFILS.md](SECURITE_PROFILS.md)
- **Exemples:** [EXEMPLES_PROFILS.md](EXEMPLES_PROFILS.md)
- **ShellCheck:** https://www.shellcheck.net/
- **Google Shell Style Guide:** https://google.github.io/styleguide/shellguide.html

---

**Version:** 1.0
**Dernière mise à jour:** Octobre 2025
