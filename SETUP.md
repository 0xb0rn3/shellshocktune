# 🚀 ShellShockTune - Complete Setup Guide

This guide will walk you through setting up ShellShockTune from scratch.

---

## 📋 Prerequisites

### System Requirements

- **OS**: Any Linux distribution (Arch, Debian, Fedora, Ubuntu, etc.)
- **Kernel**: 4.0+ (5.x+ recommended)
- **Architecture**: x86_64, ARM64, ARM32
- **RAM**: 2GB minimum, 4GB+ recommended
- **Disk**: 100MB for installation

### Required Packages

The installer will automatically install these, but you can install manually:

**Arch/Manjaro/Archcraft:**
```bash
sudo pacman -S dialog gcc git curl stress-ng sysbench
```

**Debian/Ubuntu/Kali:**
```bash
sudo apt install dialog gcc git curl stress-ng sysbench
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install dialog gcc git curl stress-ng sysbench
```

---

## 🛠️ Installation Methods

### Method 1: One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/0xb0rn3/shellshocktune/main/install.sh | sudo bash
```

### Method 2: Git Clone

```bash
# Clone repository
git clone https://github.com/0xb0rn3/shellshocktune.git
cd shellshocktune

# Make installer executable
chmod +x install.sh

# Run installer
sudo ./install.sh
```

### Method 3: Manual Installation

```bash
# Create directories
sudo mkdir -p /opt/shellshocktune/{modules,profiles,scripts}
sudo mkdir -p /var/lib/shellshocktune/{backups,benchmarks}

# Download main script
sudo curl -o /opt/shellshocktune/shellshocktune \
  https://raw.githubusercontent.com/0xb0rn3/shellshocktune/main/shellshocktune

# Make executable
sudo chmod +x /opt/shellshocktune/shellshocktune

# Create symlink
sudo ln -s /opt/shellshocktune/shellshocktune /usr/local/bin/shellshocktune

# Download and setup cpu-governor
sudo mkdir -p /opt/shellshocktune/modules/cpu-governor
cd /opt/shellshocktune/modules/cpu-governor
sudo curl -O https://raw.githubusercontent.com/0xb0rn3/cpu-governor/main/cpu-governor.c
sudo gcc -O2 -march=native -o cpu-governor cpu-governor.c
sudo chmod +x cpu-governor
```

---

## 📁 Project Structure Setup

After installation, your system will have:

```
/opt/shellshocktune/
├── shellshocktune              # Main executable
├── modules/
│   ├── cpu-governor/
│   │   ├── cpu-governor.c
│   │   └── cpu-governor        # Compiled binary
│   ├── kernel/                 # Kernel tuning modules
│   ├── network/                # Network optimization
│   ├── filesystem/             # FS optimization
│   ├── security/               # Security tools
│   └── monitoring/             # Benchmarking
├── profiles/
│   ├── gaming.conf
│   ├── developer.conf
│   ├── extreme.conf
│   └── redteam.conf
└── scripts/
    ├── apply-stage.sh          # Stage logic
    ├── verify.sh
    ├── backup.sh
    └── restore.sh

/var/lib/shellshocktune/
├── backups/                    # System backups
│   └── benchmarks/             # Performance data
└── state                       # Current state file

/var/log/
└── shellshocktune.log         # Activity log

/usr/local/bin/
└── shellshocktune -> /opt/shellshocktune/shellshocktune
```

---

## 🎯 First Run

### 1. Launch ShellShockTune

```bash
sudo shellshocktune
```

You'll see the interactive menu:

```
   _____ __         ____   _____ __                __  ______                
  / ___// /_  ___  / / /  / ___// /_  ____  _____/ /_/_  __/_  ______  ___ 
  \__ \/ __ \/ _ \/ / /   \__ \/ __ \/ __ \/ ___/ //_// / / / / / __ \/ _ \
 ___/ / / / /  __/ / /   ___/ / / / / /_/ / /__/ ,<  / / / /_/ / / / /  __/
