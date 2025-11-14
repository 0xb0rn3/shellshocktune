#!/bin/bash

#==============================================================================
# ShellShockTune - Stage Application Script
# Handles all tuning logic for each stage
#==============================================================================

set -euo pipefail

STAGE=$1
TUNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$TUNER_DIR/modules"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

log() {
    local level=$1
    shift
    echo -e "${BLUE}[STAGE $STAGE]${RESET} $*"
}

#==============================================================================
# Module Functions
#==============================================================================

apply_cpu_governor() {
    local governor=$1
    log "Setting CPU governor to: $governor"
    
    if [[ -f "$MODULES_DIR/cpu-governor/cpu-governor" ]]; then
        "$MODULES_DIR/cpu-governor/cpu-governor" "$governor"
    else
        # Fallback manual method
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "$governor" > "$cpu" 2>/dev/null || true
        done
    fi
}

apply_kernel_params() {
    local -n params=$1
    log "Applying kernel parameters..."
    
    for key in "${!params[@]}"; do
        sysctl -w "${key}=${params[$key]}" &>/dev/null
        echo "${key} = ${params[$key]}" >> /etc/sysctl.d/99-shellshocktune.conf
    done
    
    sysctl -p /etc/sysctl.d/99-shellshocktune.conf &>/dev/null
}

apply_io_scheduler() {
    local scheduler=$1
    log "Setting I/O scheduler to: $scheduler"
    
    for disk in /sys/block/sd*/queue/scheduler /sys/block/nvme*/queue/scheduler; do
        if [[ -f "$disk" ]]; then
            echo "$scheduler" > "$disk" 2>/dev/null || true
        fi
    done
}

optimize_network_stack() {
    local level=$1
    log "Optimizing network stack (level $level)..."
    
    declare -A network_params
    
    case $level in
        1)  # Basic
            network_params=(
                ["net.core.rmem_max"]="16777216"
                ["net.core.wmem_max"]="16777216"
                ["net.ipv4.tcp_rmem"]="4096 87380 16777216"
                ["net.ipv4.tcp_wmem"]="4096 65536 16777216"
            )
            ;;
        2)  # Aggressive
            network_params=(
                ["net.core.rmem_max"]="67108864"
                ["net.core.wmem_max"]="67108864"
                ["net.core.netdev_max_backlog"]="10000"
                ["net.ipv4.tcp_rmem"]="4096 87380 67108864"
                ["net.ipv4.tcp_wmem"]="4096 65536 67108864"
                ["net.ipv4.tcp_congestion_control"]="bbr"
                ["net.ipv4.tcp_fastopen"]="3"
                ["net.ipv4.tcp_slow_start_after_idle"]="0"
            )
            ;;
        3)  # Extreme
            network_params=(
                ["net.core.rmem_max"]="134217728"
                ["net.core.wmem_max"]="134217728"
                ["net.core.netdev_max_backlog"]="50000"
                ["net.ipv4.tcp_rmem"]="4096 87380 134217728"
                ["net.ipv4.tcp_wmem"]="4096 65536 134217728"
                ["net.ipv4.tcp_congestion_control"]="bbr"
                ["net.ipv4.tcp_fastopen"]="3"
                ["net.ipv4.tcp_slow_start_after_idle"]="0"
                ["net.ipv4.tcp_mtu_probing"]="1"
                ["net.ipv4.tcp_timestamps"]="1"
                ["net.ipv4.tcp_window_scaling"]="1"
                ["net.ipv4.tcp_sack"]="1"
                ["net.core.default_qdisc"]="fq"
            )
            ;;
    esac
    
    apply_kernel_params network_params
}

optimize_memory() {
    local level=$1
    log "Optimizing memory management (level $level)..."
    
    declare -A memory_params
    
    case $level in
        1)  # Basic
            memory_params=(
                ["vm.swappiness"]="10"
                ["vm.dirty_ratio"]="15"
                ["vm.dirty_background_ratio"]="5"
            )
            ;;
        2)  # Performance
            memory_params=(
                ["vm.swappiness"]="1"
                ["vm.dirty_ratio"]="20"
                ["vm.dirty_background_ratio"]="3"
                ["vm.vfs_cache_pressure"]="50"
                ["vm.min_free_kbytes"]="65536"
            )
            ;;
        3)  # Extreme
            memory_params=(
                ["vm.swappiness"]="0"
                ["vm.dirty_ratio"]="30"
                ["vm.dirty_background_ratio"]="2"
                ["vm.vfs_cache_pressure"]="40"
                ["vm.min_free_kbytes"]="131072"
                ["vm.zone_reclaim_mode"]="0"
                ["vm.page-cluster"]="3"
            )
            ;;
    esac
    
    apply_kernel_params memory_params
}

enable_performance_features() {
    log "Enabling performance features..."
    
    # Disable CPU mitigations (extreme performance)
    if ! grep -q "mitigations=off" /etc/default/grub 2>/dev/null; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&mitigations=off /' /etc/default/grub
        update-grub 2>/dev/null || grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
    fi
    
    # Enable transparent huge pages
    echo always > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
    
    # Disable watchdog (saves CPU cycles)
    echo 0 > /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
}

