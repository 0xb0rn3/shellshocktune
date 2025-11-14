#!/bin/bash

#==============================================================================
# ShellShockTune - Network Stack Optimization Module
# Optimizes TCP/IP stack for different performance profiles
#==============================================================================

MODULE_NAME="network"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="0xbv1 | 0xb0rn3"
MODULE_DESCRIPTION="TCP/IP stack and network buffer optimization"

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

log() {
    local level=$1
    shift
    echo -e "${BLUE}[NETWORK $level]${RESET} $*"
}

write_sysctl() {
    local key=$1
    local value=$2
    
    sysctl -w "${key}=${value}" &>/dev/null || {
        log ERROR "Failed to set ${key}=${value}"
        return 1
    }
    
    echo "${key} = ${value}" >> /etc/sysctl.d/99-shellshocktune-network.conf
    log INFO "Set ${key} = ${value}"
}

enable_bbr() {
    log INFO "Enabling BBR congestion control..."
    
    # Load BBR module
    modprobe tcp_bbr 2>/dev/null || {
        log WARNING "BBR module not available"
        return 1
    }
    
    # Set BBR as default
    write_sysctl "net.ipv4.tcp_congestion_control" "bbr"
    write_sysctl "net.core.default_qdisc" "fq"
    
    log SUCCESS "BBR enabled"
}

optimize_tcp_buffers() {
    local level=$1
    
    log INFO "Optimizing TCP buffers (level $level)..."
    
    case $level in
        1)  # 16MB buffers
            write_sysctl "net.core.rmem_max" "16777216"
            write_sysctl "net.core.wmem_max" "16777216"
            write_sysctl "net.core.rmem_default" "1048576"
            write_sysctl "net.core.wmem_default" "1048576"
            write_sysctl "net.ipv4.tcp_rmem" "4096 87380 16777216"
            write_sysctl "net.ipv4.tcp_wmem" "4096 65536 16777216"
            ;;
        2)  # 64MB buffers
            write_sysctl "net.core.rmem_max" "67108864"
            write_sysctl "net.core.wmem_max" "67108864"
            write_sysctl "net.core.rmem_default" "8388608"
            write_sysctl "net.core.wmem_default" "8388608"
            write_sysctl "net.ipv4.tcp_rmem" "4096 87380 67108864"
            write_sysctl "net.ipv4.tcp_wmem" "4096 65536 67108864"
            ;;
        3)  # 128MB buffers
            write_sysctl "net.core.rmem_max" "134217728"
            write_sysctl "net.core.wmem_max" "134217728"
            write_sysctl "net.core.rmem_default" "16777216"
            write_sysctl "net.core.wmem_default" "16777216"
            write_sysctl "net.ipv4.tcp_rmem" "4096 87380 134217728"
            write_sysctl "net.ipv4.tcp_wmem" "4096 65536 134217728"
            ;;
    esac
    
    log SUCCESS "TCP buffers optimized"
}

optimize_tcp_stack() {
    local level=$1
    
    log INFO "Optimizing TCP stack (level $level)..."
    
    # Basic optimizations (all levels)
    write_sysctl "net.ipv4.tcp_window_scaling" "1"
    write_sysctl "net.ipv4.tcp_timestamps" "1"
    write_sysctl "net.ipv4.tcp_sack" "1"
    
    case $level in
        1)
            write_sysctl "net.core.netdev_max_backlog" "5000"
            write_sysctl "net.ipv4.tcp_fastopen" "3"
            ;;
        2)
            write_sysctl "net.core.netdev_max_backlog" "10000"
            write_sysctl "net.ipv4.tcp_fastopen" "3"
            write_sysctl "net.ipv4.tcp_slow_start_after_idle" "0"
            write_sysctl "net.ipv4.tcp_tw_reuse" "1"
            ;;
        3)
            write_sysctl "net.core.netdev_max_backlog" "50000"
            write_sysctl "net.core.netdev_budget" "50000"
            write_sysctl "net.core.netdev_budget_usecs" "5000"
            write_sysctl "net.ipv4.tcp_fastopen" "3"
            write_sysctl "net.ipv4.tcp_slow_start_after_idle" "0"
            write_sysctl "net.ipv4.tcp_tw_reuse" "1"
            write_sysctl "net.ipv4.tcp_mtu_probing" "1"
            write_sysctl "net.ipv4.tcp_fin_timeout" "15"
            write_sysctl "net.ipv4.tcp_keepalive_time" "300"
            write_sysctl "net.ipv4.tcp_keepalive_probes" "5"
            write_sysctl "net.ipv4.tcp_keepalive_intvl" "15"
            ;;
    esac
    
    log SUCCESS "TCP stack optimized"
}