/____/_/ /_/\___/_/_/   /____/_/ /_/\____/\___/_/|_|/_/  \__,_/_/ /_/\___/ 

Linux Performance Tuner v0.0.1
by 0xbv1 | 0xb0rn3 {shell shock}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────────────┐
│                     Main Menu                        │
├─────────────────────────────────────────────────────┤
│  1  Select Tuning Stage                             │
│  2  Apply Current Configuration                     │
│  3  System Information                              │
│  4  Benchmark System                                │
│  5  Compare Performance                             │
│  6  Load Profile                                    │
│  7  Save Profile                                    │
│  8  Restore System                                  │
│  9  Module Configuration                            │
│  10 Advanced Options                                │
│  11 View Logs                                       │
│  12 Exit                                            │
└─────────────────────────────────────────────────────┘
```

### 2. Check System Information

Select `3. System Information` to verify detection:

```
[INFO] Detecting system configuration...
[✓] System detected:
  Distribution: arch 
  CPU: AMD Ryzen 9 5900X (12 cores)
  Vendor: AuthenticAMD
  Kernel: 6.1.0-arch1-1
  Init System: systemd
```

### 3. Run Initial Benchmark

Select `4. Benchmark System` to establish baseline:

```
[INFO] Running before-tuning benchmark...

=== ShellShockTune Benchmark - before tuning ===
Timestamp: 2024-11-14 10:30:00

=== CPU Performance ===
stress-ng: 45000 bogo ops/s

=== Memory Performance ===
2500.00 MiB/sec

=== Disk I/O ===
1073741824 bytes (1.1 GB, 1.0 GiB) copied, 2.4 s, 450 MB/s

[✓] Benchmark results saved: /var/lib/shellshocktune/backups/benchmarks/before_1234567890.txt
```

---

## 🎛️ Stage Selection Guide

### Choosing Your Stage

Select `1. Select Tuning Stage`:

```
┌─────────────────────────────────────────────────────┐
│              Select Tuning Stage                     │
├─────────────────────────────────────────────────────┤
│  0  Stock - Distro defaults                         │
│  1  Optimized - Safe tweaks (scheduler, I/O)       │
│  2  Performance - Aggressive (CPU gov, network)     │
│  3  Extreme - Maximum (custom kernel params)        │
│  4  Redteam - Stage 3 + security tools + wireless   │
└─────────────────────────────────────────────────────┘
```

### Stage Recommendations

**Stage 1 - Daily Driver:**
- ✅ Laptops
- ✅ Battery-powered devices
- ✅ General use
- ✅ Minimal risk

**Stage 2 - Gaming/Development:**
- ✅ Desktop gaming
- ✅ Software development
- ✅ Video editing
- ✅ Content creation

**Stage 3 - Maximum Performance:**
- ✅ Benchmarking
- ✅ Competitive gaming
- ✅ Data science workloads
- ✅ High-performance computing
- ⚠️ May increase power consumption
- ⚠️ Disables security mitigations

**Stage 4 - Security/Pentesting:**
- ✅ Penetration testing
- ✅ Security research
- ✅ Network analysis
- ✅ CTF competitions
- ✅ Wireless auditing
- ⚠️ All Stage 3 warnings apply
- ⚠️ Installs additional tools

---

## 📊 Understanding the Process

When you apply a stage, ShellShockTune:

1. **Creates Backup**
   ```
   [INFO] Creating system backup...
   [✓] System backup created at: /var/lib/shellshocktune/backups/20241114_103000
   ```

2. **Runs Before Benchmark**
   ```
   [INFO] Running before-tuning benchmark...
   [✓] Benchmark results saved
   ```

3. **Applies Stage**
   ```
   [STAGE 2] Setting CPU governor to: performance
   [STAGE 2] Setting I/O scheduler to: kyber
   [STAGE 2] Applying kernel parameters...
   [STAGE 2] Optimizing network stack (level 2)...
   [STAGE 2] Optimizing memory management (level 2)...
   [STAGE 2] Configuring thermal management...
   ```

4. **Runs After Benchmark**
   ```
   [INFO] Running after-tuning benchmark...
   [✓] Benchmark results saved
   ```

5. **Shows Results**
   ```
   ┌─────────────────────────────────────────────────────┐
   │                      Success                         │
   ├─────────────────────────────────────────────────────┤
   │ Stage 2 applied successfully!                       │
   │                                                      │
   │ A system reboot is recommended for all changes      │
   │ to take effect.                                     │
   │                                                      │
   │ Benchmark results have been saved.                  │
   └─────────────────────────────────────────────────────┘
   ```

---

## 🔍 Verifying Changes

### Check CPU Governor

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Should show: performance (Stage 2+)
```

