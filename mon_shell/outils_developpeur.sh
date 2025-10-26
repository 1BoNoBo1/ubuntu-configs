#!/usr/bin/env bash
# ============================================================
# Module : outils_developpeur.sh
# Objectif : Outils spécialisés pour développeurs
# Usage : source outils_developpeur.sh
# Style : Fonctions courtes, pratiques pour le dev
# ============================================================

# Couleurs
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[0;35m'
NC='\033[0m'

afficher() {
    echo -e "${2:-$NC}$1${NC}"
}

# ========== ANALYSEUR DE CODE ==========

analyser_projet() {
    local dossier="${1:-.}"

    afficher "📊 ANALYSE DU PROJET: $dossier" $BLEU
    echo "══════════════════════════════"

    if [[ ! -d "$dossier" ]]; then
        afficher "❌ Dossier '$dossier' introuvable" $ROUGE
        return 1
    fi

    # Statistiques de base
    local total_fichiers=$(find "$dossier" -type f 2>/dev/null | wc -l)
    local total_lignes=0

    # Analyse par type de fichier
    afficher "📁 Structure du projet:" $CYAN

    declare -A extensions
    declare -A lignes_par_ext

    # Parcourir les fichiers
    while IFS= read -r -d '' fichier; do
        local ext="${fichier##*.}"

        # Si pas d'extension
        if [[ "$ext" == "$fichier" ]]; then
            ext="sans_extension"
        fi

        # Compter
        extensions["$ext"]=$((${extensions["$ext"]:-0} + 1))

        # Compter lignes si c'est un fichier texte
        if file "$fichier" 2>/dev/null | grep -q "text"; then
            local lignes=$(wc -l < "$fichier" 2>/dev/null || echo 0)
            lignes_par_ext["$ext"]=$((${lignes_par_ext["$ext"]:-0} + lignes))
            total_lignes=$((total_lignes + lignes))
        fi

    done < <(find "$dossier" -type f -print0 2>/dev/null)

    # Afficher résultats
    echo "   📄 Total fichiers: $total_fichiers"
    echo "   📝 Total lignes: $total_lignes"
    echo

    afficher "🏷️ Répartition par extension:" $CYAN
    for ext in "${!extensions[@]}"; do
        local count=${extensions["$ext"]}
        local lignes=${lignes_par_ext["$ext"]:-0}
        printf "   %-12s %3d fichiers" "$ext" "$count"
        if [[ $lignes -gt 0 ]]; then
            printf " (%d lignes)" "$lignes"
        fi
        echo
    done
}

detecter_langage_projet() {
    local dossier="${1:-.}"

    afficher "🔍 Détection du langage principal..." $CYAN

    # Fichiers de configuration communs
    if [[ -f "$dossier/package.json" ]]; then
        afficher "📦 Projet Node.js/JavaScript détecté" $VERT
        if [[ -f "$dossier/tsconfig.json" ]]; then
            afficher "   TypeScript configuré" $CYAN
        fi
    elif [[ -f "$dossier/requirements.txt" ]] || [[ -f "$dossier/setup.py" ]]; then
        afficher "🐍 Projet Python détecté" $VERT
    elif [[ -f "$dossier/Cargo.toml" ]]; then
        afficher "🦀 Projet Rust détecté" $VERT
    elif [[ -f "$dossier/go.mod" ]]; then
        afficher "🐹 Projet Go détecté" $VERT
    elif [[ -f "$dossier/composer.json" ]]; then
        afficher "🐘 Projet PHP détecté" $VERT
    elif [[ -f "$dossier/pom.xml" ]] || [[ -f "$dossier/build.gradle" ]]; then
        afficher "☕ Projet Java détecté" $VERT
    else
        # Analyser les extensions
        local js_files=$(find "$dossier" -name "*.js" 2>/dev/null | wc -l)
        local py_files=$(find "$dossier" -name "*.py" 2>/dev/null | wc -l)
        local sh_files=$(find "$dossier" -name "*.sh" 2>/dev/null | wc -l)

        if [[ $js_files -gt 0 ]]; then
            afficher "📜 Fichiers JavaScript trouvés ($js_files)" $JAUNE
        fi
        if [[ $py_files -gt 0 ]]; then
            afficher "🐍 Fichiers Python trouvés ($py_files)" $JAUNE
        fi
        if [[ $sh_files -gt 0 ]]; then
            afficher "🐚 Scripts shell trouvés ($sh_files)" $JAUNE
        fi
    fi
}

# ========== OUTILS GIT AVANCÉS ==========

git_statut_propre() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        afficher "❌ Pas dans un dépôt Git" $ROUGE
        return 1
    fi

    afficher "📊 STATUT GIT DÉTAILLÉ" $BLEU
    echo "═══════════════════════"

    # Branche actuelle
    local branche=$(git branch --show-current)
    afficher "🌿 Branche: $branche" $CYAN

    # Statut des fichiers
    local modifies=$(git status --porcelain | grep "^ M" | wc -l)
    local ajoutes=$(git status --porcelain | grep "^A" | wc -l)
    local supprimes=$(git status --porcelain | grep "^ D" | wc -l)
    local non_suivis=$(git status --porcelain | grep "^??" | wc -l)

    echo "📄 Fichiers modifiés: $modifies"
    echo "➕ Fichiers ajoutés: $ajoutes"
    echo "➖ Fichiers supprimés: $supprimes"
    echo "❓ Fichiers non suivis: $non_suivis"

    # Derniers commits
    afficher "📜 Derniers commits:" $CYAN
    git log --oneline -5 | while read ligne; do
        echo "   $ligne"
    done
}

