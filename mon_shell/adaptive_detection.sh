#!/usr/bin/env bash
# --------------------------------------------------
# Adaptive System Detection and Classification
# Part of the ubuntu-configs adaptive framework
# --------------------------------------------------

# Define colors directly for bash compatibility
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Echo with color support
echo_color() {
    echo -e "${2}${1}${NC}"
}

# ========== RESOURCE DETECTION ENGINE ==========

detect_system_resources() {
    echo_color "🔍 Détection des ressources système..." $BLEU

    # Memory detection (MB)
    local ram_mb=$(free -m | awk 'NR==2{printf "%.0f", $2}')

    # CPU information
    local cpu_cores=$(nproc)
    local cpu_mhz=$(lscpu | grep -E "(CPU MHz|cpu MHz)" | head -1 | awk '{print $NF}' | cut -d'.' -f1)
    [[ -z "$cpu_mhz" ]] && cpu_mhz=1000  # Fallback for ARM/other architectures

    # Storage type detection
    local storage_type="hdd"  # Default assumption
    local root_device=$(df / | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//' | sed 's|/dev/||')
    if [[ -f "/sys/block/${root_device}/queue/rotational" ]]; then
        local rotational=$(cat "/sys/block/${root_device}/queue/rotational" 2>/dev/null || echo "1")
        [[ "$rotational" == "0" ]] && storage_type="ssd"
    fi

    # Available space (GB)
    local available_space_gb=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')

    # Architecture detection
    local arch=$(uname -m)

    # Export system profile
    export SYSTEM_RAM_MB=$ram_mb
    export SYSTEM_CPU_CORES=$cpu_cores
    export SYSTEM_CPU_MHZ=$cpu_mhz
    export SYSTEM_STORAGE_TYPE=$storage_type
    export SYSTEM_AVAILABLE_GB=$available_space_gb
    export SYSTEM_ARCH=$arch

    # Calculate and export performance score
    local perf_score=$(calculate_performance_score $ram_mb $cpu_cores $cpu_mhz $storage_type)
    export SYSTEM_PERFORMANCE_SCORE=$perf_score

    echo_color "📊 RAM: ${ram_mb}MB | CPU: ${cpu_cores}c@${cpu_mhz}MHz | Storage: ${storage_type} | Espace: ${available_space_gb}GB" $CYAN
}

calculate_performance_score() {
    local ram=$1 cpu_cores=$2 cpu_mhz=$3 storage=$4
    local score=0

    # RAM contribution (40% of total score)
    if [[ $ram -ge 8192 ]]; then
        score=$((score + 40))
    elif [[ $ram -ge 4096 ]]; then
        score=$((score + 30))
    elif [[ $ram -ge 2048 ]]; then
        score=$((score + 20))
    elif [[ $ram -ge 1024 ]]; then
        score=$((score + 15))
    else
        score=$((score + 8))
    fi

    # CPU contribution (35% of total score)
    local cpu_power=$((cpu_cores * cpu_mhz / 1000))
    if [[ $cpu_power -ge 8 ]]; then
        score=$((score + 35))
    elif [[ $cpu_power -ge 6 ]]; then
        score=$((score + 28))
    elif [[ $cpu_power -ge 4 ]]; then
        score=$((score + 20))
    elif [[ $cpu_power -ge 2 ]]; then
        score=$((score + 12))
    else
        score=$((score + 5))
    fi

    # Storage contribution (15% of total score)
    if [[ "$storage" == "ssd" ]]; then
        score=$((score + 15))
    else
        score=$((score + 8))
    fi

    # Available space contribution (10% of total score)
    if [[ $SYSTEM_AVAILABLE_GB -ge 100 ]]; then
        score=$((score + 10))
    elif [[ $SYSTEM_AVAILABLE_GB -ge 50 ]]; then
        score=$((score + 7))
    elif [[ $SYSTEM_AVAILABLE_GB -ge 20 ]]; then
        score=$((score + 4))
    else
        score=$((score + 2))
    fi

    echo $score
}

# ========== TIER CLASSIFICATION ==========

classify_system_tier() {
    # Ensure resources are detected first
    [[ -z "$SYSTEM_PERFORMANCE_SCORE" ]] && detect_system_resources

    # Tier classification logic
    if [[ $SYSTEM_PERFORMANCE_SCORE -ge 70 ]]; then
        export SYSTEM_TIER="performance"
        export TIER_COLOR=$VERT
    elif [[ $SYSTEM_PERFORMANCE_SCORE -ge 40 ]]; then
        export SYSTEM_TIER="standard"
        export TIER_COLOR=$JAUNE
    else
        export SYSTEM_TIER="minimal"
        export TIER_COLOR=$ROUGE
    fi

    echo_color "🎯 Système classé: niveau $SYSTEM_TIER" $TIER_COLOR
    echo_color "📈 Score de performance: $SYSTEM_PERFORMANCE_SCORE/100" $CYAN

    # Set tier-specific configurations
    set_tier_defaults
}

set_tier_defaults() {
    case "$SYSTEM_TIER" in
        "minimal")
            export TIER_SWAP_SIZE="512M"
            export TIER_SERVICES_MODE="essential"
            export TIER_GUI_MODE="lightweight"
            export TIER_MONITORING="basic"
            export TIER_BACKUP_STRATEGY="local"
            ;;
        "standard")
            export TIER_SWAP_SIZE="1G"
            export TIER_SERVICES_MODE="selective"
            export TIER_GUI_MODE="balanced"
            export TIER_MONITORING="enhanced"
            export TIER_BACKUP_STRATEGY="hybrid"
            ;;
        "performance")
            export TIER_SWAP_SIZE="2G"
            export TIER_SERVICES_MODE="full"
            export TIER_GUI_MODE="optimized"
            export TIER_MONITORING="comprehensive"
            export TIER_BACKUP_STRATEGY="cloud_hybrid"
            ;;
    esac
}

