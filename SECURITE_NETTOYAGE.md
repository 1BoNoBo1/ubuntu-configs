# 🛡️ Sécurité du Module de Nettoyage

## ⚠️ IMPORTANT - Protections Critiques

Le module `nettoyage_securise.sh` a été conçu avec **4 niveaux de protection** pour éviter toute suppression accidentelle de fichiers critiques.

---

## 🔴 NIVEAU 1 : INTERDICTION ABSOLUE

Ces dossiers **NE PEUVENT JAMAIS** être nettoyés (blocage immédiat) :

### Système racine et binaires
```
/                    # Racine système - INTERDIT
/bin                 # Binaires essentiels - INTERDIT
/sbin                # Binaires système - INTERDIT
/usr                 # Programmes utilisateur - INTERDIT
/usr/bin             # Sous-dossiers aussi protégés
/usr/local/bin       # Protection héritée
```

### Configuration et bibliothèques
```
/etc                 # Configuration système - INTERDIT
/lib, /lib32, /lib64 # Bibliothèques - INTERDIT
/boot                # Noyau et boot - INTERDIT
```

### Système et services
```
/dev                 # Périphériques - INTERDIT
/proc                # Processus - INTERDIT
/sys                 # Système virtuel - INTERDIT
/var                 # Données variables - INTERDIT
/run                 # Runtime - INTERDIT
```

### Montages et services
```
/root                # Home root - INTERDIT
/opt                 # Applications optionnelles - INTERDIT
/srv                 # Services - INTERDIT
/snap                # Paquets snap - INTERDIT
/mnt                 # Points montage - INTERDIT
/media               # Médias - INTERDIT
/lost+found          # Récupération - INTERDIT
```

### 🚨 Message si tenté
```
🚨 ALERTE SÉCURITÉ CRITIQUE !
════════════════════════════

❌ OPÉRATION INTERDITE
   Dossier système protégé: /etc

🛡️  Protection activée: Impossible de nettoyer les dossiers système
💡 Ce dossier contient des fichiers critiques du système

→ Nettoyage REFUSÉ immédiatement
```

---

## 🟡 NIVEAU 2 : AVERTISSEMENT + CONFIRMATION OBLIGATOIRE

Ces dossiers **sensibles** peuvent être nettoyés MAIS avec avertissement :

### Clés et certificats
```
~/.ssh               # Clés SSH - SENSIBLE
~/.gnupg             # Clés GPG - SENSIBLE
```

### Configuration utilisateur
```
~/.config            # Configurations apps - SENSIBLE
~/.local/share       # Données apps - SENSIBLE
```

### Navigateurs et emails
```
~/.mozilla           # Profils Firefox - SENSIBLE
~/.cache/mozilla     # Cache Firefox - SENSIBLE
~/.thunderbird       # Emails Thunderbird - SENSIBLE
```

### 💛 Message si tenté
```
⚠️  AVERTISSEMENT: Dossier sensible détecté
════════════════════════════════════════

📂 Dossier: /home/user/.ssh
🔐 Type: Configuration/Données sensibles

Ce dossier contient des données importantes:
  • Clés SSH/GPG
  • Configurations système
  • Données applications

Êtes-vous ABSOLUMENT certain de vouloir nettoyer ici ? (oui/NON) : _

→ Si vous ne tapez PAS "oui" → Annulation
→ Si vous confirmez → Continue avec prudence maximale
```

---

## 🟠 NIVEAU 3 : PROTECTION HOME COMPLET

Nettoyer **tout le dossier HOME** nécessite confirmation spéciale :

### Protection
```
~                    # $HOME complet - AVERTISSEMENT SPÉCIAL
/home/user           # Analyse totale - CONFIRMATION REQUISE
```

