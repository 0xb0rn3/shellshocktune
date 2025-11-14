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
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [STAGE $STAGE] $*" | tee -a /var/log/shellshocktune.log
    echo -e "${BLUE}[STAGE $STAGE]${RESET} $*"
}

#==============================================================================
# Module Functions
#==============================================================================

apply_cpu_governor() {
    local governor=$1
    log "Setting CPU governor to: $governor"
    
    # Detect CPU driver
    local driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "unknown")
    local available=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")
    
    log "CPU driver: $driver, Available governors: $available"
    
    # Map requested governor to available ones
    local target_governor="$governor"
    
    case $driver in
        intel_pstate|intel_cpufreq)
            # Intel systems typically only have performance/powersave
            case $governor in
                performance)
                    target_governor="performance"
                    # Enable turbo boost
                    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
                        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
                        log "Turbo boost enabled"
                    fi
                    ;;
                ondemand|schedutil|conservative)
                    # Map to schedutil if available, otherwise powersave
                    if [[ "$available" =~ schedutil ]]; then
                        target_governor="schedutil"
                    else
                        target_governor="powersave"
                    fi
                    ;;
                powersave)
                    target_governor="powersave"
                    ;;
            esac
            ;;
        acpi-cpufreq|amd-pstate|amd-pstate-epp)
            # AMD and older systems have more governors
            if [[ ! "$available" =~ $governor ]]; then
                log "Governor $governor not available, trying fallback..."
                if [[ "$available" =~ ondemand ]]; then
                    target_governor="ondemand"
                elif [[ "$available" =~ schedutil ]]; then
                    target_governor="schedutil"
                else
                    target_governor="powersave"
                fi
            fi
            ;;
    esac
    
    # Try enhanced script first
    if [[ -f "$MODULES_DIR/cpu-governor/set-governor.sh" ]]; then
        bash "$MODULES_DIR/cpu-governor/set-governor.sh" "$target_governor" || {
            log "Enhanced script failed, trying fallback..."
            manual_set_governor "$target_governor"
        }
    # Try compiled binary
    elif [[ -f "$MODULES_DIR/cpu-governor/cpu-governor" ]]; then
        "$MODULES_DIR/cpu-governor/cpu-governor" "$target_governor" 2>/dev/null || {
            log "Binary failed, trying fallback..."
            manual_set_governor "$target_governor"
        }
    else
        # Fallback manual method
        manual_set_governor "$target_governor"
    fi
    
    # Verify
    local current=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    log "Active governor: $current"
}

manual_set_governor() {
    local governor=$1
    local success=0
    local total=0
    
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
            ((total++))
            if echo "$governor" > "$cpu" 2>/dev/null; then
                ((success++))
            fi
        fi
    done
    
    if [[ $success -gt 0 ]]; then
        log "Set governor '$governor' on $success/$total CPUs"
        return 0
    else
        log "Failed to set governor on any CPU"
        return 1
    fi
}

apply_kernel_params() {
    local -n params=$1
    log "Applying kernel parameters..."
    
    # Create/clear the config file
    > /etc/sysctl.d/99-shellshocktune.conf
    
    for key in "${!params[@]}"; do
        # Skip nf_conntrack if module not loaded
        if [[ "$key" =~ nf_conntrack ]] && ! lsmod | grep -q nf_conntrack; then
            modprobe nf_conntrack 2>/dev/null || {
                log "Skipping $key (nf_conntrack not available)"
                continue
            }
        fi
        
        if sysctl -w "${key}=${params[$key]}" &>/dev/null; then
            echo "${key} = ${params[$key]}" >> /etc/sysctl.d/99-shellshocktune.conf
        else
            log "Warning: Failed to set ${key}=${params[$key]}"
        fi
    done
    
    sysctl -p /etc/sysctl.d/99-shellshocktune.conf &>/dev/null || true
}

