#!/bin/bash
# ============================================================
# Script : adaptive_ubuntu.sh
# Objectif : Orchestrateur principal du système adaptatif Ubuntu
# Usage : sudo ./adaptive_ubuntu.sh [action]
# Compatibilité : Ubuntu ≥ 20.04 / Debian ≥ 11
# Intégration : Compatible avec enhance_ubuntu_geek.sh
# ============================================================

set -euo pipefail

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo_color() {
    echo -e "${2}${1}${NC}"
}

# ========== CONFIGURATION ==========

UTILISATEUR="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
DOSSIER_HOME="/home/$UTILISATEUR"
UBUNTU_CONFIGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MON_SHELL_DIR="$UBUNTU_CONFIGS_DIR/mon_shell"

# Configuration directories
ADAPTIVE_CONFIG_DIR="/etc/adaptive-ubuntu"
ADAPTIVE_LOG_DIR="/var/log/adaptive-ubuntu"
ADAPTIVE_CACHE_DIR="/var/cache/adaptive-ubuntu"

# ========== INITIALIZATION ==========

init_adaptive_system() {
    echo_color "🔧 Initialisation du système adaptatif Ubuntu..." $MAGENTA
    echo_color "=================================================" $MAGENTA

    # Create necessary directories
    sudo mkdir -p "$ADAPTIVE_CONFIG_DIR" "$ADAPTIVE_LOG_DIR" "$ADAPTIVE_CACHE_DIR"
    sudo chown "$UTILISATEUR:$UTILISATEUR" "$ADAPTIVE_CACHE_DIR"

    # Source adaptive modules
    source_adaptive_modules

    # Initial system detection and classification
    detect_and_classify

    # Create system configuration
    create_adaptive_config

    echo_color "✅ Système adaptatif initialisé" $GREEN
}

source_adaptive_modules() {
    echo_color "📦 Chargement des modules adaptatifs..." $CYAN

    local modules=(
        "colors.sh"
        "adaptive_detection.sh"
        "adaptive_tools.sh"
        "adaptive_monitoring.sh"
    )

    for module in "${modules[@]}"; do
        local module_path="$MON_SHELL_DIR/$module"
        if [[ -f "$module_path" ]]; then
            source "$module_path"
            echo_color "  ✅ Module chargé: $module" $GREEN
        else
            echo_color "  ⚠️  Module manquant: $module" $YELLOW
        fi
    done

    # Source existing mon_shell functions for compatibility
    local existing_modules=(
        "functions_system.sh"
        "functions_utils.sh"
        "functions_security.sh"
        "functions_webdav.sh"
    )

    for module in "${existing_modules[@]}"; do
        local module_path="$MON_SHELL_DIR/$module"
        if [[ -f "$module_path" ]]; then
            source "$module_path"
        fi
    done
}

create_adaptive_config() {
    local config_file="$ADAPTIVE_CONFIG_DIR/system.conf"

    echo_color "📝 Création configuration système..." $CYAN

    sudo tee "$config_file" > /dev/null << EOF
# Adaptive Ubuntu System Configuration
# Generated on $(date)

[system]
tier=$SYSTEM_TIER
ram_mb=$SYSTEM_RAM_MB
cpu_cores=$SYSTEM_CPU_CORES
cpu_mhz=$SYSTEM_CPU_MHZ
storage_type=$SYSTEM_STORAGE_TYPE
available_gb=$SYSTEM_AVAILABLE_GB
performance_score=$SYSTEM_PERFORMANCE_SCORE

[configuration]
swap_size=$TIER_SWAP_SIZE
services_mode=$TIER_SERVICES_MODE
gui_mode=$TIER_GUI_MODE
monitoring=$TIER_MONITORING
backup_strategy=$TIER_BACKUP_STRATEGY

[thresholds]
memory_warning=${MEMORY_THRESHOLDS[${SYSTEM_TIER}_warning]}
memory_critical=${MEMORY_THRESHOLDS[${SYSTEM_TIER}_critical]}
cpu_warning=${CPU_THRESHOLDS[${SYSTEM_TIER}_warning]}
cpu_critical=${CPU_THRESHOLDS[${SYSTEM_TIER}_critical]}

[paths]
ubuntu_configs_dir=$UBUNTU_CONFIGS_DIR
mon_shell_dir=$MON_SHELL_DIR
user_home=$DOSSIER_HOME
user=$UTILISATEUR
EOF

    echo_color "✅ Configuration sauvée: $config_file" $GREEN
}