### 🧡 Message si tenté
```
⚠️  ALERTE: Nettoyage de tout le dossier HOME
═══════════════════════════════════════════

📂 Vous tentez de nettoyer: /home/user
⚠️  Ceci va analyser TOUS vos fichiers personnels !

💡 Recommandation: Spécifiez un sous-dossier précis
   Exemples:
   • nettoyer-safe ~/Downloads
   • nettoyer-safe ~/Documents
   • nettoyer-safe ~/Bureau

Continuer malgré tout sur TOUT le HOME ? (oui/NON) : _

→ Recommandation forte d'être plus précis
→ Si refus → Annulation
→ Si accepté → Continue avec analyse complète
```

---

## 🟢 NIVEAU 4 : DOSSIERS AUTORISÉS (sûrs)

Ces dossiers **peuvent** être nettoyés normalement :

### Dossiers utilisateur standards
```
~/Downloads          # Téléchargements - SÛR
~/Documents          # Documents - SÛR
~/Bureau             # Bureau/Desktop - SÛR
~/Images             # Images/Pictures - SÛR
~/Vidéos             # Vidéos/Videos - SÛR
~/Musique            # Musique/Music - SÛR
```

### Temporaires système
```
/tmp                 # Fichiers temporaires - SÛR
/var/tmp             # (si permissions)
```

### Autres dossiers utilisateur
```
~/Projets            # Projets personnels - SÛR
~/Téléchargements    # Variante française - SÛR
Tout sous-dossier de ~ non protégé - SÛR
```

---

## 🛡️ SYSTÈME DE PROTECTION MULTICOUCHE

### Vérification 1 : Résolution du chemin
```bash
# Suit les liens symboliques pour détecter vraie destination
readlink -f /chemin
realpath /chemin

# Empêche contournement par symlink
# /tmp/lien -> /etc/passwd  → DÉTECTÉ et BLOQUÉ
```

### Vérification 2 : Correspondance exacte
```bash
# Vérifie si c'est exactement un dossier protégé
if [[ "$chemin" == "/etc" ]]; then
    BLOQUER
fi
```

### Vérification 3 : Sous-dossiers
```bash
# Vérifie si c'est un sous-dossier d'un dossier protégé
if [[ "$chemin" == "/etc"/* ]]; then
    BLOQUER  # /etc/apache2 aussi bloqué
fi
```

### Vérification 4 : Permissions
```bash
# Vérifie permissions d'écriture
if [[ ! -w "$chemin" ]]; then
    REFUSER
fi
```

---

## 🎯 TRIPLE CONFIRMATION POUR SUPPRESSION

Même après validation du dossier, **3 étapes** avant suppression :

### Étape 1 : Analyse (aucune suppression)
```
🔎 PHASE 1: ANALYSE DES FICHIERS
─────────────────────────────────

📊 FICHIERS TEMPORAIRES TROUVÉS: 15
💾 Espace total à libérer: 2.5 MB

📋 LISTE DES FICHIERS (premiers 20):
  1. fichier1.tmp          125 KB
  2. fichier2.temp         89 KB
  ...

→ AUCUNE suppression à ce stade
→ Vous VOYEZ ce qui sera supprimé
```

### Étape 2 : Première confirmation
```
⚠️  VÉRIFICATION 1/2: CONFIRMATION INITIALE
───────────────────────────────────────────

Vous êtes sur le point de supprimer 15 fichier(s)
Espace à libérer: 2.5 MB

Voulez-vous continuer ? (oui/NON) : _

→ Il faut taper EXACTEMENT "oui" (minuscules)
→ "Oui", "OUI", "o", "y" → REFUSÉ
→ Tout autre chose → REFUSÉ
```

### Étape 3 : Deuxième confirmation
```
⚠️  VÉRIFICATION 2/2: CONFIRMATION FINALE
─────────────────────────────────────────

⚠️  DERNIÈRE CHANCE D'ANNULER !
Cette action est IRRÉVERSIBLE

Dossier: /home/user/Downloads
Fichiers: 15

Tapez SUPPRIMER pour confirmer définitivement : _

→ Il faut taper EXACTEMENT "SUPPRIMER" (MAJUSCULES)
→ "supprimer", "Supprimer" → REFUSÉ
→ Tout autre chose → REFUSÉ
```