install_wireless_tools() {
    log "Installing wireless penetration testing tools..."
    
    # Detect distribution and install appropriate packages
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        
        case $ID in
            arch|archcraft|manjaro)
                pacman -S --noconfirm aircrack-ng wifite reaver bully pixiewps wireshark-cli tcpdump 2>/dev/null || true
                ;;
            debian|ubuntu|kali)
                apt-get install -y aircrack-ng wifite reaver bully pixiewps wireshark tcpdump 2>/dev/null || true
                ;;
            fedora|rhel)
                dnf install -y aircrack-ng wifite reaver bully wireshark-cli tcpdump 2>/dev/null || true
                ;;
        esac
    fi
    
    # Enable monitor mode support
    modprobe mac80211 2>/dev/null || true
}

enable_redteam_modules() {
    log "Enabling red team kernel modules..."
    
    # Wireless modules
    local wireless_modules=(
        "ath9k"
        "ath9k_htc"
        "rtl8xxxu"
        "rt2800usb"
        "mt76x0u"
        "cfg80211"
        "mac80211"
    )
    
    for module in "${wireless_modules[@]}"; do
        modprobe "$module" 2>/dev/null || true
    done
    
    # Network analysis modules
    modprobe nfnetlink 2>/dev/null || true
    modprobe nfnetlink_queue 2>/dev/null || true
    
    # USB modules for hardware attacks
    modprobe usbmon 2>/dev/null || true
    
    log "Red team modules loaded"
}

optimize_thermal() {
    log "Configuring thermal management..."
    
    # Set performance thermal governor if available
    for policy in /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference; do
        if [[ -f "$policy" ]]; then
            echo performance > "$policy" 2>/dev/null || true
        fi
    done
    
    # Disable laptop mode
    echo 0 > /proc/sys/vm/laptop_mode 2>/dev/null || true
}

#==============================================================================
# Stage Implementations
#==============================================================================

apply_stage_0() {
    log "Restoring stock configuration..."
    
    # Remove custom sysctl
    rm -f /etc/sysctl.d/99-shellshocktune.conf
    
    # Reset to default governor
    apply_cpu_governor "schedutil"
    
    # Reset I/O scheduler
    apply_io_scheduler "mq-deadline"
    
    log "Stock configuration restored"
}

apply_stage_1() {
    log "Applying Stage 1: Optimized (Safe tweaks)"
    
    # CPU governor: balanced
    apply_cpu_governor "ondemand"
    
    # I/O scheduler: performance-oriented
    apply_io_scheduler "bfq"
    
    # Basic memory optimization
    optimize_memory 1
    
    # Basic network optimization
    optimize_network_stack 1
    
    log "Stage 1 applied successfully"
}

apply_stage_2() {
    log "Applying Stage 2: Performance (Aggressive)"
    
    # CPU governor: performance
    apply_cpu_governor "performance"
    
    # I/O scheduler: high performance
    apply_io_scheduler "kyber"
    
    # Aggressive memory optimization
    optimize_memory 2
    
    # Aggressive network optimization
    optimize_network_stack 2
    
    # Thermal optimization
    optimize_thermal
    
    log "Stage 2 applied successfully"
}

apply_stage_3() {
    log "Applying Stage 3: Extreme (Maximum performance)"
    
    # CPU governor: maximum performance
    apply_cpu_governor "performance"
    
    # I/O scheduler: none (direct submission)
    apply_io_scheduler "none"
    
    # Extreme memory optimization
    optimize_memory 3
    
    # Extreme network optimization
    optimize_network_stack 3
    
    # Enable all performance features
    enable_performance_features
    
    # Thermal management
    optimize_thermal
    
    # Additional extreme tweaks
    declare -A extreme_params=(
        ["kernel.sched_migration_cost_ns"]="5000000"
        ["kernel.sched_autogroup_enabled"]="0"
        ["kernel.sched_latency_ns"]="10000000"
        ["kernel.sched_min_granularity_ns"]="3000000"
        ["kernel.sched_wakeup_granularity_ns"]="4000000"
    )
    apply_kernel_params extreme_params
    
    log "Stage 3 applied successfully"
}

apply_stage_4() {
    log "Applying Stage 4: Redteam (Extreme + Security tools)"
    
    # Apply Stage 3 first
    apply_stage_3
    
    # Install wireless tools
    install_wireless_tools
    
    # Enable red team modules
    enable_redteam_modules
    
    # Network capture optimizations
    declare -A capture_params=(
        ["net.core.rmem_default"]="134217728"
        ["net.core.wmem_default"]="134217728"
        ["net.ipv4.tcp_timestamps"]="1"
        ["net.ipv4.tcp_tw_reuse"]="1"
        ["net.ipv4.ip_local_port_range"]="1024 65535"
        ["net.netfilter.nf_conntrack_max"]="1048576"
    )
    apply_kernel_params capture_params
    
    # Enable packet capture
    chmod 755 /usr/bin/dumpcap 2>/dev/null || true
    setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap 2>/dev/null || true
    
    log "Stage 4 (Redteam) applied successfully"
}

#==============================================================================
# Main Execution
#==============================================================================

case $STAGE in
    0)
        apply_stage_0
        ;;
    1)
        apply_stage_1
        ;;
    2)
        apply_stage_2
        ;;
    3)
        apply_stage_3
        ;;
    4)
        apply_stage_4
        ;;
    *)
        echo "Invalid stage: $STAGE"
        exit 1
        ;;
esac

log "Stage $STAGE completed successfully"