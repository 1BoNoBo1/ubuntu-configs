# Système de Bandeau de Statut

Guide d'utilisation du système de bandeau d'informations pour terminal.

## Vue d'ensemble

Le système de bandeau fournit **2 méthodes** pour afficher des informations importantes en permanence :

### 🎯 Méthode 1 : tmux (Recommandé)
Barre de statut permanente en bas d'écran avec rafraîchissement automatique toutes les 2 secondes.

### 🔧 Méthode 2 : tput (Alternative sans installation)
Bandeau shell avec positionnement en bas d'écran, utilisable sans tmux.

---

## Méthode 1 : tmux (Recommandé)

### Installation

```bash
# Installer tmux
sudo apt install tmux

# Lier la configuration
ln -sf ~/ubuntu-configs/.tmux.conf ~/.tmux.conf
```

### Démarrage

```bash
# Démarrer tmux avec le bandeau
start-tmux-status

# Ou directement
tmux
```

### Affichage

La barre de statut affiche en permanence :

```
⚪ tmux PcDeV jim | 💻 default | 🔋 27% | 💾 3,0Gi/3,7Gi | ⚙️ 0.22 | ⏰ 27/10 11:57:30
```

**Sections :**
- **Gauche** : État tmux + Machine + User
- **Droite** : Profil + Batterie + RAM + CPU + Heure

### Raccourcis tmux

| Raccourci | Action |
|-----------|--------|
| `Ctrl+B` puis `R` | Recharger la configuration |
| `Ctrl+B` puis `\|` | Split vertical |
| `Ctrl+B` puis `-` | Split horizontal |
| `Ctrl+B` puis `h/j/k/l` | Navigation entre panes |
| `Ctrl+B` puis `D` | Détacher la session |

### Configuration

Fichier : `~/ubuntu-configs/.tmux.conf`

Personnalisation possible :
- Couleurs de la barre (`set -g status-style`)
- Intervalle de rafraîchissement (`set -g status-interval`)
- Contenu des sections gauche/droite
- Position de la barre (`set -g status-position`)

---

## Méthode 2 : tput (Alternative)

### Fonctions disponibles

#### `status-banner`
Affiche un statut système complet et formaté.

```bash
status-banner
```

**Sortie :**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Statut Système
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  💻 Profil      : default
  🖥️  Machine     : PcDeV
  🔋 Batterie    : 27%
  💾 RAM         : 3,0Gi / 3,7Gi (81%)
  ⚙️  CPU Load   : 0,22, 0,07, 0,02
  💿 Disque (/)  : 37G / 114G (35%)
  ⏱️  Uptime      : 21 hours, 46 minutes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### `bandeau`
Affiche un bandeau compact en bas d'écran (une seule fois).

```bash
bandeau
```

**Sortie :**
```
💻 default | 🔋27% | 💾 3,0Gi/3,7Gi | ⚙️ 0.22 | ⏰ 11:57:30
```

#### `watch-status`
Affiche un bandeau en continu, mis à jour toutes les 2 secondes.

```bash
watch-status
# Ctrl+C pour arrêter
```

### Intégration dans le prompt

Ajoutez `bandeau` à votre prompt bash/zsh :

**Bash (~/.bashrc) :**
```bash
PROMPT_COMMAND='bandeau'
```

**Zsh (~/.zshrc) :**
```bash
precmd() {
    bandeau
}
```

---

## Comparaison des Méthodes

| Critère | tmux | tput |
|---------|------|------|
| **Installation** | Requiert tmux | Aucune |
| **Permanence** | Toujours visible | Selon intégration |
| **Rafraîchissement** | Automatique (2s) | Manuel ou prompt |
| **Position** | Barre fixe bas | Bas d'écran |
| **Fonctionnalités** | Session management | Simple bandeau |
| **Recommandé pour** | Usage quotidien | Tests rapides |

---

## Informations Affichées

### 💻 Profil
Le profil actuel de la machine (TuF, PcDeV, default).

**Source :** `~/.config/ubuntu-configs/machine_profile`

### 🔋 Batterie
- **Portable** : Pourcentage + état de charge
- **Desktop** : "AC" (alimentation secteur)

**Source :** `/sys/class/power_supply/BAT0/capacity`

### 💾 RAM
Usage mémoire actuel / total (pourcentage).

**Source :** `free -h`

### ⚙️ CPU Load
Charge moyenne sur 1 minute (load average).

**Source :** `uptime`