apply_io_scheduler() {
    local scheduler=$1
    log "Setting I/O scheduler to: $scheduler"
    
    for disk in /sys/block/*/queue/scheduler; do
        if [[ -f "$disk" ]]; then
            local available=$(cat "$disk")
            
            # Check if requested scheduler is available
            if [[ "$available" =~ \[$scheduler\] ]] || [[ "$available" =~ $scheduler ]]; then
                echo "$scheduler" > "$disk" 2>/dev/null && \
                    log "Set scheduler for $(dirname $(dirname $disk)): $scheduler" || \
                    log "Failed to set scheduler for $(dirname $(dirname $disk))"
            else
                log "Scheduler $scheduler not available for $(dirname $(dirname $disk))"
                log "Available: $available"
            fi
        fi
    done
}

optimize_network_stack() {
    local level=$1
    log "Optimizing network stack (level $level)..."
    
    declare -A network_params
    
    case $level in
        1)  # Basic - 16MB buffers
            network_params=(
                ["net.core.rmem_max"]="16777216"
                ["net.core.wmem_max"]="16777216"
                ["net.core.rmem_default"]="1048576"
                ["net.core.wmem_default"]="1048576"
                ["net.ipv4.tcp_rmem"]="4096 87380 16777216"
                ["net.ipv4.tcp_wmem"]="4096 65536 16777216"
                ["net.core.netdev_max_backlog"]="5000"
                ["net.ipv4.tcp_window_scaling"]="1"
                ["net.ipv4.tcp_timestamps"]="1"
                ["net.ipv4.tcp_sack"]="1"
            )
            ;;
        2)  # Aggressive - 64MB buffers + BBR
            network_params=(
                ["net.core.rmem_max"]="67108864"
                ["net.core.wmem_max"]="67108864"
                ["net.core.rmem_default"]="8388608"
                ["net.core.wmem_default"]="8388608"
                ["net.core.netdev_max_backlog"]="10000"
                ["net.ipv4.tcp_rmem"]="4096 87380 67108864"
                ["net.ipv4.tcp_wmem"]="4096 65536 67108864"
                ["net.ipv4.tcp_congestion_control"]="bbr"
                ["net.ipv4.tcp_fastopen"]="3"
                ["net.ipv4.tcp_slow_start_after_idle"]="0"
                ["net.ipv4.tcp_tw_reuse"]="1"
                ["net.ipv4.tcp_window_scaling"]="1"
                ["net.ipv4.tcp_timestamps"]="1"
                ["net.ipv4.tcp_sack"]="1"
                ["net.core.default_qdisc"]="fq"
            )
            
            # Load BBR module
            modprobe tcp_bbr 2>/dev/null || log "Warning: BBR module not available"
            ;;
        3)  # Extreme - 128MB buffers
            network_params=(
                ["net.core.rmem_max"]="134217728"
                ["net.core.wmem_max"]="134217728"
                ["net.core.rmem_default"]="16777216"
                ["net.core.wmem_default"]="16777216"
                ["net.core.netdev_max_backlog"]="50000"
                ["net.core.netdev_budget"]="50000"
                ["net.core.netdev_budget_usecs"]="5000"
                ["net.ipv4.tcp_rmem"]="4096 87380 134217728"
                ["net.ipv4.tcp_wmem"]="4096 65536 134217728"
                ["net.ipv4.tcp_congestion_control"]="bbr"
                ["net.ipv4.tcp_fastopen"]="3"
                ["net.ipv4.tcp_slow_start_after_idle"]="0"
                ["net.ipv4.tcp_mtu_probing"]="1"
                ["net.ipv4.tcp_timestamps"]="1"
                ["net.ipv4.tcp_window_scaling"]="1"
                ["net.ipv4.tcp_sack"]="1"
                ["net.ipv4.tcp_tw_reuse"]="1"
                ["net.ipv4.tcp_fin_timeout"]="15"
                ["net.ipv4.tcp_keepalive_time"]="300"
                ["net.ipv4.tcp_keepalive_probes"]="5"
                ["net.ipv4.tcp_keepalive_intvl"]="15"
                ["net.core.default_qdisc"]="fq"
            )
            
            modprobe tcp_bbr 2>/dev/null || log "Warning: BBR module not available"
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
                ["vm.vfs_cache_pressure"]="100"
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
            
            # Enable transparent huge pages
            if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
                echo always > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
                log "Transparent huge pages enabled"
            fi
            ;;
    esac
    
    apply_kernel_params memory_params
}

enable_performance_features() {
    log "Enabling performance features..."
    
    # Disable CPU mitigations (extreme performance)
    if [[ -f /etc/default/grub ]]; then
        if ! grep -q "mitigations=off" /etc/default/grub 2>/dev/null; then
            sed -i.bak 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 mitigations=off"/' /etc/default/grub
            log "Added mitigations=off to GRUB (reboot required)"
            
            # Update GRUB
            if command -v update-grub &>/dev/null; then
                update-grub 2>/dev/null || true
            elif command -v grub-mkconfig &>/dev/null; then
                grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            fi
        fi
    fi
    
    # Disable watchdog (saves CPU cycles)
    if [[ -f /proc/sys/kernel/nmi_watchdog ]]; then
        echo 0 > /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
        log "NMI watchdog disabled"
    fi
    
    # Scheduler tuning
    declare -A sched_params=(
        ["kernel.sched_migration_cost_ns"]="5000000"
        ["kernel.sched_autogroup_enabled"]="0"
    )
    
    if [[ -f /proc/sys/kernel/sched_latency_ns ]]; then
        sched_params["kernel.sched_latency_ns"]="10000000"
        sched_params["kernel.sched_min_granularity_ns"]="3000000"
        sched_params["kernel.sched_wakeup_granularity_ns"]="4000000"
    fi
    
    apply_kernel_params sched_params
}

install_wireless_tools() {
    log "Installing wireless penetration testing tools..."
    
    # Detect distribution and install appropriate packages
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        
        case $ID in
            arch|archcraft|manjaro)
                pacman -S --noconfirm --needed aircrack-ng wifite reaver bully pixiewps wireshark-cli tcpdump 2>/dev/null || \
                    log "Warning: Some wireless tools may have failed to install"
                ;;
            debian|ubuntu|kali)
                apt-get update &>/dev/null
                apt-get install -y aircrack-ng wifite reaver bully pixiewps wireshark tcpdump 2>/dev/null || \
                    log "Warning: Some wireless tools may have failed to install"
                ;;
            fedora|rhel|centos|rocky|alma)
                dnf install -y aircrack-ng wifite reaver bully wireshark-cli tcpdump 2>/dev/null || \
                    log "Warning: Some wireless tools may have failed to install"
                ;;
            *)
                log "Warning: Unknown distribution, skipping wireless tools installation"
                ;;
        esac
    fi
}

enable_redteam_modules() {
    log "Enabling red team kernel modules..."
    
    # Wireless modules
    local wireless_modules=(
        "mac80211"
        "cfg80211"
        "ath9k"
        "ath9k_htc"
        "rtl8xxxu"
        "rt2800usb"
        "mt76x0u"
    )
    
    for module in "${wireless_modules[@]}"; do
        if modprobe "$module" 2>/dev/null; then
            log "Loaded module: $module"
        else
            log "Warning: Could not load module $module"
        fi
    done
    
    # Network analysis modules
    modprobe nfnetlink 2>/dev/null || true
    modprobe nfnetlink_queue 2>/dev/null || true
    
    # USB modules for hardware attacks
    modprobe usbmon 2>/dev/null || true
    
    log "Red team modules processing complete"
}

optimize_thermal() {
    log "Configuring thermal management..."
    
    # Set performance thermal governor if available
    for policy in /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference; do
        if [[ -f "$policy" ]]; then
            echo performance > "$policy" 2>/dev/null && \
                log "Set energy performance preference to performance" || \
                log "Could not set energy performance preference"
        fi
    done
    
    # Disable laptop mode
    if [[ -f /proc/sys/vm/laptop_mode ]]; then
        echo 0 > /proc/sys/vm/laptop_mode 2>/dev/null || true
        log "Laptop mode disabled"
    fi
}

optimize_for_redteam() {
    log "Applying redteam-specific optimizations..."
    
    declare -A redteam_params=(
        ["net.netfilter.nf_conntrack_max"]="2097152"
        ["net.ipv4.tcp_syn_retries"]="2"
        ["net.ipv4.tcp_synack_retries"]="2"
        ["net.ipv4.tcp_fin_timeout"]="10"
        ["net.ipv4.ip_forward"]="1"
        ["net.ipv6.conf.all.forwarding"]="1"
        ["net.ipv4.conf.all.accept_redirects"]="0"
        ["net.ipv6.conf.all.accept_redirects"]="0"
        ["net.ipv4.conf.all.send_redirects"]="0"
        ["net.ipv4.conf.all.rp_filter"]="1"
        ["net.ipv4.ip_local_port_range"]="1024 65535"
    )
    
    apply_kernel_params redteam_params
    
    # Enable packet capture capabilities
    if command -v setcap &>/dev/null; then
        for tool in /usr/bin/dumpcap /usr/sbin/tcpdump; do
            if [[ -f "$tool" ]]; then
                setcap cap_net_raw,cap_net_admin=eip "$tool" 2>/dev/null && \
                    log "Set capabilities for $(basename $tool)" || \
                    log "Warning: Could not set capabilities for $(basename $tool)"
            fi
        done
    fi
}

#==============================================================================
# Stage Implementations
#==============================================================================

apply_stage_0() {
    log "Restoring stock configuration..."
    
    # Remove custom sysctl
    rm -f /etc/sysctl.d/99-shellshocktune.conf
    
    # Reset to default governor (schedutil or powersave)
    local driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "unknown")
    
    case $driver in
        intel_pstate|intel_cpufreq)
            apply_cpu_governor "schedutil"
            ;;
        *)
            apply_cpu_governor "schedutil"
            ;;
    esac
    
    # Reset I/O scheduler to default
    apply_io_scheduler "mq-deadline"
    
    # Reload default sysctl
    sysctl -p &>/dev/null || true
    
    log "Stock configuration restored"
}

apply_stage_1() {
    log "Applying Stage 1: Optimized (Safe tweaks)"
    
    # CPU governor: balanced
    apply_cpu_governor "schedutil"
    
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
    
    # Apply redteam-specific optimizations
    optimize_for_redteam
    
    log "Stage 4 (Redteam) applied successfully"
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
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
    echo ""
    echo -e "${GREEN}Stage $STAGE applied!${RESET}"
    echo -e "${YELLOW}A reboot is recommended for all changes to take full effect.${RESET}"
    echo ""
}

# Trap errors
trap 'log "ERROR at line $LINENO: Command failed with exit code $?"' ERR

main