### Étape 4 : Suppression effective
```
🗑️  SUPPRESSION EN COURS...
═══════════════════════════

  ✅ fichier1.tmp
  ✅ fichier2.temp
  ...

📊 RÉSULTAT FINAL
✅ Fichiers supprimés: 15
💾 Espace libéré: 2.5 MB
```

---

## 🎮 MODES D'UTILISATION SÉCURISÉS

### Mode 1 : LISTE SEULE (0% risque)
```bash
lister-temp ~/Downloads

# Résultat:
# 📋 ANALYSE FICHIERS TEMPORAIRES (MODE LECTURE SEULE)
# → Affiche seulement ce qui existe
# → AUCUNE suppression
# → 100% sûr
```

**Usage** : Toujours commencer par là

---

### Mode 2 : SÉCURISÉ (double confirmation)
```bash
nettoyer-safe ~/Downloads

# Processus:
# 1. Vérification dossier protégé  ← BLOCAGE si système
# 2. Analyse fichiers              ← Liste complète
# 3. Confirmation "oui"            ← Première vérif
# 4. Confirmation "SUPPRIMER"      ← Deuxième vérif
# 5. Suppression + rapport         ← Exécution
```

**Usage** : Recommandé pour nettoyage normal

---

### Mode 3 : INTERACTIF (contrôle total)
```bash
nettoyer-interactif ~/Documents

# Processus:
# Pour CHAQUE fichier:
# ═══════════════════════════════════════════
# Fichier 1/15
# ═══════════════════════════════════════════
# 📄 Nom: photo.tmp
# 📁 Chemin: /home/user/Documents/photo.tmp
# 💾 Taille: 1.2 KB
#
# Supprimer ce fichier ? (o/N) : _

# → Décision fichier par fichier
# → Contrôle maximum
```

**Usage** : Quand vous voulez contrôle absolu

---

## 📋 FICHIERS CIBLÉS PAR LE NETTOYAGE

### Patterns temporaires sûrs
```
*.tmp                # Temporaires génériques
*.temp               # Temporaires alternatifs
*~                   # Sauvegardes éditeurs (vim, emacs)
.DS_Store            # Métadonnées macOS
Thumbs.db            # Miniatures Windows
*.part               # Téléchargements incomplets
*.crdownload         # Téléchargements Chrome incomplets
```

### ✅ Ce qui N'est JAMAIS touché
```
❌ Fichiers normaux (*.txt, *.pdf, *.jpg, etc.)
❌ Dossiers (sauf vides en mode spécial)
❌ Fichiers cachés importants (.bashrc, .profile, etc.)
❌ Configurations (.config/*, .local/*, etc.)
❌ Documents utilisateur
❌ Tout fichier sans extension temporaire
```

---

## 🧪 TESTS DE VALIDATION

### Test automatique des protections
```bash
./test_protections_nettoyage.sh

# Vérifie:
# ✅ Blocage de / → OK
# ✅ Blocage de /etc → OK
# ✅ Blocage de /usr → OK
# ✅ Avertissement ~/.ssh → OK
# ✅ Autorisation ~/Downloads → OK
```

### Test manuel recommandé
```bash
# 1. Test lecture seule
source mon_shell/nettoyage_securise.sh
lister-temp ~/Downloads    # Doit fonctionner

# 2. Test blocage système
lister-temp /etc           # Doit être REFUSÉ

# 3. Test avertissement
lister-temp ~/.ssh         # Doit AVERTIR

# 4. Test nettoyage sûr
nettoyer-safe ~/Downloads  # Doit demander double confirmation
```

---

## 💡 RECOMMANDATIONS D'UTILISATION

### Workflow sécurisé standard
```bash
# Étape 1: TOUJOURS lister d'abord
lister-temp ~/Downloads

# Étape 2: Lire le résultat
# → Combien de fichiers ?
# → Quel espace à libérer ?
# → Liste des fichiers OK ?

# Étape 3: Si OK, nettoyer
nettoyer-safe ~/Downloads

# Étape 4: Confirmer deux fois
# → Taper "oui"
# → Taper "SUPPRIMER"
```