### ⏰ Heure
Heure actuelle au format HH:MM:SS (tmux) ou date complète.

**Source :** `date`

---

## Scripts

### Localisation

```
~/ubuntu-configs/
├── .tmux.conf                    # Configuration tmux
├── scripts/
│   ├── status_banner.sh         # Bandeau tput
│   └── tmux_battery.sh          # Helper batterie tmux
└── mon_shell/
    └── bandeau_status.sh        # Module shell avec fonctions
```

### Helper : `tmux_battery.sh`

Script intelligent qui détecte :
- Portable avec BAT0/BAT1 → affiche pourcentage + état
- Desktop sans batterie → affiche "AC"

```bash
~/ubuntu-configs/scripts/tmux_battery.sh
# Sortie : 🔋 27% ou 🔌 AC
```

---

## Aide Intégrée

```bash
aide-bandeau
```

Affiche l'aide complète avec toutes les commandes disponibles.

---

## Exemples d'Utilisation

### Démarrage Rapide

```bash
# 1. Charger les fonctions
source ~/ubuntu-configs/mon_shell/bandeau_status.sh

# 2. Afficher le statut complet
status-banner

# 3. Ou démarrer tmux avec bandeau permanent
start-tmux-status
```

### Workflow Quotidien

**Option A : tmux (recommandé)**
```bash
# Au démarrage de la session
tmux

# Le bandeau est toujours visible en bas
# Travaillez normalement, le statut se met à jour automatiquement
```

**Option B : Intégration prompt**
```bash
# Ajoutez à ~/.bashrc ou ~/.zshrc
source ~/ubuntu-configs/mon_shell/bandeau_status.sh
PROMPT_COMMAND='bandeau'  # bash
# ou
precmd() { bandeau }      # zsh

# Le bandeau s'affiche après chaque commande
```

### Surveillance Continue

```bash
# Surveiller en continu (sans tmux)
watch-status

# Arrêter avec Ctrl+C
```

---

## Personnalisation

### Modifier les Couleurs (tmux)

Éditez `~/.tmux.conf` :

```bash
# Changer le fond de la barre
set -g status-style bg=colour235,fg=colour136

# Couleurs des sections
set -g status-left "#[fg=green]..."
set -g status-right "#[fg=magenta]..."
```

**Codes couleurs :**
- `colour235` : Gris foncé
- `colour136` : Jaune
- `green`, `cyan`, `red`, `magenta`, `yellow` : Couleurs nommées

### Modifier le Contenu (tmux)

```bash
# Ajouter une section personnalisée
set -g status-right "... | #[fg=blue]📁 #(df -h / | awk 'NR==2 {print $5}')"
```

### Modifier les Fonctions (tput)

Éditez `~/ubuntu-configs/mon_shell/bandeau_status.sh` pour personnaliser les fonctions.

---

## Dépannage

### tmux n'affiche pas le bandeau

```bash
# Vérifier que la config est liée
ls -la ~/.tmux.conf

# Recharger la config dans tmux
# Ctrl+B puis R

# Ou relancer tmux
tmux kill-server
tmux
```

### Bandeau tput mal positionné

```bash
# Vérifier les variables de terminal
echo $TERM

# Doit être : xterm-256color ou screen-256color
# Si nécessaire :
export TERM=xterm-256color
```

### Informations incorrectes

```bash
# Tester les helpers individuellement
~/ubuntu-configs/scripts/tmux_battery.sh
uptime
free -h
```

---

## Intégration avec les Profils

Le bandeau s'intègre automatiquement avec le système de profils multi-machines :

- **TuF (Desktop)** : Affiche "AC" pour l'alimentation
- **PcDeV (Ultraportable)** : Affiche le pourcentage de batterie
- **default** : S'adapte automatiquement

Le profil actuel est toujours affiché dans le bandeau : `💻 [nom_profil]`

---

## Références

- **tmux Documentation** : https://github.com/tmux/tmux/wiki
- **tput Manual** : `man tput`
- **Profils** : Voir `README_PROFILS.md`

---

## Commandes Rapides

| Commande | Description |
|----------|-------------|
| `start-tmux-status` | Démarrer tmux avec bandeau |
| `status-banner` | Afficher statut complet |
| `bandeau` | Afficher bandeau compact |
| `watch-status` | Surveillance continue |
| `aide-bandeau` | Afficher l'aide |

---

**💡 Recommandation :** Pour un usage quotidien, installez tmux et utilisez la configuration fournie. Le bandeau sera toujours visible et à jour automatiquement.
