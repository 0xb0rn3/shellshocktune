#!/usr/bin/env bash

#==============================================================================
# Enhanced CPU Governor Management
# Handles intel_pstate, amd-pstate, and acpi-cpufreq drivers
# Author: 0xbv1 | 0xb0rn3
#==============================================================================

set -euo pipefail

GOVERNOR=${1:-schedutil}

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
RESET='\033[0m'

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[CPU-GOV]${RESET} $*"
    echo "[$timestamp] [CPU-GOV] $*" >> /var/log/shellshocktune.log 2>/dev/null || true
}

log_success() {
    echo -e "${GREEN}[CPU-GOV]${RESET} $*"
}

log_warning() {
    echo -e "${YELLOW}[CPU-GOV]${RESET} $*"
}

log_error() {
    echo -e "${RED}[CPU-GOV]${RESET} $*"
}

# Detect CPU scaling driver
detect_driver() {
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "unknown"
    else
        echo "none"
    fi
}

# Get available governors
get_available_governors() {
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Check if governor is available
is_governor_available() {
    local gov=$1
    local available=$(get_available_governors)
    [[ "$available" =~ $gov ]]
}

# Get current governor
get_current_governor() {
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown"
    else
        echo "none"
    fi
}

# Set governor for all CPUs
set_governor() {
    local gov=$1
    local success=0
    local total=0
    
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
            ((total++))
            if echo "$gov" > "$cpu" 2>/dev/null; then
                ((success++))
            else
                log_warning "Failed to set governor for $cpu"
            fi
        fi
    done
    
    if [[ $success -eq $total ]] && [[ $total -gt 0 ]]; then
        log_success "Set governor '$gov' on $success/$total CPUs"
        return 0
    elif [[ $success -gt 0 ]]; then
        log_warning "Partially set governor (applied to $success/$total CPUs)"
        return 0
    else
        log_error "Failed to set governor on any CPU"
        return 1
    fi
}

# Handle Intel pstate driver
handle_intel_pstate() {
    local requested=$1
    local target=""
    
    log "Intel pstate driver detected"
    
    case $requested in
        performance)
            target="performance"
            
            # Try to enable turbo boost
            if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
                local turbo_disabled=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
                if [[ "$turbo_disabled" == "1" ]]; then
                    echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null && \
                        log_success "Turbo boost enabled" || \
                        log_warning "Could not enable turbo boost"
                fi
            fi
            ;;
        ondemand|conservative)
            # Map to schedutil if available, otherwise powersave
            if is_governor_available "schedutil"; then
                target="schedutil"
                log "Mapping '$requested' to 'schedutil' (Intel recommendation)"
            else
                target="powersave"
                log "Mapping '$requested' to 'powersave'"
            fi
            ;;
        schedutil)
            if is_governor_available "schedutil"; then
                target="schedutil"
            else
                target="powersave"
                log "schedutil not available, using powersave"
            fi
            ;;
        powersave)
            target="powersave"
            ;;
        *)
            if is_governor_available "$requested"; then
                target="$requested"
            else
                log_warning "Governor '$requested' not available on Intel pstate"
                target="powersave"
            fi
            ;;
    esac
    
    set_governor "$target"
}

# Handle AMD pstate driver
handle_amd_pstate() {
    local requested=$1
    
    log "AMD pstate driver detected"
    
    # AMD pstate behavior is similar to Intel
    handle_intel_pstate "$requested"
}

# Handle ACPI cpufreq driver
handle_acpi_cpufreq() {
    local requested=$1
    
    log "ACPI cpufreq driver detected"
    
    if is_governor_available "$requested"; then
        set_governor "$requested"
    else
        log_warning "Governor '$requested' not available"
        
        # Fallback logic
        if is_governor_available "ondemand"; then
            log "Falling back to 'ondemand'"
            set_governor "ondemand"
        elif is_governor_available "schedutil"; then
            log "Falling back to 'schedutil'"
            set_governor "schedutil"
        elif is_governor_available "powersave"; then
            log "Falling back to 'powersave'"
            set_governor "powersave"
        else
            log_error "No suitable governor found"
            return 1
        fi
    fi
}

# Get CPU frequency info
get_frequency_info() {
    local cpu=0
    
    if [[ -f /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_cur_freq ]]; then
        local cur_freq=$(cat /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_cur_freq)
        local cur_mhz=$((cur_freq / 1000))
        echo "Current: ${cur_mhz} MHz"
    fi
    
    if [[ -f /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_min_freq ]]; then
        local min_freq=$(cat /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_min_freq)
        local min_mhz=$((min_freq / 1000))
        echo "Min: ${min_mhz} MHz"
    fi
    
    if [[ -f /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_max_freq ]]; then
        local max_freq=$(cat /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_max_freq)
        local max_mhz=$((max_freq / 1000))
        echo "Max: ${max_mhz} MHz"
    fi
}

# Main execution
main() {
    local driver=$(detect_driver)
    local available=$(get_available_governors)
    local current=$(get_current_governor)
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "CPU Scaling Driver: $driver"
    log "Available Governors: ${available:-none}"
    log "Current Governor: $current"
    log "Requested Governor: $GOVERNOR"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if cpufreq is available
    if [[ "$driver" == "none" ]] || [[ "$driver" == "unknown" ]]; then
        log_error "CPU frequency scaling not available on this system"
        log_error "Your CPU may not support frequency scaling or driver is not loaded"
        exit 1
    fi
    
    # Handle based on driver
    case $driver in
        intel_pstate|intel_cpufreq)
            handle_intel_pstate "$GOVERNOR"
            ;;
        amd-pstate|amd-pstate-epp)
            handle_amd_pstate "$GOVERNOR"
            ;;
        acpi-cpufreq)
            handle_acpi_cpufreq "$GOVERNOR"
            ;;
        *)
            log_warning "Unknown driver: $driver"
            log "Attempting direct governor setting..."
            
            if is_governor_available "$GOVERNOR"; then
                set_governor "$GOVERNOR"
            else
                log_error "Governor '$GOVERNOR' not available"
                log_error "Available governors: $available"
                exit 1
            fi
            ;;
    esac
    
    # Verify and show results
    local new_governor=$(get_current_governor)
    
    echo ""
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Governor Change Complete"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Previous: $current"
    log "Current:  $new_governor"
    echo ""
    
    # Show frequency info
    log "Frequency Information:"
    get_frequency_info | while read line; do
        log "  $line"
    done
    echo ""
    
    if [[ "$new_governor" != "$current" ]]; then
        log_success "Governor successfully changed!"
    else
        log_warning "Governor unchanged (may already be set)"
    fi
}

# Show help
show_help() {
    cat << EOF
Usage: $(basename $0) [GOVERNOR]

Set CPU frequency scaling governor for all CPU cores.

Available Governors (system-dependent):
  performance     - Run CPUs at maximum frequency
  powersave       - Energy efficient frequency scaling
  schedutil       - Scheduler-driven CPU frequency scaling
  ondemand        - Dynamic frequency scaling (older systems)
  conservative    - Gradual frequency scaling (older systems)
  userspace       - Manual frequency control

Examples:
  $(basename $0) performance    # Set to performance mode
  $(basename $0) schedutil      # Set to schedutil mode
  $(basename $0) powersave      # Set to powersave mode

Current System:
  Driver: $(detect_driver)
  Available: $(get_available_governors)
  Current: $(get_current_governor)

EOF
}

# Handle arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    log_error "Try: sudo $(basename $0) $GOVERNOR"
    exit 1
fi

# Trap errors
trap 'log_error "Script failed at line $LINENO"' ERR

main