# ========== COMPATIBILITY CHECKS ==========

check_adaptive_compatibility() {
    echo_color "🔍 Vérification compatibilité adaptative..." $BLEU

    local issues=0

    # Check if running as root when needed
    if [[ "$EUID" -eq 0 ]] && [[ -z "$SUDO_USER" ]]; then
        echo_color "⚠️  Exécution en root sans SUDO_USER" $JAUNE
        ((issues++))
    fi

    # Check for required commands
    local required_commands=("free" "nproc" "lscpu" "df" "uname")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo_color "❌ Commande manquante: $cmd" $ROUGE
            ((issues++))
        fi
    done

    # Check write permissions for adaptive configs
    local config_dir="/etc/adaptive-ubuntu"
    if [[ ! -d "$config_dir" ]] && ! mkdir -p "$config_dir" 2>/dev/null; then
        echo_color "⚠️  Impossible de créer $config_dir" $JAUNE
        ((issues++))
    fi

    if [[ $issues -eq 0 ]]; then
        echo_color "✅ Système compatible avec l'adaptation" $VERT
        return 0
    else
        echo_color "⚠️  $issues problèmes de compatibilité détectés" $JAUNE
        return 1
    fi
}

# ========== SYSTEM PROFILING ==========

create_system_profile() {
    local profile_file="/tmp/system_profile_$$.json"

    cat > "$profile_file" << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)",
    "distribution": "$(lsb_release -ds 2>/dev/null || echo 'Unknown')",
    "resources": {
        "ram_mb": $SYSTEM_RAM_MB,
        "cpu_cores": $SYSTEM_CPU_CORES,
        "cpu_mhz": $SYSTEM_CPU_MHZ,
        "storage_type": "$SYSTEM_STORAGE_TYPE",
        "available_gb": $SYSTEM_AVAILABLE_GB,
        "architecture": "$SYSTEM_ARCH"
    },
    "performance": {
        "score": $SYSTEM_PERFORMANCE_SCORE,
        "tier": "$SYSTEM_TIER"
    },
    "configuration": {
        "swap_size": "$TIER_SWAP_SIZE",
        "services_mode": "$TIER_SERVICES_MODE",
        "gui_mode": "$TIER_GUI_MODE",
        "monitoring": "$TIER_MONITORING",
        "backup_strategy": "$TIER_BACKUP_STRATEGY"
    }
}
EOF

    echo "$profile_file"
}

# ========== MAIN DETECTION FUNCTION ==========

detect_and_classify() {
    echo_color "🎯 Détection et classification adaptative" $MAGENTA
    echo_color "============================================" $MAGENTA

    # Run detection pipeline
    detect_system_resources
    classify_system_tier
    check_adaptive_compatibility

    # Create system profile
    local profile_file=$(create_system_profile)
    echo_color "📋 Profil système sauvé: $profile_file" $CYAN

    # Display summary
    display_system_summary
}

display_system_summary() {
    echo_color "
📊 RÉSUMÉ DU SYSTÈME" $MAGENTA
    echo_color "===================" $MAGENTA
    echo_color "🎯 Niveau: $SYSTEM_TIER ($SYSTEM_PERFORMANCE_SCORE/100)" $TIER_COLOR
    echo_color "💾 RAM: ${SYSTEM_RAM_MB}MB | CPU: ${SYSTEM_CPU_CORES}c@${SYSTEM_CPU_MHZ}MHz" $CYAN
    echo_color "💿 Stockage: $SYSTEM_STORAGE_TYPE | Espace: ${SYSTEM_AVAILABLE_GB}GB" $CYAN
    echo_color "⚙️  Configuration adaptée au niveau $SYSTEM_TIER" $VERT
    echo_color ""
}

# ========== UTILITY FUNCTIONS ==========

# Quick tier check without full detection
quick_tier_check() {
    local ram_mb=$(free -m | awk 'NR==2{printf "%.0f", $2}')

    if [[ $ram_mb -le 1024 ]]; then
        echo "minimal"
    elif [[ $ram_mb -le 4096 ]]; then
        echo "standard"
    else
        echo "performance"
    fi
}

# Export system variables for use by other scripts
export_system_vars() {
    [[ -z "$SYSTEM_TIER" ]] && classify_system_tier

    cat << EOF
export SYSTEM_RAM_MB=$SYSTEM_RAM_MB
export SYSTEM_CPU_CORES=$SYSTEM_CPU_CORES
export SYSTEM_CPU_MHZ=$SYSTEM_CPU_MHZ
export SYSTEM_STORAGE_TYPE=$SYSTEM_STORAGE_TYPE
export SYSTEM_AVAILABLE_GB=$SYSTEM_AVAILABLE_GB
export SYSTEM_ARCH=$SYSTEM_ARCH
export SYSTEM_PERFORMANCE_SCORE=$SYSTEM_PERFORMANCE_SCORE
export SYSTEM_TIER=$SYSTEM_TIER
export TIER_SWAP_SIZE=$TIER_SWAP_SIZE
export TIER_SERVICES_MODE=$TIER_SERVICES_MODE
export TIER_GUI_MODE=$TIER_GUI_MODE
export TIER_MONITORING=$TIER_MONITORING
export TIER_BACKUP_STRATEGY=$TIER_BACKUP_STRATEGY
EOF
}

# If script is called directly, run detection
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_and_classify
fi