### Check I/O Scheduler

```bash
cat /sys/block/sda/queue/scheduler
# Stage 2: [kyber]
# Stage 3: [none]
```

### Check Kernel Parameters

```bash
sysctl vm.swappiness
# Stage 1: vm.swappiness = 10
# Stage 2: vm.swappiness = 1
# Stage 3: vm.swappiness = 0
```

### Check Network Settings

```bash
sysctl net.core.rmem_max
# Stage 1: net.core.rmem_max = 16777216 (16MB)
# Stage 2: net.core.rmem_max = 67108864 (64MB)
# Stage 3: net.core.rmem_max = 134217728 (128MB)
```

---

## 📈 Comparing Performance

Select `5. Compare Performance`:

```
=== Performance Comparison ===

BEFORE:
  stress-ng: 45000 bogo ops/s
  Memory: 2500.00 MiB/sec
  Disk: 450 MB/s

AFTER:
  stress-ng: 58000 bogo ops/s (+28.8%)
  Memory: 3200.00 MiB/sec (+28.0%)
  Disk: 890 MB/s (+97.7%)

Press Enter to continue...
```

---

## 🔄 Restoring Your System

If you need to revert changes:

### Via Menu

1. Select `8. Restore System`
2. Confirm restoration
3. System automatically restores from latest backup

### Via Command Line

```bash
sudo shellshocktune --restore
```

### Manual Restoration

```bash
# Find latest backup
ls -lt /var/lib/shellshocktune/backups/

# Restore files
sudo cp -a /var/lib/shellshocktune/backups/20241114_103000/* /

# Reload sysctl
sudo sysctl -p
```

---

## 🎨 Using Profiles

### Loading a Profile

Select `6. Load Profile`:

```
┌─────────────────────────────────────────────────────┐
│                  Available Profiles                  │
├─────────────────────────────────────────────────────┤
│  1  gaming.conf       - Stage 2 gaming optimized    │
│  2  developer.conf    - Stage 1 development         │
│  3  extreme.conf      - Stage 3 maximum perf        │
│  4  redteam.conf      - Stage 4 security tools      │
└─────────────────────────────────────────────────────┘
```

### Creating Custom Profiles

```bash
sudo nano /opt/shellshocktune/profiles/myprofile.conf
```

Example custom profile:

```ini
# My Custom Profile
STAGE=2
CPU_GOVERNOR=performance
IO_SCHEDULER=kyber
SWAPPINESS=5
NETWORK_BUFFERS=64MB
ENABLE_BBR=true
DISABLE_COMPOSITOR=false
```

---

## ⚙️ Advanced Configuration

### Command-Line Usage (Coming Soon)

```bash
# Apply specific stage
sudo shellshocktune --stage 2

# Apply profile
sudo shellshocktune --profile gaming

# Check status
sudo shellshocktune --status

# Run benchmark
sudo shellshocktune --benchmark

# Restore system
sudo shellshocktune --restore
```

### Systemd Integration

Auto-apply on boot:

```bash
sudo nano /etc/systemd/system/shellshocktune.service
```

```ini
[Unit]
Description=ShellShockTune Performance Optimization
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/shellshocktune --stage 2
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable:

```bash
sudo systemctl enable shellshocktune.service
sudo systemctl start shellshocktune.service
```

---

## 🐛 Troubleshooting

### Issue: "cpu-governor failed to compile"

**Solution:**
```bash
# Install build tools
sudo pacman -S base-devel  # Arch
sudo apt install build-essential  # Debian/Ubuntu

