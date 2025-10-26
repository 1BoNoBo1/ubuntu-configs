#!/usr/bin/env bash
# --------------------------------------------------
# Adaptive Tool Selection Matrix
# Intelligent tool selection based on system resources
# --------------------------------------------------

# Define colors directly for bash compatibility
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source adaptive detection
[[ -f "${BASH_SOURCE[0]%/*}/adaptive_detection.sh" ]] && source "${BASH_SOURCE[0]%/*}/adaptive_detection.sh"

# ========== TOOL SELECTION MATRICES ==========

# Tool configuration: "primary:fallback:memory_requirement_mb:cpu_requirement"
declare -A TOOL_MATRIX

# Text Editors
TOOL_MATRIX[editor_minimal]="nano:vi:5:1"
TOOL_MATRIX[editor_standard]="vim:nano:15:1"
TOOL_MATRIX[editor_performance]="nvim:vim:30:2"

# File Managers
TOOL_MATRIX[filemanager_minimal]="ranger:ls:10:1"
TOOL_MATRIX[filemanager_standard]="mc:ranger:25:1"
TOOL_MATRIX[filemanager_performance]="lf:mc:20:1"

# System Monitors
TOOL_MATRIX[monitor_minimal]="htop:top:8:1"
TOOL_MATRIX[monitor_standard]="btop:htop:15:1"
TOOL_MATRIX[monitor_performance]="btop:gotop:25:2"

# Terminal Multiplexers
TOOL_MATRIX[tmux_minimal]="screen:tmux:10:1"
TOOL_MATRIX[tmux_standard]="tmux:screen:20:1"
TOOL_MATRIX[tmux_performance]="tmux:zellij:25:2"

# Backup Solutions
TOOL_MATRIX[backup_minimal]="rsync:cp:5:1"
TOOL_MATRIX[backup_standard]="restic:rsync:50:1"
TOOL_MATRIX[backup_performance]="restic:borg:100:2"

# Compression Tools
TOOL_MATRIX[compression_minimal]="gzip:bzip2:10:1"
TOOL_MATRIX[compression_standard]="zstd:gzip:25:1"
TOOL_MATRIX[compression_performance]="zstd:lz4:40:2"

# Development Tools
TOOL_MATRIX[git_ui_minimal]="tig:git:15:1"
TOOL_MATRIX[git_ui_standard]="lazygit:tig:30:1"
TOOL_MATRIX[git_ui_performance]="lazygit:gitui:40:2"

# Network Tools
TOOL_MATRIX[network_minimal]="curl:wget:8:1"
TOOL_MATRIX[network_standard]="httpie:curl:20:1"
TOOL_MATRIX[network_performance]="xh:httpie:25:1"

# Package Managers Enhancement
TOOL_MATRIX[package_minimal]="apt:dpkg:10:1"
TOOL_MATRIX[package_standard]="nala:apt:25:1"
TOOL_MATRIX[package_performance]="nala:apt-fast:30:2"

# ========== TOOL SELECTION ENGINE ==========

select_optimal_tool() {
    local category="$1"
    local tier="${2:-$SYSTEM_TIER}"
    local available_memory="${3:-$SYSTEM_RAM_MB}"
    local available_cores="${4:-$SYSTEM_CPU_CORES}"

    # Ensure system is classified
    [[ -z "$tier" ]] && tier=$(quick_tier_check)

    local tool_key="${category}_${tier}"
    local tool_config="${TOOL_MATRIX[$tool_key]}"

    if [[ -z "$tool_config" ]]; then
        echo_color "❌ Configuration d'outil introuvable: $tool_key" $ROUGE
        return 1
    fi

    IFS=':' read -ra TOOL_PARTS <<< "$tool_config"
    local primary="${TOOL_PARTS[0]}"
    local fallback="${TOOL_PARTS[1]}"
    local required_memory="${TOOL_PARTS[2]:-10}"
    local required_cores="${TOOL_PARTS[3]:-1}"

    # Calculate available memory percentage
    local free_memory_mb=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    local memory_usage_percent=0
    if [[ $available_memory -gt 0 ]]; then
        memory_usage_percent=$(( (available_memory - free_memory_mb) * 100 / available_memory ))
    fi

    # Decision logic: primary if resources available, fallback otherwise
    if [[ $free_memory_mb -ge $required_memory ]] && [[ $available_cores -ge $required_cores ]] && [[ $memory_usage_percent -lt 80 ]]; then
        echo "$primary"
    else
        echo "$fallback"
    fi
}

# ========== INTELLIGENT INSTALLATION ==========

install_tier_tools() {
    local tier="${1:-$SYSTEM_TIER}"

    echo_color "🔧 Installation des outils pour le niveau $tier..." $CYAN

    case "$tier" in
        "minimal")
            install_minimal_tools
            ;;
        "standard")
            install_minimal_tools
            install_standard_tools
            ;;
        "performance")
            install_minimal_tools
            install_standard_tools
            install_performance_tools
            ;;
        *)
            echo_color "❌ Niveau inconnu: $tier" $ROUGE
            return 1
            ;;
    esac
}