optimize_udp() {
    local level=$1
    
    log INFO "Optimizing UDP (level $level)..."
    
    case $level in
        1)
            write_sysctl "net.ipv4.udp_rmem_min" "8192"
            write_sysctl "net.ipv4.udp_wmem_min" "8192"
            ;;
        2|3)
            write_sysctl "net.ipv4.udp_rmem_min" "16384"
            write_sysctl "net.ipv4.udp_wmem_min" "16384"
            write_sysctl "net.ipv4.udp_mem" "8388608 12582912 16777216"
            ;;
    esac
    
    log SUCCESS "UDP optimized"
}

optimize_conntrack() {
    local level=$1
    
    log INFO "Optimizing connection tracking (level $level)..."
    
    case $level in
        1)
            write_sysctl "net.netfilter.nf_conntrack_max" "262144"
            ;;
        2)
            write_sysctl "net.netfilter.nf_conntrack_max" "524288"
            write_sysctl "net.netfilter.nf_conntrack_tcp_timeout_established" "1200"
            ;;
        3|4)
            write_sysctl "net.netfilter.nf_conntrack_max" "1048576"
            write_sysctl "net.netfilter.nf_conntrack_tcp_timeout_established" "600"
            write_sysctl "net.netfilter.nf_conntrack_tcp_timeout_time_wait" "30"
            write_sysctl "net.netfilter.nf_conntrack_tcp_timeout_close_wait" "15"
            ;;
    esac
    
    log SUCCESS "Connection tracking optimized"
}

optimize_local_port_range() {
    log INFO "Optimizing local port range..."
    write_sysctl "net.ipv4.ip_local_port_range" "1024 65535"
    log SUCCESS "Local port range optimized"
}

optimize_for_redteam() {
    log INFO "Applying redteam network optimizations..."
    
    # Increase connection tracking for massive scans
    write_sysctl "net.netfilter.nf_conntrack_max" "2097152"
    
    # Optimize for packet capture
    write_sysctl "net.core.rmem_default" "134217728"
    write_sysctl "net.core.wmem_default" "134217728"
    
    # Reduce timeouts for faster scanning
    write_sysctl "net.ipv4.tcp_syn_retries" "2"
    write_sysctl "net.ipv4.tcp_synack_retries" "2"
    write_sysctl "net.ipv4.tcp_fin_timeout" "10"
    
    # Enable IP forwarding (useful for MITM)
    write_sysctl "net.ipv4.ip_forward" "1"
    write_sysctl "net.ipv6.conf.all.forwarding" "1"
    
    # Disable ICMP redirects (security)
    write_sysctl "net.ipv4.conf.all.accept_redirects" "0"
    write_sysctl "net.ipv6.conf.all.accept_redirects" "0"
    write_sysctl "net.ipv4.conf.all.send_redirects" "0"
    
    # Enable reverse path filtering
    write_sysctl "net.ipv4.conf.all.rp_filter" "1"
    
    log SUCCESS "Redteam optimizations applied"
}

apply_stage_1() {
    log INFO "Applying Stage 1 network optimizations..."
    
    # Create fresh config file
    > /etc/sysctl.d/99-shellshocktune-network.conf
    
    optimize_tcp_buffers 1
    optimize_tcp_stack 1
    optimize_udp 1
    optimize_local_port_range
    
    log SUCCESS "Stage 1 applied"
}

