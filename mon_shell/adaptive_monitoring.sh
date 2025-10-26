#!/usr/bin/env bash
# --------------------------------------------------
# Adaptive Resource Monitoring and Emergency Response
# Real-time monitoring with tier-specific thresholds
# --------------------------------------------------

# Define colors directly for bash compatibility
VERT='\033[0;32m'
ROUGE='\033[0;31m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Source adaptive detection
[[ -f "${BASH_SOURCE[0]%/*}/adaptive_detection.sh" ]] && source "${BASH_SOURCE[0]%/*}/adaptive_detection.sh"

# ========== MONITORING CONFIGURATION ==========

# Memory thresholds by tier (percentage)
declare -A MEMORY_THRESHOLDS
MEMORY_THRESHOLDS[minimal_warning]=85
MEMORY_THRESHOLDS[minimal_critical]=95
MEMORY_THRESHOLDS[standard_warning]=80
MEMORY_THRESHOLDS[standard_critical]=90
MEMORY_THRESHOLDS[performance_warning]=75
MEMORY_THRESHOLDS[performance_critical]=85

# CPU thresholds by tier (percentage)
declare -A CPU_THRESHOLDS
CPU_THRESHOLDS[minimal_warning]=90
CPU_THRESHOLDS[minimal_critical]=98
CPU_THRESHOLDS[standard_warning]=85
CPU_THRESHOLDS[standard_critical]=95
CPU_THRESHOLDS[performance_warning]=80
CPU_THRESHOLDS[performance_critical]=90

# Load average thresholds (relative to CPU cores)
declare -A LOAD_THRESHOLDS
LOAD_THRESHOLDS[minimal_warning]=1.5
LOAD_THRESHOLDS[minimal_critical]=2.0
LOAD_THRESHOLDS[standard_warning]=2.0
LOAD_THRESHOLDS[standard_critical]=3.0
LOAD_THRESHOLDS[performance_warning]=2.5
LOAD_THRESHOLDS[performance_critical]=4.0

# Monitoring intervals by tier (seconds)
declare -A MONITOR_INTERVALS
MONITOR_INTERVALS[minimal]=60
MONITOR_INTERVALS[standard]=30
MONITOR_INTERVALS[performance]=15

# ========== SYSTEM METRICS COLLECTION ==========

collect_system_metrics() {
    # Memory metrics
    local memory_info=$(free -m)
    local total_memory=$(echo "$memory_info" | awk 'NR==2{print $2}')
    local used_memory=$(echo "$memory_info" | awk 'NR==2{print $3}')
    local available_memory=$(echo "$memory_info" | awk 'NR==2{print $7}')
    local memory_percent=$(( used_memory * 100 / total_memory ))

    # CPU metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_usage=${cpu_usage/,/.}  # Handle locale decimal separator

    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

    # Disk usage for root partition
    local disk_usage=$(df / | awk 'NR==2 {print $(NF-1)}' | sed 's/%//')

    # Swap usage
    local swap_total=$(echo "$memory_info" | awk 'NR==3{print $2}')
    local swap_used=$(echo "$memory_info" | awk 'NR==3{print $3}')
    local swap_percent=0
    if [[ $swap_total -gt 0 ]]; then
        swap_percent=$(( swap_used * 100 / swap_total ))
    fi

    # Process count
    local process_count=$(ps aux | wc -l)

    # Export metrics
    export CURRENT_MEMORY_PERCENT=$memory_percent
    export CURRENT_CPU_PERCENT=${cpu_usage:-0}
    export CURRENT_LOAD_AVG=$load_avg
    export CURRENT_DISK_PERCENT=$disk_usage
    export CURRENT_SWAP_PERCENT=$swap_percent
    export CURRENT_PROCESS_COUNT=$process_count
    export CURRENT_AVAILABLE_MEMORY_MB=$available_memory

    # Timestamp
    export METRICS_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
}

# ========== THRESHOLD MONITORING ==========

