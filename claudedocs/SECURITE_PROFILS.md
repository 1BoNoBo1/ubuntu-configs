# Sécurité du Système de Profils Multi-Machines

Documentation complète des aspects sécurité, modèle de menaces, contrôles et bonnes pratiques.

## Table des Matières

- [Vue d'Ensemble Sécurité](#vue-densemble-sécurité)
- [Modèle de Menaces](#modèle-de-menaces)
- [Contrôles de Sécurité](#contrôles-de-sécurité)
- [Validation des Entrées](#validation-des-entrées)
- [Protection des Chemins](#protection-des-chemins)
- [Isolation et Sandboxing](#isolation-et-sandboxing)
- [Gestion des Permissions](#gestion-des-permissions)
- [Audit et Logging](#audit-et-logging)
- [Tests de Sécurité](#tests-de-sécurité)
- [Réponse aux Incidents](#réponse-aux-incidents)

---

## Vue d'Ensemble Sécurité

### Principes de Sécurité

Le système de profils est conçu selon les principes suivants:

1. **Défense en Profondeur**: Multiples couches de sécurité indépendantes
2. **Moindre Privilège**: Permissions minimales nécessaires
3. **Fail-Safe**: Retour automatique à un état sûr en cas d'erreur
4. **Validation Systématique**: Toutes les entrées sont validées
5. **Isolation**: Séparation stricte entre composants

### Surface d'Attaque

**Points d'Entrée Potentiels:**
1. Fichier de configuration manuel (`~/.config/ubuntu-configs/machine_profile`)
2. Hostname système (détection automatique)
3. Noms de profils (paramètres utilisateur)
4. Noms de modules (listes dans config.sh)
5. Fichiers de configuration de profils

**Actifs à Protéger:**
1. Exécution de code arbitraire
2. Accès fichiers système sensibles
3. Escalade de privilèges
4. Intégrité de l'environnement shell

---

## Modèle de Menaces

### Threat Modeling (STRIDE)

#### Spoofing (Usurpation d'Identité)

**Menace:** Attaquant usurpe un profil légitime

**Scénario:**
```bash
# Attaquant crée un faux profil
echo "../../etc/passwd" > ~/.config/ubuntu-configs/machine_profile
```

**Impact:** Chargement de fichiers système sensibles comme profil

**Mitigation:**
- Whitelist stricte des profils autorisés
- Validation regex du nom de profil
- Vérification realpath pour détecter symlinks et traversée

---

#### Tampering (Altération)

**Menace:** Modification malveillante des fichiers de profils

**Scénario:**
```bash
# Attaquant modifie config.sh pour injecter code
echo "rm -rf /" >> ~/ubuntu-configs/profiles/TuF/config.sh
```

**Impact:** Exécution de code malveillant au chargement du profil

**Mitigation:**
- Permissions strictes (700/600)
- Vérification d'intégrité (checksums)
- Audit des modifications
- Contrôle de version (git)

---

#### Repudiation (Non-Répudiation)

**Menace:** Impossibilité de tracer qui a fait quoi

**Scénario:**
- Modifications de profils sans traçabilité
- Changements de configuration anonymes

**Impact:** Difficulté d'investigation post-incident

**Mitigation:**
- Logs des chargements et changements
- Intégration avec syslog/journald
- Historique git des modifications

---

#### Information Disclosure (Divulgation d'Information)

**Menace:** Exposition d'informations sensibles

**Scénario:**
```bash
# Messages d'erreur verbeux révèlent structure système
⚠️  Configuration du profil introuvable: /home/user/ubuntu-configs/profiles/../../../etc/shadow/config.sh
```

**Impact:** Reconnaissance de la structure du système

**Mitigation:**
- Messages d'erreur génériques
- Logs détaillés uniquement en mode debug
- Pas d'exposition de chemins complets dans erreurs

---

#### Denial of Service (Déni de Service)

**Menace:** Consommation excessive de ressources

**Scénario:**
```bash
# Boucle infinie dans config.sh
while true; do
    load_profile_modules
done
```

**Impact:** Shell inutilisable, système ralenti

**Mitigation:**
- Timeouts sur opérations longues
- Détection de boucles infinies
- Limite de profondeur de récursion
- Resource limits (ulimit)

---

#### Elevation of Privilege (Escalade de Privilèges)

**Menace:** Obtention de privilèges non autorisés

**Scénario:**
```bash
# Fonction malveillante exportée
export -f malicious_sudo() { sudo "$@"; }
alias sudo='malicious_sudo'
```

**Impact:** Exécution de commandes privilégiées à l'insu de l'utilisateur

**Mitigation:**
- Pas d'export -f de fonctions
- Pas de sudo dans les scripts de profils
- Validation de toutes les commandes système

---

## Contrôles de Sécurité

### Matrice de Contrôles par Composant

| Composant | Menace | Contrôle | Niveau |
|-----------|--------|----------|--------|
| machine_detector.sh | Injection profil | Whitelist + Regex | Critique |
| machine_detector.sh | Traversée chemin | N/A (pas de chemins) | - |
| profile_loader.sh | Injection profil | Whitelist + Regex + Realpath | Critique |
| profile_loader.sh | Traversée chemin | Realpath + Containment check | Critique |
| profile_loader.sh | Modules malveillants | Whitelist modules + Regex + Realpath | Critique |
| config.sh | Code malveillant | Review manuel + Git | Important |
| Fichier config manuel | Injection | Whitelist + Validation | Critique |

---

### Contrôles Techniques Détaillés

#### 1. Validation par Whitelist

**Objectif:** Autoriser uniquement valeurs connues et sûres

**Implémentation:**

```bash
# Whitelist profils
local valid_profiles=("TuF" "PcDeV" "default")

# Validation
local is_valid=false
for valid_profile in "${valid_profiles[@]}"; do
    if [[ "$machine_name" == "$valid_profile" ]]; then
        is_valid=true
        break
    fi
done

if [[ "$is_valid" != "true" ]]; then
    echo "❌ Profil invalide: $machine_name" >&2
    echo "   Profils valides: ${valid_profiles[*]}" >&2
    return 1
fi
```

**Avantages:**
- Protection contre injection de valeurs arbitraires
- Liste explicite et maintenable
- Échec sécurisé si valeur inconnue

---

#### 2. Validation par Expression Régulière

**Objectif:** Valider format des entrées

**Implémentation:**

```bash
# Validation nom de profil (alphanumeric + underscore uniquement)
if [[ ! "$profile" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "⚠️  Nom de profil invalide détecté, utilisation du profil default" >&2
    profile="default"
fi

# Validation nom de module
if [[ ! "$module" =~ ^[a-zA-Z0-9_.-]+\.sh$ ]]; then
    echo "⚠️  Nom de module invalide: $module" >&2
    continue
fi
```

**Patterns Autorisés:**
- Profils: `^[a-zA-Z0-9_]+$`
- Modules: `^[a-zA-Z0-9_.-]+\.sh$`

**Caractères Interdits:**
- `/` (séparateur de chemin)
- `\` (échappement)
- `..` (traversée parent)
- Espaces et caractères spéciaux

---

#### 3. Protection contre Traversée de Chemin

**Objectif:** Empêcher accès à fichiers hors répertoires autorisés

**Technique 1: Resolution Realpath**

```bash
# Résoudre le chemin réel (suit symlinks, résout ..)
local profile_realpath=$(realpath -m "$profile_config" 2>/dev/null)
local profiles_realpath=$(realpath "$PROFILES_DIR" 2>/dev/null)

# Vérifier que le chemin résolu est dans PROFILES_DIR
if [[ ! "$profile_realpath" == "$profiles_realpath"/* ]]; then
    echo "⚠️  Tentative de traversée de chemin détectée" >&2
    profile="default"
    profile_config="$PROFILES_DIR/default/config.sh"
fi
```

**Technique 2: Vérification Containment**

```bash
# Vérifier que module est bien dans mon_shell/
local module_realpath=$(realpath -m "$module_path" 2>/dev/null)
local shell_realpath=$(realpath "$HOME/ubuntu-configs/mon_shell" 2>/dev/null)

if [[ "$module_realpath" == "$shell_realpath"/* ]] && [[ -f "$module_path" ]]; then
    source "$module_path"
else
    echo "⚠️  Module introuvable ou chemin invalide: $module" >&2
fi
```

**Attaques Bloquées:**
```bash
# Tentatives d'attaque (toutes bloquées)
../../../etc/passwd
/etc/shadow
~/../../root/.ssh/id_rsa
symlink_to_sensitive_file
```

---

#### 4. Création Atomique de Fichiers

**Objectif:** Éviter race conditions lors de création de fichiers

**Implémentation:**

```bash
# Créer répertoire avec permissions restrictives
install -d -m 700 "$HOME/.config/ubuntu-configs"

# Écriture atomique avec umask sécurisé
(umask 077 && echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile")
```

**Protection Contre:**
- Race condition entre création et chmod
- Lecture par autre utilisateur pendant écriture
- Modification par processus concurrent

---

#### 5. Whitelist Modules

**Objectif:** Autoriser uniquement modules connus et sûrs

**Implémentation:**

```bash
# Whitelist des modules autorisés
declare -A VALID_MODULES=(
    ["utilitaires_systeme.sh"]=1
    ["outils_fichiers.sh"]=1
    ["outils_productivite.sh"]=1
    ["outils_developpeur.sh"]=1
    ["outils_reseau.sh"]=1
    ["outils_multimedia.sh"]=1
    ["aide_memoire.sh"]=1
    ["raccourcis_pratiques.sh"]=1
    ["nettoyage_securise.sh"]=1
    ["chargeur_modules.sh"]=1
)

# Validation
if [[ ! "${VALID_MODULES[$module]}" ]]; then
    echo "⚠️  Module non autorisé ignoré: $module" >&2
    continue
fi
```

**Maintenance:**
- Ajouter nouveau module → Mise à jour whitelist obligatoire
- Review de sécurité pour chaque nouveau module
- Documentation des modules autorisés

---

## Validation des Entrées

### Types d'Entrées

#### Entrée Utilisateur Directe

**Source:** Paramètres de commande (`switch-profile TuF`)

**Validation:**
```bash
switch-profile() {
    local new_profile="$1"

    # Validation présence paramètre
    if [[ -z "$new_profile" ]]; then
        echo "Usage: switch-profile [TuF|PcDeV|default]" >&2
        return 1
    fi

    # Validation via fonction sécurisée
    definir_profil_manuel "$new_profile"
}
```

---

#### Entrée Fichier de Configuration

**Source:** `~/.config/ubuntu-configs/machine_profile`

**Validation:**
```bash
# Lecture sécurisée
machine_name=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null | tr -d '[:space:]')

# Validation non-vide
if [[ -n "$machine_name" ]]; then
    # Validation whitelist
    local is_valid=false
    for valid_profile in "${valid_profiles[@]}"; do
        if [[ "$machine_name" == "$valid_profile" ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" == "true" ]]; then
        echo "$machine_name"
        return 0
    else
        echo "⚠️ Profil invalide dans le fichier de configuration: $machine_name" >&2
    fi
fi
```

**Sanitization:**
- `tr -d '[:space:]'`: Suppression espaces/newlines
- Validation whitelist stricte
- Rejet si invalide avec message d'erreur

---

#### Entrée Système (Hostname)

**Source:** Commande `hostname`

**Validation:**
```bash
local hostname=$(hostname)

# Pattern matching sécurisé
case "$hostname" in
    TuF|tuf|TUF)
        echo "TuF"
        return 0
        ;;
    PcDeV|pcdev|PCDEV|ultraportable)
        echo "PcDeV"
        return 0
        ;;
esac
```

**Notes:**
- Hostname contrôlé par root, donc fiable
- Mais validation quand même par sécurité défense en profondeur
- Case insensitive pour flexibilité

---

#### Entrée Tableau de Modules

**Source:** Variables `MODULES_TUF`, `MODULES_PCDEV`, etc.

**Validation:**
```bash
for module_info in "${modules_to_load[@]}"; do
    local module="${module_info%%:*}"

    # Validation 1: Whitelist
    if [[ ! "${VALID_MODULES[$module]}" ]]; then
        echo "⚠️  Module non autorisé ignoré: $module" >&2
        continue
    fi

    # Validation 2: Format
    if [[ ! "$module" =~ ^[a-zA-Z0-9_.-]+\.sh$ ]]; then
        echo "⚠️  Nom de module invalide: $module" >&2
        continue
    fi

    # Validation 3: Chemin
    local module_realpath=$(realpath -m "$module_path")
    local shell_realpath=$(realpath "$HOME/ubuntu-configs/mon_shell")

    if [[ "$module_realpath" != "$shell_realpath"/* ]]; then
        echo "⚠️  Module hors répertoire autorisé: $module" >&2
        continue
    fi

    # Chargement sécurisé
    source "$module_path"
done
```

---

## Protection des Chemins

### Techniques de Protection

#### 1. Basename pour Extraction

**Objectif:** Isoler le nom de fichier du chemin

```bash
local profile_name=$(basename "$profile_dir")
```

**Limite:** Ne protège pas contre traversée si utilisé seul

---

#### 2. Realpath pour Résolution

**Objectif:** Résoudre chemins canoniques (symlinks, .., .)

```bash
local profile_realpath=$(realpath -m "$profile_config" 2>/dev/null)
```

**Options:**
- `-m`: Permet chemins non existants (mode canonicalize-missing)
- `2>/dev/null`: Supprime erreurs si chemin invalide

**Avantages:**
- Détecte symlinks malveillants
- Résout `..` et `.`
- Retourne chemin absolu

---

#### 3. Vérification Containment

**Objectif:** Vérifier que chemin résolu est dans répertoire autorisé

```bash
if [[ ! "$profile_realpath" == "$profiles_realpath"/* ]]; then
    # Chemin hors répertoire autorisé
    echo "Erreur: Traversée de chemin" >&2
    return 1
fi
```

**Pattern Matching:**
- `"$parent"/*`: Tout sous-répertoire de parent
- Teste préfixe du chemin résolu

---

#### 4. Validation Existence et Type

**Objectif:** Vérifier que fichier existe et est régulier

```bash
if [[ ! -f "$profile_config" ]]; then
    echo "Fichier introuvable ou non régulier" >&2
    return 1
fi
```

**Tests:**
- `-f`: Fichier régulier (pas répertoire, symlink, device)
- `-d`: Répertoire
- `-e`: Existe (tout type)

---

### Scénarios d'Attaque et Défenses

#### Attaque 1: Traversée Classique

**Tentative:**
```bash
switch-profile "../../etc/passwd"
```

**Défense:**
1. Regex validation: `^[a-zA-Z0-9_]+$` → Échec (contient `/`)
2. Whitelist validation → Échec (pas dans liste)
3. **Résultat:** Profil rejeté, message d'erreur

---

#### Attaque 2: Symlink Malveillant

**Tentative:**
```bash
ln -s /etc/shadow ~/ubuntu-configs/profiles/malicious
```

**Défense:**
1. Nom validé: `malicious` passe regex
2. Realpath: Résout vers `/etc/shadow`
3. Containment: `/etc/shadow` != `~/ubuntu-configs/profiles/*` → Échec
4. **Résultat:** Traversée détectée, fallback default

---

#### Attaque 3: Null Byte Injection

**Tentative:**
```bash
switch-profile "TuF\x00../../etc/passwd"
```

**Défense:**
1. Bash traite `\x00` comme fin de string
2. Devient effectivement `"TuF"`
3. Validation whitelist: `TuF` → OK
4. **Résultat:** Pas d'injection, profil TuF légitime chargé

**Note:** Bash résistant naturellement aux null bytes

---

#### Attaque 4: Module Malveillant via Tableau

**Tentative:**
```bash
# Dans config.sh compromis
MODULES_TUF=(
    "utilitaires_systeme.sh:Description"
    "../../evil.sh:Malicious"
)
```

**Défense:**
1. Extraction nom: `../../evil.sh`
2. Whitelist validation → Échec (pas dans whitelist)
3. **Résultat:** Module ignoré, message d'avertissement

---

## Isolation et Sandboxing

### Isolation des Fonctions

**Problème:** `export -f` permet hijacking de fonctions

**Solution:** Pas d'export de fonctions

```bash
# ❌ Dangereux - Fonction exportée vers sous-shells
export -f ma_fonction

# ✅ Sûr - Fonction locale au shell courant
ma_fonction() {
    # Code
}
```

**Implications:**
- Fonctions disponibles uniquement dans shell actuel
- Sous-shells n'héritent pas des fonctions
- Protection contre hijacking via PATH ou autres

---

### Isolation des Profils

**Principe:** Chaque profil est autonome et isolé

**Implémentation:**
- Répertoires séparés par profil
- Pas de partage de fichiers entre profils
- Variables de profil scopées

```
profiles/
├── TuF/
│   └── config.sh          # Isolé
├── PcDeV/
│   └── config.sh          # Isolé
└── default/
    └── config.sh          # Isolé
```

---

### Sandbox Modules

**Principe:** Modules chargés ne peuvent affecter que l'environnement shell

**Limitations:**
- Pas d'accès root (pas de sudo dans modules)
- Pas de modification fichiers système
- Scope limité aux variables et fonctions shell

**Validation:**
- Code review de chaque module
- Tests de sécurité automatisés
- Audit régulier

---

## Gestion des Permissions

### Permissions Fichiers

#### Répertoire Configuration Utilisateur

```bash
$HOME/.config/ubuntu-configs/
Permissions: 700 (rwx------)
Propriétaire: utilisateur
Groupe: utilisateur
```

**Justification:**
- Lecture/écriture/exécution uniquement par utilisateur
- Aucun accès pour autres utilisateurs
- Protège fichier de configuration manuelle

---

#### Fichier Configuration Manuelle

```bash
$HOME/.config/ubuntu-configs/machine_profile
Permissions: 600 (rw-------)
Propriétaire: utilisateur
Groupe: utilisateur
```

**Création:**
```bash
(umask 077 && echo "$profile" > "$file")
```

**Justification:**
- Lecture/écriture uniquement par utilisateur
- Pas d'exécution nécessaire
- Protection contre lecture par autres utilisateurs

---

#### Fichiers de Profils

```bash
~/ubuntu-configs/profiles/*/config.sh
Permissions: 755 (rwxr-xr-x) ou 700 (rwx------)
Propriétaire: utilisateur
Recommandation: 700 pour sécurité maximale
```

**Justification:**
- Si 755: Lecture par tous (OK pour partage)
- Si 700: Lecture uniquement propriétaire (recommandé)
- Exécution nécessaire pour sourcing

---

### Umask et Création Sécurisée

**Umask par Défaut:**
```bash
umask 022  # Fichiers: 644, Répertoires: 755
```

**Umask Sécurisé:**
```bash
umask 077  # Fichiers: 600, Répertoires: 700
```

**Application:**
```bash
# Création avec umask restrictif
(umask 077 && echo "data" > "$file")

# Création répertoire avec permissions explicites
install -d -m 700 "$directory"
```

---

## Audit et Logging

### Événements à Logger

#### Chargement de Profil

```bash
# Succès
echo "✅ Profil $PROFILE_NAME chargé avec succès" | \
    logger -t "ubuntu-configs" -p user.info

# Erreur
echo "❌ Erreur chargement profil: $error" | \
    logger -t "ubuntu-configs" -p user.error
```

---

#### Détection de Profil

```bash
# Méthode de détection utilisée
echo "Profil $profile détecté via: $method" | \
    logger -t "ubuntu-configs" -p user.info
```

**Méthodes:**
- `manuel`: Configuration manuelle
- `hostname`: Détection par hostname
- `hardware`: Détection matérielle
- `scripts`: Détection par scripts spécifiques
- `default`: Fallback

---

#### Changement de Profil

```bash
# Changement manuel
echo "Profil changé: $old_profile → $new_profile par $USER" | \
    logger -t "ubuntu-configs" -p user.notice
```

---

#### Tentatives de Sécurité

```bash
# Profil invalide
echo "⚠️  Tentative profil invalide: $invalid_profile" | \
    logger -t "ubuntu-configs" -p user.warning

# Traversée de chemin
echo "🚨 Tentative de traversée de chemin détectée: $path" | \
    logger -t "ubuntu-configs" -p user.warning

# Module non autorisé
echo "⚠️  Tentative de chargement module non autorisé: $module" | \
    logger -t "ubuntu-configs" -p user.warning
```

---

### Consultation des Logs

#### Via journalctl

```bash
# Logs ubuntu-configs
journalctl -t ubuntu-configs

# Logs récents (dernière heure)
journalctl -t ubuntu-configs --since "1 hour ago"

# Logs de sécurité uniquement
journalctl -t ubuntu-configs -p warning..emerg

# Suivi en temps réel
journalctl -t ubuntu-configs -f
```

---

#### Via syslog

```bash
# Fichier de log traditionnel
tail -f /var/log/syslog | grep ubuntu-configs

# Recherche d'incidents
grep "Tentative" /var/log/syslog | grep ubuntu-configs
```

---

## Tests de Sécurité

### Suite de Tests de Sécurité

#### Test 1: Validation Whitelist

```bash
test_whitelist_validation() {
    # Profil valide
    result=$(definir_profil_manuel "TuF" && echo "OK" || echo "FAIL")
    assert_equals "OK" "$result"

    # Profil invalide
    result=$(definir_profil_manuel "Malicious" 2>&1)
    assert_contains "Profil invalide" "$result"
}
```

---

#### Test 2: Protection Traversée

```bash
test_path_traversal_protection() {
    # Tentative traversée classique
    echo "../../etc/passwd" > ~/.config/ubuntu-configs/machine_profile
    profile=$(detecter_machine)
    assert_equals "default" "$profile"  # Fallback sécurisé

    # Tentative avec symlink
    ln -s /etc/shadow ~/ubuntu-configs/profiles/evil
    profile=$(detecter_machine)
    assert_not_equals "evil" "$profile"
}
```

---

#### Test 3: Validation Modules

```bash
test_module_whitelist() {
    # Module autorisé
    MODULES_TEST=("utilitaires_systeme.sh:Test")
    # Doit charger sans erreur

    # Module non autorisé
    MODULES_TEST=("evil_module.sh:Malicious")
    # Doit ignorer avec avertissement
}
```

---

#### Test 4: Permissions Fichiers

```bash
test_file_permissions() {
    # Créer fichier config
    definir_profil_manuel "TuF"

    # Vérifier permissions
    perms=$(stat -c "%a" ~/.config/ubuntu-configs/machine_profile)
    assert_equals "600" "$perms"

    # Vérifier propriétaire
    owner=$(stat -c "%U" ~/.config/ubuntu-configs/machine_profile)
    assert_equals "$USER" "$owner"
}
```

---

### Tests de Fuzzing

**Objectif:** Tester avec entrées aléatoires/malformées

```bash
test_fuzzing_profile_names() {
    local fuzz_inputs=(
        ""                    # Vide
        " "                   # Espace
        "../../../etc/passwd" # Traversée
        "TuF\x00/etc/shadow"  # Null byte
        "$(rm -rf /)"         # Injection commande
        "'; DROP TABLE;"      # SQL injection (N/A mais test)
        "TuF' OR '1'='1"      # Injection logique
        "../../../../"        # Traversée multiple
        "TuF/../PcDeV"        # Traversée relative
    )

    for input in "${fuzz_inputs[@]}"; do
        result=$(definir_profil_manuel "$input" 2>&1)
        # Vérifier rejet sécurisé (pas d'exécution code)
        assert_safe_failure "$result"
    done
}
```

---

## Réponse aux Incidents

### Détection d'Incidents

**Indicateurs de Compromission (IOC):**

1. **Fichiers de profil modifiés sans raison**
   ```bash
   # Vérifier intégrité avec git
   cd ~/ubuntu-configs
   git status
   git diff
   ```

2. **Tentatives répétées de traversée dans les logs**
   ```bash
   journalctl -t ubuntu-configs | grep "traversée" | wc -l
   ```

3. **Profil inconnu ou bizarre chargé**
   ```bash
   echo $CURRENT_PROFILE
   # Si différent de TuF/PcDeV/default → Investigation
   ```

4. **Modules non autorisés tentés**
   ```bash
   journalctl -t ubuntu-configs | grep "non autorisé"
   ```

---

### Procédure de Réponse

#### Phase 1: Détection et Confinement

```bash
# 1. Isoler le système
# Déconnecter réseau si nécessaire

# 2. Vérifier l'état actuel
echo "Profil actuel: $CURRENT_PROFILE"
show-profile

# 3. Vérifier intégrité des fichiers
cd ~/ubuntu-configs
git status
git diff

# 4. Consulter les logs
journalctl -t ubuntu-configs --since "24 hours ago" > /tmp/incident.log
```

---

#### Phase 2: Investigation

```bash
# 1. Identifier fichiers modifiés
find ~/ubuntu-configs -type f -mtime -1

# 2. Vérifier permissions
find ~/ubuntu-configs -type f ! -perm 644 -ls
find ~/.config/ubuntu-configs -type f ! -perm 600 -ls

# 3. Rechercher contenu suspect
grep -r "rm -rf" ~/ubuntu-configs/
grep -r "sudo" ~/ubuntu-configs/profiles/

# 4. Vérifier historique git
cd ~/ubuntu-configs
git log --since="24 hours ago" --all --oneline
git diff HEAD~5
```

---

#### Phase 3: Éradication

```bash
# 1. Restaurer depuis version propre
cd ~/ubuntu-configs
git reset --hard HEAD  # Si modifications non commitées
# ou
git reset --hard <commit_propre>

# 2. Supprimer fichiers suspects
rm -f ~/.config/ubuntu-configs/machine_profile  # Si compromis
# Recréer avec profil légitime
definir_profil_manuel "TuF"

# 3. Recharger profil propre
source ~/.bashrc
```

---

#### Phase 4: Récupération

```bash
# 1. Vérifier que profil correct chargé
show-profile

# 2. Tester fonctionnalités
aide
raccourcis

# 3. Monitoring renforcé
journalctl -t ubuntu-configs -f

# 4. Audit post-incident
cd ~/ubuntu-configs
git log --all --graph --decorate
```

---

#### Phase 5: Leçons Apprises

**Documentation:**
1. Documenter l'incident (date, heure, découverte)
2. Identifier cause racine
3. Lister indicateurs de compromission observés
4. Documenter actions de réponse

**Améliorations:**
1. Renforcer contrôles si nécessaire
2. Ajouter détection pour IOC spécifiques
3. Mettre à jour procédures
4. Former utilisateurs si erreur humaine

---

## Bonnes Pratiques de Sécurité

### Pour les Utilisateurs

1. **Ne jamais éditer manuellement fichiers de profils depuis sources non fiables**
2. **Utiliser `definir_profil_manuel` au lieu d'éditer directement le fichier**
3. **Vérifier régulièrement `git status` dans ~/ubuntu-configs**
4. **Ne pas donner permissions write à d'autres utilisateurs**
5. **Sauvegarder configurations avant modifications importantes**

### Pour les Développeurs

1. **Code review de tous les nouveaux profils et modules**
2. **Tests de sécurité automatisés avant merge**
3. **Validation stricte de toutes les entrées**
4. **Principe de moindre privilège (pas de sudo)**
5. **Documentation des contrôles de sécurité**
6. **Whitelist plutôt que blacklist**
7. **Fail-safe (fallback sécurisé sur erreur)**

### Pour les Administrateurs

1. **Audit régulier des permissions fichiers**
2. **Monitoring des logs ubuntu-configs**
3. **Détection d'anomalies (profils inconnus, tentatives traversée)**
4. **Backup régulier des configurations**
5. **Plan de réponse aux incidents documenté**

---

## Checklist de Sécurité

### Lors de l'Installation

- [ ] Permissions correctes sur ~/ubuntu-configs (755)
- [ ] Permissions restrictives sur ~/.config/ubuntu-configs (700)
- [ ] Git configuré pour suivi des modifications
- [ ] Logs configurés (syslog/journald)

### Mensuel

- [ ] Audit des permissions fichiers
- [ ] Revue des logs pour tentatives suspectes
- [ ] Vérification intégrité git
- [ ] Tests de sécurité automatisés

### Après Modification de Profil

- [ ] Code review des changements
- [ ] Tests fonctionnels
- [ ] Tests de sécurité (traversée, injection)
- [ ] Commit git avec message descriptif

### Annuel

- [ ] Audit de sécurité complet
- [ ] Review du modèle de menaces
- [ ] Mise à jour des procédures
- [ ] Formation/sensibilisation utilisateurs

---

## Références

- **API Reference:** [API_PROFILS.md](API_PROFILS.md)
- **Architecture:** [ARCHITECTURE_PROFILS.md](ARCHITECTURE_PROFILS.md)
- **Guide Développeur:** [DEVELOPPEUR_PROFILS.md](DEVELOPPEUR_PROFILS.md)
- **Exemples:** [EXEMPLES_PROFILS.md](EXEMPLES_PROFILS.md)
- **OWASP Secure Coding Practices:** https://owasp.org/
- **CWE Top 25:** https://cwe.mitre.org/top25/

---

**Version:** 1.0
**Dernière mise à jour:** Octobre 2025
**Mainteneur:** ubuntu-configs team
**Classification:** Public