# Recompile manually
cd /opt/shellshocktune/modules/cpu-governor
sudo gcc -O2 -march=native -o cpu-governor cpu-governor.c
```

### Issue: "Cannot write to /sys/devices/..."

**Solution:**
```bash
# Ensure running as root
sudo shellshocktune

# Check if cpufreq available
ls /sys/devices/system/cpu/cpu0/cpufreq/
```

### Issue: "Stage application failed"

ShellShockTune automatically restores on failure. Check logs:

```bash
sudo cat /var/log/shellshocktune.log
```

### Issue: System instability after Stage 3/4

**Solution:**
```bash
# Immediate restore
sudo shellshocktune --restore

# Or boot into recovery and restore manually
sudo cp -a /var/lib/shellshocktune/backups/latest/* /
sudo sysctl -p
sudo reboot
```

---

## 📝 Viewing Logs

### Real-time Monitoring

```bash
sudo tail -f /var/log/shellshocktune.log
```

### Via Menu

Select `11. View Logs` to view in dialog interface

### Log Location

- **Main log**: `/var/log/shellshocktune.log`
- **Benchmarks**: `/var/lib/shellshocktune/backups/benchmarks/`
- **State file**: `/var/lib/shellshocktune/state`

---

## 🔒 Security Considerations

### Stage 3 & 4 Disable Mitigations

These stages disable CPU vulnerability mitigations (Spectre, Meltdown) for maximum performance.

**Recommendation:**
- Use Stage 3/4 only on trusted, isolated systems
- Don't use on public-facing servers
- Don't use on systems handling sensitive data

### Stage 4 Security Tools

Installs penetration testing tools. **Legal Notice:**
- Only use on systems you own or have permission to test
- Unauthorized access is illegal
- Use responsibly

---

## 🔧 Uninstallation

### Complete Removal

```bash
# Restore system first
sudo shellshocktune --restore

# Run uninstaller
sudo /opt/shellshocktune/../install.sh --uninstall
```

### Manual Uninstall

```bash
# Restore system
sudo shellshocktune --restore

# Remove files
sudo rm /usr/local/bin/shellshocktune
sudo rm -rf /opt/shellshocktune
sudo rm -rf /var/lib/shellshocktune
sudo rm /var/log/shellshocktune.log

# Remove sysctl config
sudo rm /etc/sysctl.d/99-shellshocktune.conf
sudo sysctl -p
```

---

## 📚 Next Steps

1. **Run Benchmarks**: Establish your baseline
2. **Try Stage 1**: Safe optimization for daily use
3. **Test Stage 2**: For gaming/performance work
4. **Experiment**: Try different stages for different workloads
5. **Monitor**: Watch system behavior and temperatures
6. **Tune**: Adjust profiles for your specific needs

---

## 🆘 Getting Help

### Check Documentation

```bash
# View README
cat /opt/shellshocktune/../README.md

# View this setup guide
cat /opt/shellshocktune/../SETUP.md
```

### Community Support

- **GitHub Issues**: Report bugs and request features
- **Discord**: `oxbv1`
- **Twitter/X**: `@oxbv1`

### Logs for Bug Reports

When reporting issues, include:

```bash
# System info
uname -a
cat /etc/os-release

# ShellShockTune log
sudo cat /var/log/shellshocktune.log

# Current state
sudo cat /var/lib/shellshocktune/state
```

---

## ✅ Setup Checklist

- [ ] Dependencies installed
- [ ] ShellShockTune installed
- [ ] Initial benchmark completed
- [ ] System information verified
- [ ] Stage selected and applied
- [ ] Performance compared
- [ ] Backup verified
- [ ] Reboot performed (if needed)

---

**Congratulations! ShellShockTune is now configured and ready to optimize your Linux system.**

🔥 **Happy Tuning!** 🔥

*by 0xbv1 | 0xb0rn3 {shell shock}*