apply_stage_2() {
    log INFO "Applying Stage 2 network optimizations..."
    
    # Create fresh config file
    > /etc/sysctl.d/99-shellshocktune-network.conf
    
    optimize_tcp_buffers 2
    optimize_tcp_stack 2
    optimize_udp 2
    optimize_conntrack 2
    optimize_local_port_range
    enable_bbr
    
    log SUCCESS "Stage 2 applied"
}

apply_stage_3() {
    log INFO "Applying Stage 3 network optimizations..."
    
    # Create fresh config file
    > /etc/sysctl.d/99-shellshocktune-network.conf
    
    optimize_tcp_buffers 3
    optimize_tcp_stack 3
    optimize_udp 3
    optimize_conntrack 3
    optimize_local_port_range
    enable_bbr
    
    log SUCCESS "Stage 3 applied"
}

apply_stage_4() {
    log INFO "Applying Stage 4 (Redteam) network optimizations..."
    
    # Apply Stage 3 first
    apply_stage_3
    
    # Add redteam-specific optimizations
    optimize_for_redteam
    
    log SUCCESS "Stage 4 applied"
}

restore_defaults() {
    log INFO "Restoring network defaults..."
    
    # Remove custom config
    rm -f /etc/sysctl.d/99-shellshocktune-network.conf
    
    # Reload default sysctl
    sysctl -p &>/dev/null
    
    log SUCCESS "Network defaults restored"
}

verify_configuration() {
    log INFO "Verifying network configuration..."
    
    local errors=0
    
    # Check BBR
    local current_cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
    if [[ "$current_cc" == "bbr" ]]; then
        log SUCCESS "BBR enabled: $current_cc"
    else
        log WARNING "BBR not enabled (current: $current_cc)"
    fi
    
    # Check buffer sizes
    local rmem_max=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")
    log INFO "Max receive buffer: $rmem_max bytes"
    
    # Check conntrack
    local conntrack=$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo "N/A")
    log INFO "Conntrack max: $conntrack"
    
    if [[ $errors -eq 0 ]]; then
        log SUCCESS "Network verification passed"
        return 0
    else
        log ERROR "Network verification failed"
        return 1
    fi
}

show_info() {
    cat << EOF
Module: Network Stack Optimization
Version: $MODULE_VERSION
Author: $MODULE_AUTHOR

Current Configuration:
  Congestion Control: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
  Max RX Buffer: $(sysctl -n net.core.rmem_max 2>/dev/null || echo "unknown") bytes
  Max TX Buffer: $(sysctl -n net.core.wmem_max 2>/dev/null || echo "unknown") bytes
  Netdev Backlog: $(sysctl -n net.core.netdev_max_backlog 2>/dev/null || echo "unknown")
  Conntrack Max: $(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo "N/A")

Stage Descriptions:
  Stage 1: 16MB buffers, basic TCP optimizations
  Stage 2: 64MB buffers, BBR, aggressive TCP tuning
  Stage 3: 128MB buffers, maximum performance
  Stage 4: Stage 3 + redteam features (packet capture, forwarding)

EOF
}

main() {
    local action=${1:-help}
    
    case $action in
        apply)
            local stage=${2:-1}
            case $stage in
                1) apply_stage_1 ;;
                2) apply_stage_2 ;;
                3) apply_stage_3 ;;
                4) apply_stage_4 ;;
                *) 
                    log ERROR "Invalid stage: $stage"
                    exit 1
                    ;;
            esac
            verify_configuration
            ;;
        restore)
            restore_defaults
            ;;
        verify)
            verify_configuration
            ;;
        info)
            show_info
            ;;
        *)
            cat << EOF
Usage: $0 <action> [arguments]

Actions:
  apply <stage>      Apply network optimizations (1-4)
  restore            Restore default settings
  verify             Verify configuration
  info               Show module information

Examples:
  $0 apply 2         Apply Stage 2 optimizations
  $0 verify          Verify current configuration
  $0 restore         Restore defaults

EOF
            ;;
    esac
}

main "$@"