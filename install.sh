#!/bin/bash

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
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    else
        DISTRO="unknown"
        DISTRO_VERSION="unknown"
    fi
    
    log INFO "Detected: $DISTRO $DISTRO_VERSION"
}

install_dependencies() {
    log INFO "Installing dependencies..."
    
    case $DISTRO in
        arch|archcraft|manjaro)
            log INFO "Using pacman..."
            pacman -Sy --noconfirm --needed dialog gcc git curl stress-ng sysbench || {
                log WARNING "Some packages may have failed to install"
            }
            ;;
        debian|ubuntu|kali|linuxmint|pop)
            log INFO "Using apt..."
            apt-get update
            apt-get install -y dialog gcc git curl stress-ng sysbench || {
                log WARNING "Some packages may have failed to install"
            }
            ;;
        fedora|rhel|centos|rocky|alma)
            log INFO "Using dnf..."
            dnf install -y dialog gcc git curl stress-ng sysbench || {
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
            log WARNING "Please install manually: dialog gcc git curl stress-ng sysbench"
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
    
    # Copy scripts
    if [[ -d "$source_dir/scripts" ]]; then
        cp -r "$source_dir/scripts/"* "$INSTALL_DIR/scripts/" 2>/dev/null || true
        chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
    fi
    
    # Copy profiles
    if [[ -d "$source_dir/profiles" ]]; then
        cp -r "$source_dir/profiles/"* "$INSTALL_DIR/profiles/" 2>/dev/null || true
    fi
    
    # Copy modules (if any)
    if [[ -d "$source_dir/modules" ]]; then
        cp -r "$source_dir/modules/"* "$INSTALL_DIR/modules/" 2>/dev/null || true
    fi
    
    log SUCCESS "Files copied"
}

setup_cpu_governor() {
    log INFO "Setting up CPU Governor module..."
    
    local cpu_gov_dir="$INSTALL_DIR/modules/cpu-governor"
    mkdir -p "$cpu_gov_dir"
    cd "$cpu_gov_dir"
    
    # Download cpu-governor.c
    log INFO "Downloading cpu-governor.c..."
    curl -sL https://raw.githubusercontent.com/0xb0rn3/cpu-governor/main/cpu-governor.c -o cpu-governor.c || {
        log ERROR "Failed to download cpu-governor.c"
        return 1
    }
    
    # Compile
    log INFO "Compiling cpu-governor..."
    if gcc -O2 -march=native -o cpu-governor cpu-governor.c 2>/dev/null; then
        chmod +x cpu-governor
        log SUCCESS "CPU Governor compiled successfully"
    else
        log ERROR "Failed to compile cpu-governor"
        log WARNING "Will use fallback method for CPU frequency control"
    fi
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
CPU_GOVERNOR=ondemand
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
    
    # Runtime directories
    chmod 755 /var/lib/shellshocktune
    chmod 755 /var/lib/shellshocktune/backups
    
    log SUCCESS "Permissions set"
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
    echo -e "  ${YELLOW}cat $INSTALL_DIR/../README.md${RESET}"
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
    
    show_completion
}

# Trap errors
trap 'log ERROR "Installation failed at line $LINENO"' ERR

main "$@"