# ========== ADAPTIVE INSTALLATION ==========

adaptive_install() {
    echo_color "🚀 Installation adaptative Ubuntu..." $MAGENTA
    echo_color "=====================================" $MAGENTA

    # Initialize system
    init_adaptive_system

    # Apply memory optimizations first
    apply_memory_optimizations

    # Install tier-appropriate tools
    setup_adaptive_tools

    # Configure services based on tier
    configure_tier_services

    # Setup monitoring
    setup_adaptive_monitoring

    # Integration with existing enhance_ubuntu_geek.sh
    integrate_with_existing_setup

    # Final validation
    validate_adaptive_installation

    echo_color "✅ Installation adaptative terminée" $GREEN
    display_installation_summary
}

apply_memory_optimizations() {
    echo_color "🧠 Application optimisations mémoire..." $CYAN

    case "$SYSTEM_TIER" in
        "minimal")
            apply_minimal_memory_optimizations
            ;;
        "standard")
            apply_standard_memory_optimizations
            ;;
        "performance")
            apply_performance_memory_optimizations
            ;;
    esac
}

apply_minimal_memory_optimizations() {
    echo_color "⚡ Optimisations mémoire minimales..." $YELLOW

    # Configure ZRAM swap
    configure_zram_swap

    # Kernel parameter tuning for low memory
    configure_kernel_parameters_minimal

    # Disable memory-hungry services
    disable_heavy_services

    # Configure low-memory systemd settings
    configure_systemd_minimal
}

configure_zram_swap() {
    echo_color "💾 Configuration ZRAM swap..." $CYAN

    # Install zram tools if not present
    if ! command -v zramctl &>/dev/null; then
        sudo apt update
        sudo apt install -y util-linux
    fi

    # Create zram configuration
    sudo tee /etc/systemd/system/zram-swap.service > /dev/null << EOF
[Unit]
Description=ZRAM swap
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/sh -c 'modprobe zram && echo lz4 > /sys/block/zram0/comp_algorithm && echo $TIER_SWAP_SIZE > /sys/block/zram0/disksize && mkswap /dev/zram0 && swapon -p 100 /dev/zram0'
ExecStop=/bin/sh -c 'swapoff /dev/zram0 && rmmod zram'

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable zram-swap.service
    echo_color "✅ ZRAM swap configuré ($TIER_SWAP_SIZE)" $GREEN
}

configure_kernel_parameters_minimal() {
    echo_color "⚙️  Configuration paramètres kernel..." $CYAN

    # Create sysctl configuration for low memory systems
    sudo tee /etc/sysctl.d/99-adaptive-memory.conf > /dev/null << EOF
# Adaptive Ubuntu - Memory optimizations for $SYSTEM_TIER tier

# Memory management
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.vfs_cache_pressure=50

# Network optimizations
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 65536 134217728
net.ipv4.tcp_wmem=4096 65536 134217728

# Security
kernel.dmesg_restrict=1
kernel.kptr_restrict=1
EOF

    sudo sysctl -p /etc/sysctl.d/99-adaptive-memory.conf
    echo_color "✅ Paramètres kernel optimisés" $GREEN
}

disable_heavy_services() {
    echo_color "🛑 Désactivation services lourds..." $CYAN

    local services_to_disable=()

    case "$SYSTEM_TIER" in
        "minimal")
            services_to_disable=(
                "snapd.service"
                "snapd.socket"
                "bluetooth.service"
                "cups.service"
                "cups-browsed.service"
                "avahi-daemon.service"
                "whoopsie.service"
                "kerneloops.service"
            )
            ;;
        "standard")
            services_to_disable=(
                "snapd.service"
                "whoopsie.service"
                "kerneloops.service"
            )
            ;;
    esac

    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            sudo systemctl disable "$service" 2>/dev/null || true
            sudo systemctl stop "$service" 2>/dev/null || true
            echo_color "  ❌ Service désactivé: $service" $YELLOW
        fi
    done
}

