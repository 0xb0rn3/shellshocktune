#!/usr/bin/env bash

#==============================================================================
# ShellShockTune Installer
# Automated installation and setup
#==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'

# Configuration
INSTALL_DIR="/opt/shellshocktune"
BIN_DIR="/usr/local/bin"
TUNER_NAME="shellshocktune"

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   _____ __         ____   _____ __                __  ______                
  / ___// /_  ___  / / /  / ___// /_  ____  _____/ /_/_  __/_  ______  ___ 
  \__ \/ __ \/ _ \/ / /   \__ \/ __ \/ __ \/ ___/ //_// / / / / / __ \/ _ \
 ___/ / / / /  __/ / /   ___/ / / / / /_/ / /__/ ,<  / / / /_/ / / / /  __/
/____/_/ /_/\___/_/_/   /____/_/ /_/\____/\___/_/|_|/_/  \__,_/_/ /_/\___/ 
                                                                            
EOF
    echo -e "${RESET}"
    echo -e "${WHITE}${BOLD}ShellShockTune Installer${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

log() {
    local level=$1
    shift
    local message="$*"
    
    case $level in
        INFO)  echo -e "${BLUE}[INFO]${RESET} $message" ;;
        SUCCESS) echo -e "${GREEN}[✓]${RESET} $message" ;;
        WARNING) echo -e "${YELLOW}[!]${RESET} $message" ;;
        ERROR)   echo -e "${RED}[✗]${RESET} $message" ;;
    esac
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log WARNING "Installation requires root privileges"
        echo -e "${YELLOW}Requesting sudo elevation...${RESET}"
        exec sudo "$0" "$@"
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO=${ID:-unknown}
        DISTRO_VERSION=${VERSION_ID:-unknown}
    else
        DISTRO="unknown"
        DISTRO_VERSION="unknown"
    fi
    
    log INFO "Detected: $DISTRO $DISTRO_VERSION"
}

install_dependencies() {
    log INFO "Installing dependencies..."
    
    # Remove cpufreq_schedutil from package list (it's a kernel governor, not a package)
    local base_packages="dialog gcc git curl stress-ng sysbench"
    
    case $DISTRO in
        arch|archcraft|manjaro)
            log INFO "Using pacman..."
            pacman -Sy --noconfirm --needed $base_packages || {
                log WARNING "Some packages may have failed to install"
            }
            ;;
        debian|ubuntu|kali|linuxmint|pop)
            log INFO "Using apt..."
            apt-get update -qq
            apt-get install -y $base_packages || {
                log WARNING "Some packages may have failed to install"
            }
            ;;
        fedora|rhel|centos|rocky|alma)
            log INFO "Using dnf..."
            dnf install -y $base_packages || {
                log WARNING "Some packages may have failed to install"
            }
            ;;
        opensuse*|sles)
            log INFO "Using zypper..."
            zypper install -y dialog gcc git curl stress-ng || {
                log WARNING "Some packages may have failed to install"
            }
            ;;
        *)
            log ERROR "Unsupported distribution: $DISTRO"
            log WARNING "Please install manually: $base_packages"
            echo -e "${YELLOW}Continue anyway? [y/N]:${RESET} "
            read -r response
            [[ "$response" =~ ^[Yy]$ ]] || exit 1
            ;;
    esac
    
    log SUCCESS "Dependencies installed"
}

create_directory_structure() {
    log INFO "Creating directory structure..."
    
    # Create main installation directory
    mkdir -p "$INSTALL_DIR"/{modules,profiles,scripts}
    mkdir -p "$INSTALL_DIR"/modules/{cpu-governor,kernel,network,filesystem,security,monitoring}
    
    # Create runtime directories
    mkdir -p /var/lib/shellshocktune/{backups,benchmarks}
    mkdir -p /var/log
    
    # Create log file
    touch /var/log/shellshocktune.log
    chmod 644 /var/log/shellshocktune.log
    
    log SUCCESS "Directory structure created"
}

