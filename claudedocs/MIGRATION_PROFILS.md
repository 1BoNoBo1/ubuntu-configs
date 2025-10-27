# Guide de Migration - Système de Profils

Guide complet pour migrer depuis l'ancien système vers les profils multi-machines.

## Table des Matières

- [Vue d'Ensemble](#vue-densemble)
- [Avant la Migration](#avant-la-migration)
- [Scénarios de Migration](#scénarios-de-migration)
- [Migration Pas à Pas](#migration-pas-à-pas)
- [Migration de Personnalisations](#migration-de-personnalisations)
- [Vérification Post-Migration](#vérification-post-migration)
- [Rollback](#rollback)
- [FAQ Migration](#faq-migration)

---

## Vue d'Ensemble

### Ancien Système vs Nouveau Système

**Ancien Système (mon_shell):**
```
~/.mon_shell/
├── aliases.sh               # Tous alias pour toutes machines
├── colors.sh
├── functions_system.sh      # Toutes fonctions pour toutes machines
├── functions_security.sh
└── functions_utils.sh

.bashrc / .zshrc:
for file in ~/.mon_shell/*.sh; do
    source "$file"           # Chargement universel
done
```

**Problèmes:**
- ❌ Même configuration pour toutes les machines
- ❌ Modules lourds chargés même sur machines limitées
- ❌ Pas d'optimisation selon ressources
- ❌ Fonctionnalités desktop chargées sur laptop

**Nouveau Système (Profils):**
```
~/ubuntu-configs/
├── profiles/
│   ├── machine_detector.sh  # Détection automatique
│   ├── profile_loader.sh    # Chargement orchestré
│   ├── TuF/                 # Desktop: Modules complets
│   ├── PcDeV/               # Ultraportable: Modules essentiels
│   └── default/             # Universel: Modules standard
└── mon_shell/               # Modules réutilisables
    ├── colors.sh
    ├── aliases.sh
    └── [10 modules spécialisés]

.bashrc / .zshrc:
source ~/ubuntu-configs/profiles/profile_loader.sh
# Chargement adapté automatiquement
```

**Avantages:**
- ✅ Configuration adaptée par machine
- ✅ Optimisation ressources (MINIMAL/STANDARD/PERFORMANCE)
- ✅ Fonctionnalités spécifiques (audio desktop, batterie laptop)
- ✅ Sécurité renforcée (whitelist, validation)
- ✅ Extensibilité (nouveaux profils faciles)

---

## Avant la Migration

### 1. Backup de la Configuration Actuelle

```bash
# Créer backup complet
mkdir -p ~/backup_migration_$(date +%Y%m%d)
cd ~/backup_migration_$(date +%Y%m%d)

# Sauvegarder ancien système
if [[ -d ~/.mon_shell ]]; then
    cp -r ~/.mon_shell ./mon_shell_backup
fi

# Sauvegarder fichiers RC
cp ~/.bashrc ./bashrc_backup
cp ~/.zshrc ./zshrc_backup 2>/dev/null || true

# Sauvegarder personnalisations
cp -r ~/ubuntu-configs ./ubuntu-configs_backup 2>/dev/null || true

echo "✅ Backup créé dans ~/backup_migration_$(date +%Y%m%d)"
```

### 2. Inventaire des Personnalisations

```bash
# Lister alias personnalisés
grep "^alias" ~/.mon_shell/*.sh > ~/personnalisations_alias.txt

# Lister fonctions personnalisées
grep -E "^[a-zA-Z_][a-zA-Z0-9_]*\(\)" ~/.mon_shell/*.sh > ~/personnalisations_fonctions.txt

# Variables d'environnement
grep "^export" ~/.bashrc > ~/personnalisations_env.txt

echo "📋 Inventaire créé"
```

### 3. Identifier le Type de Machine

```bash
# Déterminer profil approprié

# Vérifier type
if [[ -d /sys/class/power_supply/BAT* ]]; then
    echo "Type: Portable"

    # Vérifier RAM
    ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $ram_gb -le 4 ]]; then
        echo "Profil recommandé: PcDeV (Ultraportable)"
    else
        echo "Profil recommandé: default ou PcDeV"
    fi
else
    echo "Type: Desktop"
    echo "Profil recommandé: TuF ou default"
fi
```

---

## Scénarios de Migration

### Scénario 1: Migration Simple (Pas de Personnalisation)

**Situation:** Configuration standard, pas de modifications majeures

**Durée:** 10 minutes

**Étapes:**
1. Backup actuel
2. Installation nouveau système
3. Test
4. Activation

```bash
# 1. Backup
cp -r ~/.mon_shell ~/backup_mon_shell

# 2. Le nouveau système est déjà installé dans ~/ubuntu-configs

# 3. Test (nouveau shell)
bash
source ~/ubuntu-configs/profiles/profile_loader.sh

# Vérifier profil chargé
show-profile

# Tester commandes
ll
aide

# 4. Activation (.bashrc)
cat >> ~/.bashrc << 'EOF'

# Système de profils multi-machines
if [[ -f ~/ubuntu-configs/profiles/profile_loader.sh ]]; then
    source ~/ubuntu-configs/profiles/profile_loader.sh
fi
EOF

# 5. Reload
source ~/.bashrc
```

---

### Scénario 2: Migration avec Personnalisations Légères

**Situation:** Quelques alias et fonctions personnalisés

**Durée:** 30 minutes

**Étapes:**
1. Backup et inventaire
2. Installation nouveau système
3. Migration des personnalisations
4. Test et validation
5. Activation

Voir section [Migration de Personnalisations](#migration-de-personnalisations)

---

### Scénario 3: Migration Complexe (Multiples Personnalisations)

**Situation:** Nombreuses personnalisations, scripts custom, intégrations

**Durée:** 1-2 heures

**Étapes:**
1. Backup complet
2. Création profil personnalisé
3. Migration systématique
4. Tests approfondis
5. Activation progressive

Voir section [Migration de Personnalisations](#migration-de-personnalisations)

---

## Migration Pas à Pas

### Étape 1: Préparation

```bash
# Créer répertoire de migration
mkdir -p ~/migration_profils
cd ~/migration_profils

# Backup
cp -r ~/.mon_shell ./backup_mon_shell
cp ~/.bashrc ./backup_bashrc
cp ~/.zshrc ./backup_zshrc 2>/dev/null || true

# Extraction personnalisations
echo "=== ALIAS PERSONNALISÉS ===" > personnalisations.txt
grep "^alias" ~/.mon_shell/*.sh 2>/dev/null >> personnalisations.txt || true

echo "" >> personnalisations.txt
echo "=== FONCTIONS PERSONNALISÉES ===" >> personnalisations.txt
grep -E "^[a-zA-Z_][a-zA-Z0-9_]*\(\)" ~/.mon_shell/*.sh 2>/dev/null >> personnalisations.txt || true

echo "" >> personnalisations.txt
echo "=== EXPORTS ===" >> personnalisations.txt
grep "^export" ~/.bashrc >> personnalisations.txt

cat personnalisations.txt
```

### Étape 2: Installation Nouveau Système

```bash
# Le système est déjà dans ~/ubuntu-configs/profiles/
ls -la ~/ubuntu-configs/profiles/

# Vérifier structure
tree ~/ubuntu-configs/profiles/
```

### Étape 3: Test en Mode Isolé

```bash
# Lancer nouveau shell pour test
bash --noprofile --norc

# Charger nouveau système
source ~/ubuntu-configs/profiles/profile_loader.sh

# Vérifier profil
show-profile
# Sortie attendue: Nom, Type, Mode du profil

# Tester commandes de base
ll
cd ~/Documents
aide
raccourcis

# Tester fonctions système
maj_ubuntu --help
analyse_disque --help

# Si tout fonctionne: Continuer
# Si problèmes: Analyser erreurs
exit  # Quitter shell test
```

### Étape 4: Migration des Personnalisations

**Option A: Ajouter au Profil Existant**

```bash
# Éditer config du profil approprié
# Pour desktop:
nano ~/ubuntu-configs/profiles/TuF/config.sh

# Pour ultraportable:
nano ~/ubuntu-configs/profiles/PcDeV/config.sh

# Ajouter à la fin du fichier, avant dernière section
# ==========================================
# Personnalisations Migrées
# ==========================================

# Alias personnalisés
alias mon-alias="ma-commande"

# Fonctions personnalisées
ma_fonction() {
    # Code de la fonction
}
```

**Option B: Créer Profil Personnalisé**

```bash
# Créer nouveau profil basé sur existant
cp -r ~/ubuntu-configs/profiles/TuF ~/ubuntu-configs/profiles/MonProfil

# Éditer
nano ~/ubuntu-configs/profiles/MonProfil/config.sh

# Modifier variables
export PROFILE_NAME="MonProfil"
export PROFILE_TYPE="custom"
export PROFILE_MODE="STANDARD"

# Ajouter personnalisations
# ... (voir exemple ci-dessus)

# Ajouter à whitelist
nano ~/ubuntu-configs/profiles/machine_detector.sh
# Ajouter "MonProfil" dans valid_profiles

nano ~/ubuntu-configs/profiles/profile_loader.sh
# Ajouter case MonProfil dans load_profile_modules

# Activer
switch-profile MonProfil
```

### Étape 5: Activation dans .bashrc / .zshrc

```bash
# Backup RC actuel
cp ~/.bashrc ~/.bashrc.backup

# Désactiver ancien système (commenter)
sed -i 's/^for file in ~\/.mon_shell/# for file in ~\/.mon_shell/' ~/.bashrc
sed -i 's/^    source "\$file"/# source "$file"/' ~/.bashrc
sed -i 's/^done/# done/' ~/.bashrc

# Ajouter nouveau système
cat >> ~/.bashrc << 'EOF'

# ==========================================
# Système de Profils Multi-Machines
# ==========================================
if [[ -f ~/ubuntu-configs/profiles/profile_loader.sh ]]; then
    source ~/ubuntu-configs/profiles/profile_loader.sh
fi
EOF

# Pour zsh (si utilisé)
if [[ -f ~/.zshrc ]]; then
    cp ~/.zshrc ~/.zshrc.backup

    # Désactiver ancien
    sed -i 's/^for file in ~\/.mon_shell/# for file in ~\/.mon_shell/' ~/.zshrc
    sed -i 's/^    source "\$file"/# source "$file"/' ~/.zshrc
    sed -i 's/^done/# done/' ~/.zshrc

    # Ajouter nouveau
    cat >> ~/.zshrc << 'EOF'

# ==========================================
# Système de Profils Multi-Machines
# ==========================================
if [[ -f ~/ubuntu-configs/profiles/profile_loader.sh ]]; then
    source ~/ubuntu-configs/profiles/profile_loader.sh
fi
EOF
fi
```

### Étape 6: Premier Redémarrage

```bash
# Recharger shell
source ~/.bashrc  # ou source ~/.zshrc

# Vérifier profil chargé
show-profile

# Tester commandes fréquentes
ll
cd ~
aide

# Tester personnalisations migrées
mon-alias
ma_fonction

# Si OK: Migration réussie!
# Si problèmes: Voir section Dépannage
```

---

## Migration de Personnalisations

### Alias Personnalisés

**Ancien emplacement:** `~/.mon_shell/aliases.sh` ou `~/.bashrc`

**Nouveau emplacement:** `~/ubuntu-configs/profiles/[Profil]/config.sh`

**Migration:**

```bash
# 1. Identifier alias
grep "^alias" ~/.bashrc > ~/mes_alias.txt

# 2. Éditer profil
nano ~/ubuntu-configs/profiles/TuF/config.sh

# 3. Ajouter section (avant dernière section)
# ==========================================
# Alias Personnalisés Migrés
# ==========================================

alias mon-projet="cd ~/Projets/mon-projet && code ."
alias backup-perso="rsync -av ~/Documents ~/Backup/"
alias update-all="sudo apt update && sudo apt upgrade -y && flatpak update -y"

# 4. Tester
source ~/ubuntu-configs/profiles/TuF/config.sh
mon-projet  # Doit fonctionner
```

### Fonctions Personnalisées

**Ancien emplacement:** `~/.mon_shell/functions_*.sh` ou `~/.bashrc`

**Nouveau emplacement:**
- **Spécifique à un profil:** `profiles/[Profil]/config.sh`
- **Commun à tous:** Créer nouveau module dans `mon_shell/`

**Migration Fonction Spécifique:**

```bash
# Ancienne fonction dans ~/.bashrc
ma_fonction_deploy() {
    git pull
    npm install
    npm run build
    systemctl restart mon-service
}

# Migrer vers profil
nano ~/ubuntu-configs/profiles/TuF/config.sh

# Ajouter:
# ==========================================
# Fonctions Personnalisées Migrées
# ==========================================

ma_fonction_deploy() {
    echo "🚀 Déploiement en cours..."

    git pull || return 1
    npm install || return 1
    npm run build || return 1
    systemctl restart mon-service || return 1

    echo "✅ Déploiement réussi"
}

# Note: Pas d'export -f (sécurité)
```

**Migration Fonction Commune (Nouveau Module):**

```bash
# Créer nouveau module
cat > ~/ubuntu-configs/mon_shell/outils_personnels.sh << 'EOF'
#!/bin/bash
# ==============================================================================
# Module : outils_personnels.sh
# Description : Outils personnalisés migrés
# ==============================================================================

# Protection double chargement
if [[ -n "$OUTILS_PERSONNELS_LOADED" ]]; then
    return 0
fi
export OUTILS_PERSONNELS_LOADED=1

# Fonction 1
ma_fonction() {
    # Code
}

# Fonction 2
autre_fonction() {
    # Code
}
EOF

# Ajouter à whitelist
nano ~/ubuntu-configs/profiles/profile_loader.sh
# Dans declare -A VALID_MODULES, ajouter:
# ["outils_personnels.sh"]=1

# Référencer dans profils
nano ~/ubuntu-configs/profiles/TuF/config.sh
# Dans MODULES_TUF, ajouter:
# "outils_personnels.sh:Outils personnalisés"
```

### Variables d'Environnement

**Ancien emplacement:** `~/.bashrc` ou `~/.profile`

**Nouveau emplacement:** `profiles/[Profil]/config.sh`

**Migration:**

```bash
# Anciennes variables
export EDITOR="vim"
export VISUAL="vim"
export BROWSER="firefox"
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# Migrer vers profil
nano ~/ubuntu-configs/profiles/TuF/config.sh

# Ajouter dans section Configuration Système:
# ==========================================
# Variables d'Environnement Personnalisées
# ==========================================

export EDITOR="vim"
export VISUAL="vim"
export BROWSER="firefox"
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export PATH="$PATH:$HOME/.local/bin"
```

### Scripts Personnalisés

**Ancien emplacement:** `~/.mon_shell/scripts/` ou éparpillés

**Nouveau emplacement:** `profiles/[Profil]/scripts/`

**Migration:**

```bash
# Copier scripts vers profil
mkdir -p ~/ubuntu-configs/profiles/TuF/scripts
cp ~/.mon_shell/scripts/* ~/ubuntu-configs/profiles/TuF/scripts/

# Créer alias dans config.sh
nano ~/ubuntu-configs/profiles/TuF/config.sh

# Ajouter:
alias mon-script="bash ~/ubuntu-configs/profiles/TuF/scripts/mon_script.sh"
alias autre-script="bash ~/ubuntu-configs/profiles/TuF/scripts/autre.sh"
```

---

## Vérification Post-Migration

### Checklist Fonctionnelle

```bash
# 1. Profil chargé correctement
show-profile
# ✅ Devrait afficher: Nom, Type, Mode

# 2. Variables d'environnement
echo $PROFILE_NAME
echo $PROFILE_MODE
echo $EDITOR
# ✅ Devraient être définies

# 3. Alias de base
ll
la
cd-
# ✅ Devraient fonctionner

# 4. Fonctions système
aide
raccourcis
maj_ubuntu --help
# ✅ Devraient fonctionner

# 5. Alias personnalisés
mon-alias  # Votre alias migré
# ✅ Devrait fonctionner

# 6. Fonctions personnalisées
ma_fonction  # Votre fonction migrée
# ✅ Devrait fonctionner

# 7. Commandes spécifiques profil
# TuF:
fix-audio --help
system-monitor

# PcDeV:
battery
eco-mode

# default:
system-info
# ✅ Devraient fonctionner selon profil
```

### Checklist Sécurité

```bash
# 1. Permissions fichier config
stat -c "%a %n" ~/.config/ubuntu-configs/machine_profile
# ✅ Devrait être 600

# 2. Pas d'erreurs dans logs
journalctl -t ubuntu-configs --since "1 hour ago"
# ✅ Pas d'erreurs critiques

# 3. Profil validé
cat ~/.config/ubuntu-configs/machine_profile
# ✅ Devrait être TuF, PcDeV, ou default (valide)
```

### Performance

```bash
# Mesurer temps de chargement
time (source ~/ubuntu-configs/profiles/profile_loader.sh)
# ✅ Devrait être < 1 seconde

# Vérifier modules chargés
echo "${#MODULES_TUF[@]} modules TuF"
echo "${#MODULES_PCDEV[@]} modules PcDeV"
# ✅ Nombre attendu selon profil
```

---

## Rollback

### Rollback Complet

```bash
# Si migration pose problème, revenir à ancien système

# 1. Restaurer .bashrc
cp ~/backup_migration_*/bashrc_backup ~/.bashrc

# 2. Restaurer .zshrc (si existe)
cp ~/backup_migration_*/zshrc_backup ~/.zshrc 2>/dev/null || true

# 3. Restaurer .mon_shell (si sauvegardé)
rm -rf ~/.mon_shell
cp -r ~/backup_migration_*/mon_shell_backup ~/.mon_shell

# 4. Recharger
source ~/.bashrc

# 5. Vérifier fonctionnement
ll
aide  # Ancienne aide

echo "✅ Rollback effectué - ancien système restauré"
```

### Rollback Partiel (Garder Nouveau, Restaurer Personnalisations)

```bash
# Garder nouveau système mais restaurer personnalisations perdues

# 1. Éditer profil
nano ~/ubuntu-configs/profiles/TuF/config.sh

# 2. Réajouter personnalisations depuis backup
cat ~/personnalisations_alias.txt
cat ~/personnalisations_fonctions.txt

# 3. Copier-coller dans config.sh

# 4. Recharger
reload-profile

# 5. Tester
mon-alias
ma_fonction
```

---

## FAQ Migration

### Q: Puis-je garder l'ancien ET le nouveau système?

**R: Non recommandé.** Risque de conflits et double chargement.

Si vraiment nécessaire:
```bash
# .bashrc
# Ancien système (commenté par défaut)
# for file in ~/.mon_shell/*.sh; do
#     source "$file"
# done

# Nouveau système (actif)
if [[ -f ~/ubuntu-configs/profiles/profile_loader.sh ]]; then
    source ~/ubuntu-configs/profiles/profile_loader.sh
fi
```

Pour tester ancien:
```bash
bash --norc
for file in ~/.mon_shell/*.sh; do source "$file"; done
```

---

### Q: Comment migrer si j'ai plusieurs machines?

**R: Migrer machine par machine, en commençant par la moins critique.**

Stratégie:
1. Machine test / secondaire → Migration complète
2. Tester pendant 1 semaine
3. Si OK → Machine principale

Synchronisation:
```bash
# Sur machine 1 (après migration réussie)
cd ~/ubuntu-configs
git add profiles/
git commit -m "Migration profils machine1"
git push

# Sur machine 2
cd ~/ubuntu-configs
git pull
# Suivre guide migration
# Configuration manuelle profil si besoin
switch-profile PcDeV  # Ou TuF selon machine
```

---

### Q: Que faire si j'ai énormément de personnalisations?

**R: Créer profil personnalisé complet.**

```bash
# Créer profil Custom
cp -r ~/ubuntu-configs/profiles/default ~/ubuntu-configs/profiles/Custom

# Migrer TOUTES personnalisations dans Custom/config.sh
nano ~/ubuntu-configs/profiles/Custom/config.sh

# Ajouter à whitelist (voir guide développeur)

# Activer
switch-profile Custom
```

---

### Q: Puis-je migrer progressivement?

**R: Oui, migration par étapes possible.**

Approche:
1. **Semaine 1:** Installer nouveau système, tester en parallèle
2. **Semaine 2:** Migrer alias basiques
3. **Semaine 3:** Migrer fonctions
4. **Semaine 4:** Activation complète, désactivation ancien

---

## Ressources Migration

- **Backup Script:** `claudedocs/scripts/migration_backup.sh` (à créer)
- **Validation Script:** `claudedocs/scripts/migration_validate.sh` (à créer)
- **Documentation API:** [API_PROFILS.md](API_PROFILS.md)
- **Guide Développeur:** [DEVELOPPEUR_PROFILS.md](DEVELOPPEUR_PROFILS.md)
- **Exemples:** [EXEMPLES_PROFILS.md](EXEMPLES_PROFILS.md)

---

## Support

En cas de problème pendant migration:

1. **Consulter logs:** `journalctl -t ubuntu-configs`
2. **Rollback temporaire:** Restaurer `.bashrc` de backup
3. **Demander aide:** Créer issue GitHub avec détails
4. **Documentation:** Relire guides API et Développeur

---

**Version:** 1.0
**Dernière mise à jour:** Octobre 2025