### Cas d'usage par mode

**Mode LISTE** : Audit, vérification, exploration
```bash
lister-temp ~/Documents
lister-temp ~/Images
lister-temp ~/Téléchargements
```

**Mode SÉCURISÉ** : Nettoyage confiant mais vérifié
```bash
nettoyer-safe ~/Downloads     # Téléchargements
nettoyer-safe ~/Bureau        # Bureau encombré
nettoyer-safe /tmp            # Temporaires système
```

**Mode INTERACTIF** : Tri sélectif et précis
```bash
nettoyer-interactif ~/Documents    # Garder certains, supprimer d'autres
nettoyer-interactif ~/Projets      # Projets avec fichiers temp mélangés
```

---

## ⚠️ CE QUE VOUS NE POUVEZ PAS FAIRE

### Impossible même avec confirmation
```bash
❌ nettoyer-safe /
    → REFUSÉ immédiatement

❌ nettoyer-safe /etc
    → REFUSÉ immédiatement

❌ nettoyer-safe /usr/bin
    → REFUSÉ immédiatement (sous-dossier de /usr)

❌ nettoyer-safe /var
    → REFUSÉ immédiatement
```

### Impossible sans confirmation explicite
```bash
⚠️ nettoyer-safe ~/.ssh
    → Demande "oui" pour continuer

⚠️ nettoyer-safe ~/.config
    → Demande "oui" pour continuer

⚠️ nettoyer-safe ~
    → Demande "oui" pour analyser tout le HOME
```

---

## 🆘 EN CAS D'ERREUR

### Si vous avez supprimé par erreur
```bash
# Malheureusement, rm -f est DÉFINITIF
# MAIS les protections limitent les dégâts:

1. Seuls les fichiers .tmp, .temp, ~, etc. sont supprimés
2. Jamais de fichiers importants (.txt, .pdf, .config, etc.)
3. Jamais de dossiers système
4. Liste affichée AVANT suppression

# Pour récupération:
# → Vérifier sauvegardes (restic, timeshift)
# → Vérifier corbeille (si disponible)
# → Outils forensics (photorec, testdisk)
```

### Si le module refuse de nettoyer un dossier sûr
```bash
# Vérifier les permissions
ls -la /chemin/vers/dossier

# Vérifier que ce n'est pas un lien symbolique vers système
readlink -f /chemin/vers/dossier

# Forcer (à vos risques) - DÉCONSEILLÉ
# Éditer DOSSIERS_INTERDITS dans le script
```

---

## 📖 AIDE INTÉGRÉE

```bash
# Charger le module
source ~/ubuntu-configs/mon_shell/nettoyage_securise.sh

# Afficher l'aide complète
aide-nettoyage

# Lister les fonctions disponibles
lister-temp              # Mode liste
nettoyer-safe            # Mode sécurisé
nettoyer-interactif      # Mode interactif
```

---

## ✅ RÉSUMÉ DES PROTECTIONS

| Protection | Niveau | Action |
|------------|--------|--------|
| Dossiers système (/, /etc, /usr, etc.) | 🔴 Critique | **BLOCAGE IMMÉDIAT** |
| Sous-dossiers système (/etc/*, /usr/*, etc.) | 🔴 Critique | **BLOCAGE IMMÉDIAT** |
| Clés SSH/GPG (~/.ssh, ~/.gnupg) | 🟡 Sensible | **AVERTISSEMENT + CONFIRMATION** |
| Config utilisateur (~/.config, etc.) | 🟡 Sensible | **AVERTISSEMENT + CONFIRMATION** |
| HOME complet (~) | 🟠 Large | **AVERTISSEMENT + CONFIRMATION** |
| Downloads, Documents, Bureau | 🟢 Sûr | **AUTORISÉ après double confirmation** |

**Résultat** : Impossible de casser votre système par accident ! 🛡️

---

**Dernière mise à jour** : Octobre 2025
**Version** : 2.0 - Protection maximale