configure_systemd_minimal() {
    echo_color "⚙️  Configuration systemd minimal..." $CYAN

    # Configure systemd for low memory usage
    sudo mkdir -p /etc/systemd/system.conf.d
    sudo tee /etc/systemd/system.conf.d/adaptive-memory.conf > /dev/null << EOF
[Manager]
DefaultMemoryAccounting=yes
DefaultLimitNOFILE=65536
DefaultLimitMEMLOCK=infinity
EOF

    # Configure journald for minimal disk usage
    sudo mkdir -p /etc/systemd/journald.conf.d
    sudo tee /etc/systemd/journald.conf.d/adaptive-memory.conf > /dev/null << EOF
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=50M
MaxRetentionSec=1week
EOF

    echo_color "✅ Systemd configuré pour mémoire limitée" $GREEN
}

apply_standard_memory_optimizations() {
    echo_color "📈 Optimisations mémoire standard..." $BLUE

    configure_zram_swap
    configure_kernel_parameters_standard
    configure_systemd_standard
}

configure_kernel_parameters_standard() {
    sudo tee /etc/sysctl.d/99-adaptive-memory.conf > /dev/null << EOF
# Adaptive Ubuntu - Memory optimizations for standard tier

vm.swappiness=30
vm.dirty_ratio=20
vm.dirty_background_ratio=10
vm.vfs_cache_pressure=100

# Enhanced network settings
net.core.rmem_max=268435456
net.core.wmem_max=268435456
net.ipv4.tcp_rmem=4096 131072 268435456
net.ipv4.tcp_wmem=4096 131072 268435456

# Security
kernel.dmesg_restrict=1
kernel.kptr_restrict=1
EOF

    sudo sysctl -p /etc/sysctl.d/99-adaptive-memory.conf
}

configure_systemd_standard() {
    sudo tee /etc/systemd/system.conf.d/adaptive-memory.conf > /dev/null << EOF
[Manager]
DefaultMemoryAccounting=yes
DefaultLimitNOFILE=131072
DefaultLimitMEMLOCK=infinity
EOF

    sudo tee /etc/systemd/journald.conf.d/adaptive-memory.conf > /dev/null << EOF
[Journal]
SystemMaxUse=500M
RuntimeMaxUse=200M
MaxRetentionSec=2weeks
EOF
}

apply_performance_memory_optimizations() {
    echo_color "🚀 Optimisations mémoire performance..." $GREEN

    configure_zram_swap
    configure_kernel_parameters_performance
    configure_systemd_performance
}

configure_kernel_parameters_performance() {
    sudo tee /etc/sysctl.d/99-adaptive-memory.conf > /dev/null << EOF
# Adaptive Ubuntu - Memory optimizations for performance tier

vm.swappiness=60
vm.dirty_ratio=40
vm.dirty_background_ratio=20
vm.vfs_cache_pressure=100

# High performance network settings
net.core.rmem_max=536870912
net.core.wmem_max=536870912
net.ipv4.tcp_rmem=4096 262144 536870912
net.ipv4.tcp_wmem=4096 262144 536870912

# Security with performance
kernel.dmesg_restrict=1
kernel.kptr_restrict=1
EOF

    sudo sysctl -p /etc/sysctl.d/99-adaptive-memory.conf
}

configure_systemd_performance() {
    sudo tee /etc/systemd/system.conf.d/adaptive-memory.conf > /dev/null << EOF
[Manager]
DefaultMemoryAccounting=yes
DefaultLimitNOFILE=262144
DefaultLimitMEMLOCK=infinity
EOF

    sudo tee /etc/systemd/journald.conf.d/adaptive-memory.conf > /dev/null << EOF
[Journal]
SystemMaxUse=1G
RuntimeMaxUse=500M
MaxRetentionSec=1month
EOF
}

# ========== SERVICE CONFIGURATION ==========