git_nettoyage_rapide() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        afficher "❌ Pas dans un dépôt Git" $ROUGE
        return 1
    fi

    afficher "🧹 Nettoyage Git..." $JAUNE

    # Nettoyer les branches mergées
    local branches_supprimees=0
    git branch --merged | grep -v "\*\|main\|master" | while read branche; do
        git branch -d "$branche" 2>/dev/null && {
            afficher "🗑️ Branche supprimée: $branche" $VERT
            ((branches_supprimees++))
        }
    done

    # Nettoyer les fichiers Git
    git gc --prune=now >/dev/null 2>&1
    afficher "✅ Nettoyage Git terminé" $VERT
}

git_sauvegarde_rapide() {
    local message="${*:-Sauvegarde rapide}"

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        afficher "❌ Pas dans un dépôt Git" $ROUGE
        return 1
    fi

    afficher "💾 Sauvegarde Git rapide..." $CYAN

    git add .
    git commit -m "$message - $(date '+%Y-%m-%d %H:%M')"

    afficher "✅ Sauvegarde effectuée: $message" $VERT
}

# ========== SERVEUR DE DÉVELOPPEMENT ==========

serveur_simple() {
    local port="${1:-8000}"
    local dossier="${2:-.}"

    afficher "🌐 Démarrage serveur HTTP simple" $CYAN
    afficher "📁 Dossier: $dossier" $CYAN
    afficher "🔗 Port: $port" $CYAN
    afficher "🌍 URL: http://localhost:$port" $VERT

    # Utiliser Python si disponible
    if command -v python3 >/dev/null; then
        cd "$dossier" && python3 -m http.server "$port"
    elif command -v python >/dev/null; then
        cd "$dossier" && python -m SimpleHTTPServer "$port"
    else
        afficher "❌ Python non trouvé pour serveur HTTP" $ROUGE
        return 1
    fi
}

tester_port() {
    local port="$1"

    if [[ -z "$port" ]]; then
        afficher "❌ Usage: tester_port <numéro_port>" $ROUGE
        return 1
    fi

    afficher "🔍 Test du port $port..." $CYAN

    if netstat -ln 2>/dev/null | grep ":$port " >/dev/null; then
        afficher "🔴 Port $port occupé" $ROUGE

        # Trouver le processus
        local processus=$(lsof -i ":$port" 2>/dev/null | tail -1 | awk '{print $2 " " $1}')
        if [[ -n "$processus" ]]; then
            afficher "   Processus: $processus" $JAUNE
        fi
    else
        afficher "✅ Port $port libre" $VERT
    fi
}

# ========== OUTILS DE DOCUMENTATION ==========