install_minimal_tools() {
    echo_color "⚡ Installation outils minimaux..." $JAUNE

    local minimal_packages=(
        "nano"          # Editor
        "htop"          # Monitor
        "curl"          # Network
        "rsync"         # Backup
        "gzip"          # Compression
        "ranger"        # File manager
        "screen"        # Terminal multiplexer
        "tig"           # Git UI
    )

    install_packages_safely "${minimal_packages[@]}"
}

install_standard_tools() {
    echo_color "📈 Installation outils standards..." $BLEU

    local standard_packages=(
        "vim"           # Better editor
        "mc"            # File manager
        "btop"          # Better monitor
        "tmux"          # Terminal multiplexer
        "zstd"          # Compression
        "restic"        # Backup
        "nala"          # Package manager
        "lazygit"       # Git UI
        "httpie"        # Network tool
    )

    install_packages_safely "${standard_packages[@]}"
}

install_performance_tools() {
    echo_color "🚀 Installation outils performance..." $VERT

    local performance_packages=(
        "neovim"        # Advanced editor
        "lf"            # Fast file manager
        "gotop"         # Advanced monitor
        "zellij"        # Modern terminal multiplexer
        "lz4"           # Fast compression
        "borg"          # Advanced backup
        "gitui"         # Advanced git UI
        "xh"            # Fast HTTP client
    )

    install_packages_safely "${performance_packages[@]}"
}

install_packages_safely() {
    local packages=("$@")
    local failed_packages=()

    for package in "${packages[@]}"; do
        echo_color "  📦 Installation: $package" $CYAN

        if apt-cache show "$package" &>/dev/null; then
            if sudo apt install -y "$package" &>/dev/null; then
                echo_color "    ✅ $package installé" $VERT
            else
                echo_color "    ❌ Échec installation: $package" $ROUGE
                failed_packages+=("$package")
            fi
        else
            echo_color "    ⚠️  Package non trouvé: $package" $JAUNE
            failed_packages+=("$package")
        fi
    done

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        echo_color "⚠️  Packages non installés: ${failed_packages[*]}" $JAUNE
    fi
}

# ========== ADAPTIVE COMMAND ALIASES ==========

create_adaptive_aliases() {
    local tier="${1:-$SYSTEM_TIER}"
    local aliases_file="/tmp/adaptive_aliases_$$.sh"

    echo_color "🔗 Création des alias adaptatifs..." $CYAN

    cat > "$aliases_file" << EOF
#!/usr/bin/env bash
# Adaptive aliases for $tier tier system

# Text editor
alias edit='$(select_optimal_tool editor)'
alias e='$(select_optimal_tool editor)'

# File manager
alias fm='$(select_optimal_tool filemanager)'
alias files='$(select_optimal_tool filemanager)'

# System monitor
alias mon='$(select_optimal_tool monitor)'
alias top='$(select_optimal_tool monitor)'

# Terminal multiplexer
alias mux='$(select_optimal_tool tmux)'

# Git UI
alias gu='$(select_optimal_tool git_ui)'
alias gitui='$(select_optimal_tool git_ui)'

# Network tools
alias http='$(select_optimal_tool network)'

# Package manager
alias pkg='$(select_optimal_tool package)'

# Compression (with adaptive parameters)
compression_tool=\$(select_optimal_tool compression)
case "\$compression_tool" in
    "zstd") alias compress='zstd -3' ;;  # Balanced compression
    "gzip") alias compress='gzip -6' ;;  # Standard compression
    "lz4")  alias compress='lz4 -1' ;;   # Fast compression
    *) alias compress='gzip' ;;
esac

# Backup with adaptive strategy
backup_tool=\$(select_optimal_tool backup)
case "\$backup_tool" in
    "restic")
        alias backup='restic backup --exclude-caches'
        ;;
    "rsync")
        alias backup='rsync -av --progress'
        ;;
    "borg")
        alias backup='borg create --progress --compression lz4'
        ;;
    *)
        alias backup='rsync -av'
        ;;
esac
EOF

    echo "$aliases_file"
}

# ========== TOOL VERIFICATION ==========

verify_tool_installation() {
    local tier="${1:-$SYSTEM_TIER}"

    echo_color "🔍 Vérification des outils installés..." $BLEU

    local categories=("editor" "filemanager" "monitor" "tmux" "backup" "compression" "git_ui" "network" "package")
    local missing_tools=()
    local working_tools=()

    for category in "${categories[@]}"; do
        local selected_tool=$(select_optimal_tool "$category" "$tier")

        if command -v "$selected_tool" &>/dev/null; then
            working_tools+=("$category:$selected_tool")
            echo_color "  ✅ $category: $selected_tool" $VERT
        else
            missing_tools+=("$category:$selected_tool")
            echo_color "  ❌ $category: $selected_tool (manquant)" $ROUGE
        fi
    done

    # Summary
    echo_color "
📊 RÉSUMÉ VÉRIFICATION" $CYAN
    echo_color "=====================" $CYAN
    echo_color "✅ Outils fonctionnels: ${#working_tools[@]}" $VERT
    echo_color "❌ Outils manquants: ${#missing_tools[@]}" $ROUGE

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo_color "
🔧 Pour installer les outils manquants:" $JAUNE
        for tool_info in "${missing_tools[@]}"; do
            IFS=':' read -ra TOOL_PARTS <<< "$tool_info"
            echo_color "  sudo apt install ${TOOL_PARTS[1]}" $CYAN
        done
    fi

    return ${#missing_tools[@]}
}

# ========== CONFIGURATION OPTIMIZATION ==========

optimize_tool_configs() {
    local tier="${1:-$SYSTEM_TIER}"

    echo_color "⚙️  Optimisation des configurations d'outils..." $CYAN

    case "$tier" in
        "minimal")
            # Minimal configurations for resource conservation
            configure_minimal_tools
            ;;
        "standard")
            # Balanced configurations
            configure_standard_tools
            ;;
        "performance")
            # Full-featured configurations
            configure_performance_tools
            ;;
    esac
}

configure_minimal_tools() {
    # Vim minimal config
    cat > ~/.vimrc << 'EOF'
set nocompatible
syntax on
set number
set tabstop=4
set shiftwidth=4
set expandtab
EOF

    # Htop minimal config
    mkdir -p ~/.config/htop 2>/dev/null
    cat > ~/.config/htop/htoprc << 'EOF'
fields=0 48 17 18 38 39 40 2 46 47 49 1
sort_key=46
sort_direction=1
hide_threads=0
hide_kernel_threads=1
hide_userland_threads=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
tree_view=0
header_margin=1
detailed_cpu_time=0
cpu_count_from_zero=0
update_process_names=0
account_guest_in_cpu_meter=0
color_scheme=0
delay=15
left_meters=LeftCPUs Memory Swap
left_meter_modes=1 1 1
right_meters=RightCPUs Tasks LoadAverage Uptime
right_meter_modes=1 2 2 2
EOF
}

configure_standard_tools() {
    # Enhanced vim config
    cat > ~/.vimrc << 'EOF'
set nocompatible
syntax on
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set showcmd
set showmatch
set ruler
set laststatus=2
set wildmenu
set scrolloff=3
EOF

    # Tmux configuration
    cat > ~/.tmux.conf << 'EOF'
set -g default-terminal "screen-256color"
set -g prefix C-a
unbind C-b
bind C-a send-prefix
set -g base-index 1
setw -g pane-base-index 1
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
bind | split-window -h
bind - split-window -v
setw -g monitor-activity on
set -g visual-activity on
EOF
}

configure_performance_tools() {
    # Advanced neovim setup would go here
    # Advanced tmux config would go here
    # Performance-optimized tool configurations
    echo_color "  🚀 Configuration avancée des outils..." $VERT
}

# ========== MAIN FUNCTIONS ==========

# Setup adaptive tools for current system
setup_adaptive_tools() {
    echo_color "🎯 Configuration adaptative des outils" $MAGENTA
    echo_color "======================================" $MAGENTA

    # Ensure system classification
    [[ -z "$SYSTEM_TIER" ]] && classify_system_tier

    # Install appropriate tools
    install_tier_tools

    # Create adaptive aliases
    local aliases_file=$(create_adaptive_aliases)
    echo_color "🔗 Aliases créés: $aliases_file" $CYAN

    # Optimize configurations
    optimize_tool_configs

    # Verify installation
    verify_tool_installation

    echo_color "✅ Configuration adaptative terminée" $VERT
}

# Quick tool recommendation
recommend_tool() {
    local category="$1"
    local tier="${2:-$(quick_tier_check)}"

    if [[ -z "$category" ]]; then
        echo_color "Usage: recommend_tool <category> [tier]" $JAUNE
        echo_color "Catégories: editor, filemanager, monitor, tmux, backup, compression, git_ui, network, package" $CYAN
        return 1
    fi

    local recommended=$(select_optimal_tool "$category" "$tier")
    echo_color "🎯 Outil recommandé pour $category (niveau $tier): $recommended" $VERT
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-setup}" in
        "setup")
            setup_adaptive_tools
            ;;
        "verify")
            verify_tool_installation
            ;;
        "recommend")
            recommend_tool "$2" "$3"
            ;;
        "install")
            install_tier_tools "$2"
            ;;
        *)
            echo_color "Usage: $0 {setup|verify|recommend|install}" $JAUNE
            ;;
    esac
fi