configure_tier_services() {
    echo_color "⚙️  Configuration services par niveau..." $CYAN

    case "$SYSTEM_TIER" in
        "minimal")
            configure_minimal_services
            ;;
        "standard")
            configure_standard_services
            ;;
        "performance")
            configure_performance_services
            ;;
    esac
}

configure_minimal_services() {
    # Keep only essential services running
    local essential_services=(
        "ssh"
        "systemd-networkd"
        "systemd-resolved"
        "systemd-timesyncd"
        "cron"
    )

    enable_services "${essential_services[@]}"
}

configure_standard_services() {
    local standard_services=(
        "ssh"
        "systemd-networkd"
        "systemd-resolved"
        "systemd-timesyncd"
        "cron"
        "bluetooth"
        "cups"
    )

    enable_services "${standard_services[@]}"
}

configure_performance_services() {
    local performance_services=(
        "ssh"
        "systemd-networkd"
        "systemd-resolved"
        "systemd-timesyncd"
        "cron"
        "bluetooth"
        "cups"
        "docker"
    )

    enable_services "${performance_services[@]}"
}

enable_services() {
    local services=("$@")

    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            sudo systemctl enable "$service" 2>/dev/null || true
            echo_color "  ✅ Service activé: $service" $GREEN
        fi
    done
}

# ========== MONITORING SETUP ==========

setup_adaptive_monitoring() {
    echo_color "📊 Configuration surveillance adaptative..." $CYAN

    # Create monitoring service
    sudo tee /etc/systemd/system/adaptive-monitoring.service > /dev/null << EOF
[Unit]
Description=Adaptive Ubuntu Monitoring
After=multi-user.target

[Service]
Type=simple
User=$UTILISATEUR
ExecStart=$MON_SHELL_DIR/adaptive_monitoring.sh start $SYSTEM_TIER
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Enable monitoring service
    sudo systemctl enable adaptive-monitoring.service

    echo_color "✅ Surveillance adaptative configurée" $GREEN
}

# ========== INTEGRATION ==========

integrate_with_existing_setup() {
    echo_color "🔗 Intégration avec la configuration existante..." $CYAN

    # Add adaptive functions to existing aliases
    if [[ -f "$MON_SHELL_DIR/aliases.sh" ]]; then
        add_adaptive_aliases
    fi

    # Enhance existing functions with adaptive behavior
    enhance_existing_functions

    # Update shell configuration
    update_shell_configuration

    echo_color "✅ Intégration terminée" $GREEN
}

add_adaptive_aliases() {
    local aliases_file="$MON_SHELL_DIR/aliases.sh"
    local adaptive_aliases_section="
# ========== ADAPTIVE ALIASES ==========
# Generated by adaptive_ubuntu.sh

# System status
alias adaptive-status='$MON_SHELL_DIR/adaptive_monitoring.sh status'
alias adaptive-report='$MON_SHELL_DIR/adaptive_monitoring.sh report'

# Tool recommendations
alias adaptive-tools='$MON_SHELL_DIR/adaptive_tools.sh recommend'

# Quick tier info
alias tier='echo \$SYSTEM_TIER'
alias tier-info='$MON_SHELL_DIR/adaptive_detection.sh'
"

    # Add adaptive aliases if not already present
    if ! grep -q "ADAPTIVE ALIASES" "$aliases_file"; then
        echo "$adaptive_aliases_section" >> "$aliases_file"
        echo_color "  ✅ Aliases adaptatifs ajoutés" $GREEN
    fi
}

enhance_existing_functions() {
    # Create enhanced versions of existing functions
    local enhanced_functions_file="$MON_SHELL_DIR/adaptive_enhanced.sh"

    cat > "$enhanced_functions_file" << 'EOF'
#!/usr/bin/env bash
# Enhanced versions of existing functions with adaptive behavior

# Source original functions
[[ -f "${BASH_SOURCE[0]%/*}/functions_system.sh" ]] && source "${BASH_SOURCE[0]%/*}/functions_system.sh"

# Enhanced maj_ubuntu with tier awareness
adaptive_maj_ubuntu() {
    case "${SYSTEM_TIER:-standard}" in
        "minimal")
            echo_color "⚡ Mise à jour minimale..." $YELLOW
            sudo apt update && sudo apt upgrade -y
            sudo apt autoremove -y && sudo apt clean
            ;;
        "standard")
            echo_color "📈 Mise à jour standard..." $BLUE
            maj_ubuntu  # Call original function
            ;;
        "performance")
            echo_color "🚀 Mise à jour complète..." $GREEN
            maj_ubuntu
            # Additional optimizations for performance tier
            sudo apt autoremove --purge -y
            sync && echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null
            ;;
    esac
}