copy_files() {
    log INFO "Copying files..."
    
    local source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy main tuner script
    if [[ -f "$source_dir/shellshocktune" ]]; then
        cp "$source_dir/shellshocktune" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/shellshocktune"
    else
        log ERROR "shellshocktune script not found!"
        return 1
    fi
    
    # Copy scripts directory
    if [[ -d "$source_dir/scripts" ]]; then
        cp -r "$source_dir/scripts"/* "$INSTALL_DIR/scripts/" 2>/dev/null || true
        chmod +x "$INSTALL_DIR/scripts"/*.sh 2>/dev/null || true
        log INFO "Copied scripts"
    else
        log WARNING "scripts directory not found, creating empty directory"
        mkdir -p "$INSTALL_DIR/scripts"
    fi
    
    # Copy profiles
    if [[ -d "$source_dir/profiles" ]]; then
        cp -r "$source_dir/profiles"/* "$INSTALL_DIR/profiles/" 2>/dev/null || true
        log INFO "Copied profiles"
    else
        log WARNING "profiles directory not found"
    fi
    
    # Copy modules (except cpu-governor which we'll handle separately)
    if [[ -d "$source_dir/modules" ]]; then
        # Copy module files but skip cpu-governor directory (we'll set it up separately)
        for module_dir in "$source_dir/modules"/*; do
            if [[ -d "$module_dir" ]] && [[ "$(basename "$module_dir")" != "cpu-governor" ]]; then
                cp -r "$module_dir" "$INSTALL_DIR/modules/" 2>/dev/null || true
            fi
        done
        log INFO "Copied modules"
    fi
    
    log SUCCESS "Files copied"
}

setup_cpu_governor() {
    log INFO "Setting up CPU Governor module..."
    
    local cpu_gov_dir="$INSTALL_DIR/modules/cpu-governor"
    mkdir -p "$cpu_gov_dir"
    
    # Download cpu-governor.c
    log INFO "Downloading cpu-governor.c..."
    if curl -sL https://raw.githubusercontent.com/0xb0rn3/cpu-governor/main/cpu-governor.c -o "$cpu_gov_dir/cpu-governor.c"; then
        log SUCCESS "Downloaded cpu-governor.c"
        
        # Try to compile
        log INFO "Compiling cpu-governor..."
        cd "$cpu_gov_dir"
        
        if gcc -O2 -march=native -o cpu-governor cpu-governor.c 2>/dev/null; then
            chmod +x cpu-governor
            log SUCCESS "CPU Governor compiled successfully"
        else
            log WARNING "Failed to compile cpu-governor (will use fallback method)"
        fi
    else
        log WARNING "Failed to download cpu-governor.c (will use fallback method)"
    fi
    
    # Create enhanced set-governor.sh script
    log INFO "Creating enhanced set-governor.sh script..."
    cat > "$cpu_gov_dir/set-governor.sh" << 'EOFGOV'
#!/bin/bash
set -euo pipefail

GOVERNOR=${1:-schedutil}

log() { echo "[CPU-GOV] $*"; }

detect_driver() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "unknown"
}

get_available_governors() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo ""
}

is_governor_available() {
    local gov=$1
    local available=$(get_available_governors)
    [[ "$available" =~ $gov ]]
}

set_governor() {
    local gov=$1
    local success=0
    local total=0
    
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
            ((total++))
            echo "$gov" > "$cpu" 2>/dev/null && ((success++)) || true
        fi
    done
    
    [[ $success -gt 0 ]] && log "Set governor '$gov' on $success/$total CPUs"
}

main() {
    local driver=$(detect_driver)
    local available=$(get_available_governors)
    
    log "Driver: $driver | Requested: $GOVERNOR"
    log "Available: $available"
    
    case $driver in
        intel_pstate|intel_cpufreq|amd-pstate*)
            case $GOVERNOR in
                performance)
                    set_governor "performance"
                    [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]] && \
                        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
                    ;;
                ondemand|conservative|schedutil)
                    is_governor_available "schedutil" && set_governor "schedutil" || set_governor "powersave"
                    ;;
                *)
                    is_governor_available "$GOVERNOR" && set_governor "$GOVERNOR" || set_governor "powersave"
                    ;;
            esac
            ;;
        *)
            is_governor_available "$GOVERNOR" && set_governor "$GOVERNOR" || \
                (is_governor_available "schedutil" && set_governor "schedutil") || \
                set_governor "powersave"
            ;;
    esac
    
    local current=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    log "Active: $current"
}

main
EOFGOV
    
    chmod +x "$cpu_gov_dir/set-governor.sh"
    log SUCCESS "Enhanced set-governor.sh created"
}

create_symlink() {
    log INFO "Creating system-wide command..."
    
    if [[ -L "$BIN_DIR/$TUNER_NAME" ]]; then
        rm "$BIN_DIR/$TUNER_NAME"
    fi
    
    ln -s "$INSTALL_DIR/shellshocktune" "$BIN_DIR/$TUNER_NAME"
    
    log SUCCESS "Command '$TUNER_NAME' available system-wide"
}

create_default_profiles() {
    log INFO "Creating default profiles..."
    
    # Gaming profile
    cat > "$INSTALL_DIR/profiles/gaming.conf" << 'EOF'
# ShellShockTune Gaming Profile
STAGE=2
CPU_GOVERNOR=performance
IO_SCHEDULER=kyber
SWAPPINESS=1
NETWORK_BUFFERS=64MB
ENABLE_BBR=true
DISABLE_COMPOSITOR=true
EOF
    
    # Developer profile
    cat > "$INSTALL_DIR/profiles/developer.conf" << 'EOF'
# ShellShockTune Developer Profile
STAGE=1
CPU_GOVERNOR=schedutil
IO_SCHEDULER=bfq
SWAPPINESS=10
NETWORK_BUFFERS=32MB
ENABLE_BBR=true
EOF
    
    # Extreme profile
    cat > "$INSTALL_DIR/profiles/extreme.conf" << 'EOF'
# ShellShockTune Extreme Profile
STAGE=3
CPU_GOVERNOR=performance
IO_SCHEDULER=none
SWAPPINESS=0
NETWORK_BUFFERS=128MB
ENABLE_BBR=true
DISABLE_MITIGATIONS=true
TRANSPARENT_HUGEPAGES=always
EOF
    
    # Redteam profile
    cat > "$INSTALL_DIR/profiles/redteam.conf" << 'EOF'
# ShellShockTune Redteam Profile
STAGE=4
CPU_GOVERNOR=performance
IO_SCHEDULER=none
SWAPPINESS=0
NETWORK_BUFFERS=128MB
ENABLE_BBR=true
DISABLE_MITIGATIONS=true
TRANSPARENT_HUGEPAGES=always
INSTALL_WIRELESS_TOOLS=true
ENABLE_MONITOR_MODE=true
EOF
    
    log SUCCESS "Default profiles created"
}

set_permissions() {
    log INFO "Setting permissions..."
    
    chown -R root:root "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR/shellshocktune"
    chmod -R 755 "$INSTALL_DIR/scripts" 2>/dev/null || true
    chmod -R 755 "$INSTALL_DIR/modules" 2>/dev/null || true
    
    # Runtime directories
    chmod 755 /var/lib/shellshocktune
    chmod 755 /var/lib/shellshocktune/backups
    chmod 755 /var/lib/shellshocktune/benchmarks
    chmod 644 /var/log/shellshocktune.log
    
    log SUCCESS "Permissions set"
}

verify_installation() {
    log INFO "Verifying installation..."
    
    local errors=0
    
    # Check main script
    if [[ ! -f "$INSTALL_DIR/shellshocktune" ]]; then
        log ERROR "Main script not found"
        ((errors++))
    fi
    
    # Check apply-stage.sh
    if [[ ! -f "$INSTALL_DIR/scripts/apply-stage.sh" ]]; then
        log WARNING "apply-stage.sh not found (will need to be added)"
    fi
    
    # Check symlink
    if [[ ! -L "$BIN_DIR/$TUNER_NAME" ]]; then
        log ERROR "System command symlink not created"
        ((errors++))
    fi
    
    # Check directories
    for dir in "$INSTALL_DIR" "$INSTALL_DIR/modules" "$INSTALL_DIR/scripts" "$INSTALL_DIR/profiles" \
               "/var/lib/shellshocktune" "/var/lib/shellshocktune/backups"; do
        if [[ ! -d "$dir" ]]; then
            log ERROR "Directory missing: $dir"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log SUCCESS "Installation verification passed"
        return 0
    else
        log WARNING "Installation verification found $errors issue(s)"
        return 1
    fi
}

show_completion() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}${BOLD}✓ Installation Complete!${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "${CYAN}Installation Directory:${RESET} $INSTALL_DIR"
    echo -e "${CYAN}Command:${RESET} $TUNER_NAME"
    echo ""
    echo -e "${WHITE}Quick Start:${RESET}"
    echo -e "  ${YELLOW}sudo $TUNER_NAME${RESET}           # Launch interactive menu"
    echo -e "  ${YELLOW}sudo $TUNER_NAME --help${RESET}    # View help"
    echo ""
    echo -e "${WHITE}Available Stages:${RESET}"
    echo -e "  ${CYAN}Stage 0:${RESET} Stock - Distro defaults"
    echo -e "  ${CYAN}Stage 1:${RESET} Optimized - Safe tweaks"
    echo -e "  ${CYAN}Stage 2:${RESET} Performance - Aggressive tuning"
    echo -e "  ${CYAN}Stage 3:${RESET} Extreme - Maximum performance"
    echo -e "  ${CYAN}Stage 4:${RESET} Redteam - Stage 3 + security tools"
    echo ""
    echo -e "${WHITE}Documentation:${RESET}"
    echo -e "  ${YELLOW}https://github.com/0xb0rn3/shellshocktune${RESET}"
    echo ""
    echo -e "${MAGENTA}by 0xbv1 | 0xb0rn3 {shell shock}${RESET}"
    echo ""
}

uninstall() {
    log WARNING "Uninstalling ShellShockTune..."
    
    # Restore system if needed
    if [[ -f /var/lib/shellshocktune/state ]]; then
        log INFO "Restoring system to previous state..."
        "$INSTALL_DIR/shellshocktune" --restore 2>/dev/null || true
    fi
    
    # Remove files
    rm -f "$BIN_DIR/$TUNER_NAME"
    rm -rf "$INSTALL_DIR"
    rm -rf /var/lib/shellshocktune
    rm -f /var/log/shellshocktune.log
    rm -f /etc/sysctl.d/99-shellshocktune.conf
    
    log SUCCESS "ShellShockTune uninstalled"
}

main() {
    print_banner
    
    # Check for uninstall flag
    if [[ "${1:-}" == "--uninstall" ]]; then
        check_root
        uninstall
        exit 0
    fi
    
    log INFO "Starting ShellShockTune installation..."
    echo ""
    
    check_root
    detect_distro
    install_dependencies
    create_directory_structure
    copy_files
    setup_cpu_governor
    create_symlink
    create_default_profiles
    set_permissions
    verify_installation || log WARNING "Installation completed with warnings"
    
    show_completion
}

# Trap errors
trap 'log ERROR "Installation failed at line $LINENO"' ERR

main "$@"