check_memory_thresholds() {
    local tier="${1:-$SYSTEM_TIER}"
    local warning_threshold=${MEMORY_THRESHOLDS[${tier}_warning]}
    local critical_threshold=${MEMORY_THRESHOLDS[${tier}_critical]}

    if [[ $CURRENT_MEMORY_PERCENT -ge $critical_threshold ]]; then
        trigger_memory_emergency "$CURRENT_MEMORY_PERCENT" "critical"
        return 2
    elif [[ $CURRENT_MEMORY_PERCENT -ge $warning_threshold ]]; then
        trigger_memory_alert "$CURRENT_MEMORY_PERCENT" "warning"
        return 1
    fi

    return 0
}

check_cpu_thresholds() {
    local tier="${1:-$SYSTEM_TIER}"
    local warning_threshold=${CPU_THRESHOLDS[${tier}_warning]}
    local critical_threshold=${CPU_THRESHOLDS[${tier}_critical]}

    # Convert to integer for comparison
    local cpu_int=$(echo "$CURRENT_CPU_PERCENT" | cut -d'.' -f1)

    if [[ $cpu_int -ge $critical_threshold ]]; then
        trigger_cpu_emergency "$CURRENT_CPU_PERCENT" "critical"
        return 2
    elif [[ $cpu_int -ge $warning_threshold ]]; then
        trigger_cpu_alert "$CURRENT_CPU_PERCENT" "warning"
        return 1
    fi

    return 0
}

check_load_thresholds() {
    local tier="${1:-$SYSTEM_TIER}"
    local warning_threshold=${LOAD_THRESHOLDS[${tier}_warning]}
    local critical_threshold=${LOAD_THRESHOLDS[${tier}_critical]}

    # Calculate threshold relative to CPU cores
    local cores="${SYSTEM_CPU_CORES:-1}"
    local warning_load=$(echo "$warning_threshold * $cores" | bc -l 2>/dev/null || echo "$warning_threshold")
    local critical_load=$(echo "$critical_threshold * $cores" | bc -l 2>/dev/null || echo "$critical_threshold")

    # Compare load average
    if command -v bc &>/dev/null; then
        if [[ $(echo "$CURRENT_LOAD_AVG >= $critical_load" | bc -l) -eq 1 ]]; then
            trigger_load_emergency "$CURRENT_LOAD_AVG" "critical"
            return 2
        elif [[ $(echo "$CURRENT_LOAD_AVG >= $warning_load" | bc -l) -eq 1 ]]; then
            trigger_load_alert "$CURRENT_LOAD_AVG" "warning"
            return 1
        fi
    else
        # Fallback without bc
        local load_int=$(echo "$CURRENT_LOAD_AVG" | cut -d'.' -f1)
        local warning_int=$(echo "$warning_load" | cut -d'.' -f1)
        local critical_int=$(echo "$critical_load" | cut -d'.' -f1)

        if [[ $load_int -ge $critical_int ]]; then
            trigger_load_emergency "$CURRENT_LOAD_AVG" "critical"
            return 2
        elif [[ $load_int -ge $warning_int ]]; then
            trigger_load_alert "$CURRENT_LOAD_AVG" "warning"
            return 1
        fi
    fi

    return 0
}

# ========== EMERGENCY RESPONSE FUNCTIONS ==========

trigger_memory_emergency() {
    local usage="$1" level="$2"

    echo_color "🚨 CRITIQUE: Mémoire à $usage%" $ROUGE
    logger "ADAPTIVE_UBUNTU: MEMORY CRITICAL - $usage%"

    # Emergency memory cleanup
    echo_color "🧹 Nettoyage d'urgence mémoire..." $JAUNE

    # Drop caches
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1

    # Kill memory-hungry processes if necessary
    if [[ $usage -ge 98 ]]; then
        kill_memory_hogs
    fi

    # Force garbage collection for known applications
    cleanup_application_memory

    # Log cleanup results
    sleep 2
    collect_system_metrics
    echo_color "📊 Mémoire après nettoyage: ${CURRENT_MEMORY_PERCENT}%" $CYAN
}