# Enhanced backup with adaptive strategy
adaptive_backup() {
    local backup_strategy="${TIER_BACKUP_STRATEGY:-local}"

    case "$backup_strategy" in
        "local")
            echo_color "💾 Sauvegarde locale..." $CYAN
            rsync -av --progress "$HOME/" "/backup/$(date +%Y%m%d)/"
            ;;
        "hybrid")
            echo_color "🔄 Sauvegarde hybride..." $BLUE
            # Local backup first, then cloud sync
            rsync -av --progress "$HOME/" "/backup/local/"
            # Add cloud backup command here
            ;;
        "cloud_hybrid")
            echo_color "☁️  Sauvegarde cloud hybride..." $GREEN
            # Advanced backup strategy
            restic backup --exclude-caches "$HOME"
            ;;
    esac
}

# Enhanced system monitoring
adaptive_system_check() {
    $MON_SHELL_DIR/adaptive_monitoring.sh report
}
EOF

    chmod +x "$enhanced_functions_file"
    echo_color "  ✅ Fonctions améliorées créées" $GREEN
}

update_shell_configuration() {
    # Add adaptive system loading to shell configuration
    local bashrc_addition="
# ========== ADAPTIVE UBUNTU SYSTEM ==========
# Auto-load adaptive system configuration

if [[ -f $ADAPTIVE_CONFIG_DIR/system.conf ]]; then
    # Load system tier information
    source <(grep -E '^(tier|ram_mb|cpu_cores)=' $ADAPTIVE_CONFIG_DIR/system.conf | sed 's/^/export SYSTEM_/')
fi

# Load adaptive modules
if [[ -d $MON_SHELL_DIR ]]; then
    source $MON_SHELL_DIR/adaptive_detection.sh
    source $MON_SHELL_DIR/adaptive_enhanced.sh 2>/dev/null || true
fi

# Display system tier on login
if [[ -n \$SYSTEM_TIER ]]; then
    echo -e \"\\033[0;36m🎯 Système Ubuntu adaptatif - Niveau: \$SYSTEM_TIER\\033[0m\"
fi
"

    # Add to user's bashrc if not already present
    if [[ -f "$DOSSIER_HOME/.bashrc" ]] && ! grep -q "ADAPTIVE UBUNTU SYSTEM" "$DOSSIER_HOME/.bashrc"; then
        echo "$bashrc_addition" >> "$DOSSIER_HOME/.bashrc"
        echo_color "  ✅ Configuration shell mise à jour" $GREEN
    fi
}

# ========== VALIDATION ==========

validate_adaptive_installation() {
    echo_color "🔍 Validation de l'installation adaptative..." $CYAN

    local validation_errors=0

    # Check if system tier is detected
    if [[ -z "$SYSTEM_TIER" ]]; then
        echo_color "❌ Niveau système non détecté" $RED
        ((validation_errors++))
    else
        echo_color "✅ Niveau système: $SYSTEM_TIER" $GREEN
    fi

    # Check if adaptive modules are loadable
    local modules=("adaptive_detection.sh" "adaptive_tools.sh" "adaptive_monitoring.sh")
    for module in "${modules[@]}"; do
        if [[ -f "$MON_SHELL_DIR/$module" ]]; then
            echo_color "✅ Module présent: $module" $GREEN
        else
            echo_color "❌ Module manquant: $module" $RED
            ((validation_errors++))
        fi
    done

    # Check if configuration files exist
    if [[ -f "$ADAPTIVE_CONFIG_DIR/system.conf" ]]; then
        echo_color "✅ Configuration système créée" $GREEN
    else
        echo_color "❌ Configuration système manquante" $RED
        ((validation_errors++))
    fi

    # Test monitoring functionality
    if $MON_SHELL_DIR/adaptive_monitoring.sh status &>/dev/null; then
        echo_color "✅ Surveillance fonctionnelle" $GREEN
    else
        echo_color "⚠️  Surveillance partiellement fonctionnelle" $YELLOW
    fi

    return $validation_errors
}