generer_readme_simple() {
    local nom_projet="${1:-$(basename "$(pwd)")}"

    afficher "📝 Génération README.md pour '$nom_projet'" $CYAN

    cat > README.md << EOF
# $nom_projet

Description courte du projet.

## Installation

\`\`\`bash
# Commandes d'installation
\`\`\`

## Utilisation

\`\`\`bash
# Exemples d'utilisation
\`\`\`

## Fonctionnalités

- [ ] Fonctionnalité 1
- [ ] Fonctionnalité 2
- [ ] Fonctionnalité 3

## Développement

\`\`\`bash
# Commandes de développement
\`\`\`

## Licence

Licence du projet.

---

Généré le $(date '+%Y-%m-%d') avec outils_developpeur.sh
EOF

    afficher "✅ README.md généré" $VERT
}

generer_gitignore() {
    local type="${1:-general}"

    afficher "📝 Génération .gitignore ($type)" $CYAN

    case "$type" in
        "node"|"js")
            cat > .gitignore << 'EOF'
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.npm
.yarn-integrity

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build
dist/
build/
*.tgz
*.tar.gz

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
            ;;
        "python"|"py")
            cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/

# Virtual env
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
            ;;
        *)
            cat > .gitignore << 'EOF'
# Fichiers temporaires
*.tmp
*.temp
*~
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build
build/
dist/
target/

# Environment
.env
.env.local
EOF
            ;;
    esac

    afficher "✅ .gitignore généré pour $type" $VERT
}

# ========== OUTILS DE TEST ==========

tester_syntaxe() {
    local fichier="$1"

    if [[ -z "$fichier" ]]; then
        afficher "❌ Usage: tester_syntaxe <fichier>" $ROUGE
        return 1
    fi

    if [[ ! -f "$fichier" ]]; then
        afficher "❌ Fichier '$fichier' introuvable" $ROUGE
        return 1
    fi

    local extension="${fichier##*.}"

    afficher "🔍 Test syntaxe: $fichier" $CYAN

    case "$extension" in
        "sh"|"bash")
            if bash -n "$fichier" 2>/dev/null; then
                afficher "✅ Syntaxe Bash OK" $VERT
            else
                afficher "❌ Erreur syntaxe Bash" $ROUGE
                bash -n "$fichier"
            fi
            ;;
        "py")
            if command -v python3 >/dev/null; then
                if python3 -m py_compile "$fichier" 2>/dev/null; then
                    afficher "✅ Syntaxe Python OK" $VERT
                else
                    afficher "❌ Erreur syntaxe Python" $ROUGE
                fi
            else
                afficher "⚠️ Python3 non disponible" $JAUNE
            fi
            ;;
        "js")
            if command -v node >/dev/null; then
                if node -c "$fichier" 2>/dev/null; then
                    afficher "✅ Syntaxe JavaScript OK" $VERT
                else
                    afficher "❌ Erreur syntaxe JavaScript" $ROUGE
                fi
            else
                afficher "⚠️ Node.js non disponible" $JAUNE
            fi
            ;;
        *)
            afficher "⚠️ Type de fichier non supporté: .$extension" $JAUNE
            ;;
    esac
}

# ========== ALIASES ==========

alias analyse='analyser_projet'
alias detect-lang='detecter_langage_projet'
alias gstat='git_statut_propre'
alias gsave='git_sauvegarde_rapide'
alias gclean='git_nettoyage_rapide'
alias serveur='serveur_simple'
alias port='tester_port'
alias readme='generer_readme_simple'
alias gitignore='generer_gitignore'
alias test-syntax='tester_syntaxe'

# ========== AIDE ==========

aide_dev() {
    afficher "💻 OUTILS DÉVELOPPEUR" $BLEU
    echo "══════════════════════"
    echo
    afficher "📊 Analyse projet:" $CYAN
    echo "  analyse [dossier]       # Analyser structure projet"
    echo "  detect-lang [dossier]   # Détecter langage principal"
    echo
    afficher "🔧 Git avancé:" $CYAN
    echo "  gstat                   # Statut Git détaillé"
    echo "  gsave [message]         # Sauvegarde rapide"
    echo "  gclean                  # Nettoyage Git"
    echo
    afficher "🌐 Serveur dev:" $CYAN
    echo "  serveur [port] [dossier] # Serveur HTTP simple"
    echo "  port <numéro>           # Tester si port libre"
    echo
    afficher "📝 Documentation:" $CYAN
    echo "  readme [nom]            # Générer README.md"
    echo "  gitignore <type>        # Générer .gitignore"
    echo
    afficher "🧪 Tests:" $CYAN
    echo "  test-syntax <fichier>   # Tester syntaxe"
    echo
    afficher "💡 Exemples:" $JAUNE
    echo "  analyse .               # Analyser projet actuel"
    echo "  serveur 3000            # Serveur sur port 3000"
    echo "  gitignore node          # .gitignore pour Node.js"
}

alias aide-dev='aide_dev'

afficher "✅ Outils développeur chargés" $VERT
afficher "💡 Tapez 'aide-dev' pour voir toutes les commandes" $CYAN