trigger_memory_alert() {
    local usage="$1" level="$2"

    echo_color "⚠️  ALERTE: Mémoire à $usage%" $JAUNE
    logger "ADAPTIVE_UBUNTU: MEMORY WARNING - $usage%"

    # Gentle cleanup
    sync && echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1

    # Suggest optimization
    echo_color "💡 Suggestion: Fermer applications non essentielles" $CYAN
}

trigger_cpu_emergency() {
    local usage="$1" level="$2"

    echo_color "🚨 CRITIQUE: CPU à $usage%" $ROUGE
    logger "ADAPTIVE_UBUNTU: CPU CRITICAL - $usage%"

    # Renice background processes
    renice_background_processes

    # Throttle non-essential services temporarily
    throttle_services "emergency"
}

trigger_cpu_alert() {
    local usage="$1" level="$2"

    echo_color "⚠️  ALERTE: CPU à $usage%" $JAUNE
    logger "ADAPTIVE_UBUNTU: CPU WARNING - $usage%"

    # Mild process optimization
    renice_background_processes "mild"
}

trigger_load_emergency() {
    local load="$1" level="$2"

    echo_color "🚨 CRITIQUE: Charge système $load" $ROUGE
    logger "ADAPTIVE_UBUNTU: LOAD CRITICAL - $load"

    # Comprehensive system optimization
    trigger_cpu_emergency "$load" "$level"
    trigger_memory_emergency "90" "$level"  # Assume high memory usage
}

trigger_load_alert() {
    local load="$1" level="$2"

    echo_color "⚠️  ALERTE: Charge système $load" $JAUNE
    logger "ADAPTIVE_UBUNTU: LOAD WARNING - $load"
}

# ========== EMERGENCY CLEANUP FUNCTIONS ==========

kill_memory_hogs() {
    echo_color "🔪 Identification des processus gourmands..." $ROUGE

    # Find processes using >100MB RAM (excluding system processes)
    local memory_hogs=$(ps aux --sort=-%mem | awk '
        NR>1 && $11!~/^\[/ && $4>5 &&
        $1!="root" && $11!~/systemd/ && $11!~/kernel/ {
        print $2":"$4":"$11
    }' | head -5)

    if [[ -n "$memory_hogs" ]]; then
        echo_color "🎯 Processus identifiés:" $CYAN
        while IFS=':' read -r pid mem cmd; do
            echo_color "  PID $pid: $cmd (${mem}%)" $JAUNE

            # Ask for confirmation in non-emergency situations
            if [[ $CURRENT_MEMORY_PERCENT -lt 98 ]]; then
                echo -n "Arrêter ce processus? [y/N]: "
                read -t 10 response
                [[ "$response" =~ ^[Yy] ]] && kill -TERM "$pid" 2>/dev/null
            else
                # Automatic kill in extreme situations
                echo_color "    ❌ Arrêt automatique" $ROUGE
                kill -TERM "$pid" 2>/dev/null
                sleep 2
                kill -KILL "$pid" 2>/dev/null
            fi
        done <<< "$memory_hogs"
    else
        echo_color "ℹ️  Aucun processus gourmand détecté" $CYAN
    fi
}

cleanup_application_memory() {
    echo_color "🧹 Nettoyage mémoire applications..." $CYAN

    # Clear browser caches if browsers are running
    pkill -USR1 firefox 2>/dev/null  # Force Firefox garbage collection
    pkill -USR1 chromium 2>/dev/null

    # Clear system caches
    sudo systemctl reload systemd-journald 2>/dev/null

    # Clear thumbnail caches
    [[ -d ~/.cache/thumbnails ]] && rm -rf ~/.cache/thumbnails/* 2>/dev/null

    # Clear temporary files
    sudo find /tmp -type f -atime +1 -delete 2>/dev/null || true
}

renice_background_processes() {
    local mode="${1:-normal}"

    echo_color "⚙️  Optimisation priorités processus..." $CYAN

    case "$mode" in
        "mild")
            # Gentle renicing
            sudo renice 5 $(pgrep -f backup) 2>/dev/null || true
            sudo renice 3 $(pgrep -f sync) 2>/dev/null || true
            ;;
        *)
            # More aggressive renicing
            sudo renice 10 $(pgrep -f backup) 2>/dev/null || true
            sudo renice 15 $(pgrep -f update) 2>/dev/null || true
            sudo renice 5 $(pgrep -f sync) 2>/dev/null || true
            ;;
    esac
}

throttle_services() {
    local mode="$1"

    echo_color "⏸️  Limitation services non essentiels..." $JAUNE

    case "$mode" in
        "emergency")
            # Temporarily stop resource-heavy services
            sudo systemctl stop snapd 2>/dev/null || true
            sudo systemctl stop update-notifier 2>/dev/null || true
            ;;
    esac
}

# ========== MONITORING LOOP ==========

start_adaptive_monitoring() {
    local tier="${1:-$SYSTEM_TIER}"
    local interval="${MONITOR_INTERVALS[$tier]:-30}"

    echo_color "🎯 Démarrage surveillance adaptative (niveau $tier)" $MAGENTA
    echo_color "🔄 Intervalle: ${interval}s" $CYAN

    # Ensure system classification
    [[ -z "$SYSTEM_TIER" ]] && classify_system_tier

    # Create monitoring log
    local log_file="/tmp/adaptive_monitoring_$$.log"
    echo "# Adaptive monitoring started at $(date)" > "$log_file"

    # Monitoring loop
    local iteration=0
    while true; do
        ((iteration++))

        # Collect current metrics
        collect_system_metrics

        # Check all thresholds
        local alerts=0
        check_memory_thresholds "$tier" || ((alerts++))
        check_cpu_thresholds "$tier" || ((alerts++))
        check_load_thresholds "$tier" || ((alerts++))

        # Log metrics every 10 iterations
        if [[ $((iteration % 10)) -eq 0 ]]; then
            log_system_metrics "$log_file"
        fi

        # Display status every iteration
        display_monitoring_status "$alerts"

        # Wait for next iteration
        sleep "$interval"
    done
}

log_system_metrics() {
    local log_file="$1"

    cat >> "$log_file" << EOF
$(date '+%Y-%m-%d %H:%M:%S') | MEM:${CURRENT_MEMORY_PERCENT}% | CPU:${CURRENT_CPU_PERCENT}% | LOAD:${CURRENT_LOAD_AVG} | DISK:${CURRENT_DISK_PERCENT}% | SWAP:${CURRENT_SWAP_PERCENT}%
EOF
}

display_monitoring_status() {
    local alerts="$1"

    # Color based on alert level
    local status_color=$VERT
    local status_text="NORMAL"

    if [[ $alerts -gt 0 ]]; then
        status_color=$JAUNE
        status_text="ALERTE"
        if [[ $alerts -gt 1 ]]; then
            status_color=$ROUGE
            status_text="CRITIQUE"
        fi
    fi

    # Clear line and show status
    printf "\r\033[K"
    printf "${status_color}[%s]${NC} 💾%s%% 🖥️ %s%% ⚖️ %s 💿%s%% 🔄%s" \
        "$status_text" \
        "$CURRENT_MEMORY_PERCENT" \
        "${CURRENT_CPU_PERCENT:-0}" \
        "$CURRENT_LOAD_AVG" \
        "$CURRENT_DISK_PERCENT" \
        "$CURRENT_SWAP_PERCENT"
}

# ========== MONITORING REPORTS ==========

generate_monitoring_report() {
    local tier="${1:-$SYSTEM_TIER}"

    echo_color "📊 RAPPORT SURVEILLANCE SYSTÈME" $MAGENTA
    echo_color "================================" $MAGENTA

    # Ensure fresh metrics
    collect_system_metrics

    echo_color "🕐 Timestamp: $METRICS_TIMESTAMP" $CYAN
    echo_color "🎯 Niveau système: $tier" $CYAN
    echo_color ""

    # Memory section
    echo_color "💾 MÉMOIRE" $BLEU
    echo_color "----------" $BLEU
    local mem_warning=${MEMORY_THRESHOLDS[${tier}_warning]}
    local mem_critical=${MEMORY_THRESHOLDS[${tier}_critical]}
    echo_color "Utilisation: ${CURRENT_MEMORY_PERCENT}% (Seuil alerte: ${mem_warning}%, critique: ${mem_critical}%)" $CYAN
    echo_color "Disponible: ${CURRENT_AVAILABLE_MEMORY_MB}MB" $CYAN

    # CPU section
    echo_color "
🖥️  PROCESSEUR" $BLEU
    echo_color "-----------" $BLEU
    local cpu_warning=${CPU_THRESHOLDS[${tier}_warning]}
    local cpu_critical=${CPU_THRESHOLDS[${tier}_critical]}
    echo_color "Utilisation: ${CURRENT_CPU_PERCENT}% (Seuil alerte: ${cpu_warning}%, critique: ${cpu_critical}%)" $CYAN
    echo_color "Charge moyenne: $CURRENT_LOAD_AVG" $CYAN

    # Storage section
    echo_color "
💿 STOCKAGE" $BLEU
    echo_color "---------" $BLEU
    echo_color "Utilisation racine: ${CURRENT_DISK_PERCENT}%" $CYAN
    echo_color "Swap: ${CURRENT_SWAP_PERCENT}%" $CYAN

    # Process section
    echo_color "
🔄 PROCESSUS" $BLEU
    echo_color "----------" $BLEU
    echo_color "Nombre total: $CURRENT_PROCESS_COUNT" $CYAN

    # Top memory consumers
    echo_color "
🔝 TOP CONSOMMATEURS MÉMOIRE" $BLEU
    echo_color "--------------------------" $BLEU
    ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %s: %s%% (%s)\n", $11, $4, $2}'

    echo_color ""
}

# ========== QUICK MONITORING FUNCTIONS ==========

quick_status() {
    collect_system_metrics
    local tier=$(quick_tier_check)

    printf "🎯%s 💾%s%% 🖥️ %s%% ⚖️ %s 💿%s%%\n" \
        "$tier" \
        "$CURRENT_MEMORY_PERCENT" \
        "${CURRENT_CPU_PERCENT:-0}" \
        "$CURRENT_LOAD_AVG" \
        "$CURRENT_DISK_PERCENT"
}

memory_status() {
    collect_system_metrics
    echo_color "💾 Mémoire: ${CURRENT_MEMORY_PERCENT}% utilisée, ${CURRENT_AVAILABLE_MEMORY_MB}MB disponible" $CYAN
}

# ========== MAIN FUNCTION ==========

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-status}" in
        "start")
            start_adaptive_monitoring "$2"
            ;;
        "status")
            quick_status
            ;;
        "report")
            generate_monitoring_report "$2"
            ;;
        "memory")
            memory_status
            ;;
        "test")
            # Test emergency functions
            echo_color "🧪 Test des fonctions d'urgence..." $JAUNE
            collect_system_metrics
            check_memory_thresholds
            check_cpu_thresholds
            check_load_thresholds
            ;;
        *)
            echo_color "Usage: $0 {start|status|report|memory|test} [tier]" $JAUNE
            echo_color "  start [tier]  - Démarrer surveillance continue" $CYAN
            echo_color "  status        - Afficher statut rapide" $CYAN
            echo_color "  report [tier] - Générer rapport complet" $CYAN
            echo_color "  memory        - Statut mémoire détaillé" $CYAN
            echo_color "  test          - Tester fonctions d'urgence" $CYAN
            ;;
    esac
fi