display_installation_summary() {
    echo_color "
📊 RÉSUMÉ INSTALLATION ADAPTATIVE" $MAGENTA
    echo_color "=================================" $MAGENTA
    echo_color "🎯 Niveau système: $SYSTEM_TIER" $CYAN
    echo_color "💾 RAM: ${SYSTEM_RAM_MB}MB" $CYAN
    echo_color "🖥️  CPU: ${SYSTEM_CPU_CORES} cores @ ${SYSTEM_CPU_MHZ}MHz" $CYAN
    echo_color "💿 Stockage: $SYSTEM_STORAGE_TYPE" $CYAN
    echo_color "📈 Score performance: $SYSTEM_PERFORMANCE_SCORE/100" $CYAN
    echo_color ""
    echo_color "⚙️  Configuration appliquée:" $CYAN
    echo_color "  - Swap ZRAM: $TIER_SWAP_SIZE" $CYAN
    echo_color "  - Mode services: $TIER_SERVICES_MODE" $CYAN
    echo_color "  - Surveillance: $TIER_MONITORING" $CYAN
    echo_color "  - Stratégie backup: $TIER_BACKUP_STRATEGY" $CYAN
    echo_color ""
    echo_color "🔧 Commandes utiles:" $CYAN
    echo_color "  adaptive-status    - Statut système" $CYAN
    echo_color "  adaptive-report    - Rapport détaillé" $CYAN
    echo_color "  adaptive-tools     - Recommandations outils" $CYAN
    echo_color "  tier               - Afficher niveau système" $CYAN
    echo_color ""
}

# ========== MAIN ACTIONS ==========

show_help() {
    echo_color "🎯 Système Ubuntu Adaptatif" $MAGENTA
    echo_color "===========================" $MAGENTA
    echo_color ""
    echo_color "Usage: sudo $0 [action]" $CYAN
    echo_color ""
    echo_color "Actions disponibles:" $CYAN
    echo_color "  install     - Installation complète du système adaptatif" $GREEN
    echo_color "  detect      - Détection et classification du système" $BLUE
    echo_color "  status      - Affichage du statut système" $BLUE
    echo_color "  monitor     - Démarrage surveillance continue" $BLUE
    echo_color "  tools       - Configuration outils adaptatifs" $BLUE
    echo_color "  optimize    - Application optimisations mémoire" $BLUE
    echo_color "  validate    - Validation installation" $BLUE
    echo_color "  help        - Affichage aide" $CYAN
    echo_color ""
    echo_color "Exemples:" $YELLOW
    echo_color "  sudo $0 install   # Installation complète" $YELLOW
    echo_color "  $0 status         # Statut système (sans sudo)" $YELLOW
    echo_color "  $0 detect         # Détection système" $YELLOW
    echo_color ""
}

# ========== MAIN EXECUTION ==========

main() {
    local action="${1:-help}"

    # Verify prerequisites for certain actions
    case "$action" in
        "install"|"optimize"|"tools")
            if [[ "$EUID" -ne 0 ]]; then
                echo_color "❌ Cette action nécessite sudo" $RED
                exit 1
            fi
            ;;
    esac

    # Execute action
    case "$action" in
        "install")
            adaptive_install
            ;;
        "detect")
            source_adaptive_modules
            detect_and_classify
            ;;
        "status")
            source_adaptive_modules
            quick_status
            ;;
        "monitor")
            source_adaptive_modules
            start_adaptive_monitoring
            ;;
        "tools")
            source_adaptive_modules
            setup_adaptive_tools
            ;;
        "optimize")
            source_adaptive_modules
            detect_and_classify
            apply_memory_optimizations
            ;;
        "validate")
            source_adaptive_modules
            detect_and_classify
            validate_adaptive_installation
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Execute main function if script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi