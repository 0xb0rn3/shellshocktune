# 🔥 ShellShockTune v0.0.1

> **Automated Linux Performance Tuner - From Kernel to Userspace**

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-green.svg)
![Stage](https://img.shields.io/badge/stage-v0.0.1-orange.svg)

**Tune your Linux system like a car - staged, automated, reversible**

</div>

---

## 🎯 Overview

**ShellShockTune** is a comprehensive Linux system performance tuner that optimizes everything from kernel parameters to userspace configurations. Designed for security professionals, developers, and performance enthusiasts who demand maximum control.

### ✨ Key Features

- 🎛️ **5 Tuning Stages**: From stock to extreme red team configurations
- 🔄 **Automatic Backup & Restore**: Safe experimentation with instant rollback
- 📊 **Before/After Benchmarking**: Quantified performance improvements
- 🏗️ **Modular Architecture**: Clean separation of concerns
- 🖥️ **Universal Support**: Works on Arch, Debian, Fedora, and derivatives
- 🛡️ **Safety First**: Automatic cleanup on failures
- 🚀 **Zero-Config**: Intelligent system detection and dependency installation

---

## 📦 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/0xb0rn3/shellshocktune.git
cd shellshocktune

# Make the installer executable
chmod +x install.sh

# Run installation (will request sudo)
./install.sh

# Launch the tuner
sudo shellshocktune
```

### First Run

The tuner will automatically:
1. ✅ Check for root privileges (requests elevation if needed)
2. ✅ Detect your system configuration
3. ✅ Check and install dependencies
4. ✅ Download and compile cpu-governor
5. ✅ Create backup directories
6. ✅ Run initial system benchmark

---

## 🎛️ Tuning Stages

### Stage 0: Stock
**Distro defaults - Factory configuration**

- Default CPU governor (usually `schedutil`)
- Default I/O scheduler
- Stock kernel parameters
- No modifications

**Use Case**: Reverting all changes

---

### Stage 1: Optimized
**Safe tweaks for everyday use**

**CPU**:
- Governor: `ondemand` (dynamic scaling)
- Basic frequency scaling optimization

**I/O**:
- Scheduler: `bfq` (balanced, fair queuing)
- Read-ahead optimization

**Memory**:
- `vm.swappiness = 10` (minimal swap usage)
- `vm.dirty_ratio = 15`
- `vm.dirty_background_ratio = 5`

**Network**:
- Increased buffer sizes (16MB)
- TCP window scaling

**Use Case**: Daily driver, laptops, balanced performance

---

### Stage 2: Performance
**Aggressive tuning for demanding workloads**

**CPU**:
- Governor: `performance` (maximum frequency)
- CPU boost enabled
- Thermal management optimized

**I/O**:
- Scheduler: `kyber` (low-latency)
- Aggressive read-ahead

**Memory**:
- `vm.swappiness = 1` (almost no swap)
- `vm.dirty_ratio = 20`
- `vm.vfs_cache_pressure = 50`
- Increased free memory threshold

**Network**:
- 64MB buffers
- BBR congestion control
- TCP Fast Open enabled
- Disabled slow start after idle

**Use Case**: Gaming, compilation, video editing, data processing

---

### Stage 3: Extreme
**Maximum performance at all costs**

Everything from Stage 2, plus:

**CPU**:
- CPU mitigations disabled (Spectre/Meltdown)
- NMI watchdog disabled
- Scheduler tuning for latency

**I/O**:
- Scheduler: `none` (direct I/O submission)
- No overhead

**Memory**:
- `vm.swappiness = 0` (disable swap)
- Transparent huge pages enabled
- Zone reclaim disabled
- `vm.min_free_kbytes = 131072`

**Network**:
- 128MB buffers
- Advanced TCP tuning
- MTU probing
- Full TCP optimization stack

**Kernel**:
- Scheduler migration cost tuned
- Autogroup disabled
- Custom latency values

**Use Case**: Benchmarks, competitive gaming, HPC, financial trading systems

---

### Stage 4: Redteam
**Stage 3 + Security/Pentesting tools**

Everything from Stage 3, plus:

**Wireless**:
- Aircrack-ng suite
- Wifite, Reaver, Bully
- Monitor mode support
- Packet injection drivers

**Network Analysis**:
- Wireshark/tcpdump
- Netfilter extensions
- Connection tracking (1M connections)
- Port range optimization

**Kernel Modules**:
- `ath9k`, `rtl8xxxu` (wireless)
- `mac80211`, `cfg80211`
- `nfnetlink_queue`
- `usbmon` (USB monitoring)

**Capabilities**:
- Packet capture permissions
- Raw socket access

**Use Case**: Penetration testing, security research, CTF competitions, network analysis

---

## 🛠️ Features Breakdown

### ✅ CPU Governor Control
Integrates [cpu-governor](https://github.com/0xb0rn3/cpu-governor) for intelligent frequency scaling:
- Auto-downloaded and compiled on first run
- Supports all governors: performance, powersave, ondemand, conservative, schedutil
- Per-core control
- Boost management (Intel/AMD)

### ✅ Kernel Parameter Tuning
Comprehensive sysctl optimization:
- Memory management (`vm.*`)
- Network stack (`net.*`)
- Scheduler behavior (`kernel.sched_*`)
- Filesystem caching
- TCP/IP stack tuning

### ✅ I/O Scheduler Selection
Optimized for different workloads:
- `bfq`: Balanced, fair queuing
- `kyber`: Low latency
- `mq-deadline`: Multi-queue deadline
- `none`: Direct submission (NVMe)

### ✅ Network Stack Optimization
Stage-based tuning:
- Buffer sizes (16MB → 128MB)
- BBR congestion control
- TCP Fast Open
- Window scaling
- Timestamps and SACK
- Custom queue discipline

### ✅ Swap/Memory Management
Intelligent memory tuning:
- Swappiness control
- Dirty page ratios
- Cache pressure
- Free memory thresholds
- Transparent huge pages

### ✅ Boot Parameter Modification
Automatic GRUB configuration:
- CPU mitigations toggle
- Kernel command-line parameters
- Cross-distro support (update-grub/grub-mkconfig)

### ✅ Wireless Driver Patches
Penetration testing readiness:
- Monitor mode support
- Packet injection
- Driver optimization
- Regulatory domain management

### ✅ Custom Kernel Compilation
*Coming in v0.1.0*

### ✅ GPU Optimization
*Coming in v0.1.0*

### ✅ Thermal Management
Performance-oriented thermal control:
- Performance thermal governor
- Laptop mode disabled
- Intelligent throttling

### ✅ Monitoring/Benchmarking
Before/after comparison:
- CPU stress testing (stress-ng)
- Memory bandwidth (sysbench)
- Disk I/O (dd)
- Network throughput
- Kernel parameter snapshots

### ✅ Profile Save/Load
*Coming in v0.1.0*

### ✅ Rollback Mechanism
Instant system restoration:
- Automatic backups before changes
- Critical file preservation
- Kernel parameter snapshots
- One-click restore

---

## 📊 Benchmarking

### Automatic Benchmarks

ShellShockTune runs comprehensive benchmarks:

```bash
# Before tuning
sudo shellshocktune
# Select "4. Benchmark System"

# Apply a stage
# Select "1. Select Tuning Stage" → Choose stage

# Compare results
# Select "5. Compare Performance"
```

### Benchmark Suite

1. **CPU Performance**
   - stress-ng with all cores
   - Bogo ops measurement
   - 10-second stress test

2. **Memory Bandwidth**
   - sysbench memory test
   - 1GB transfer
   - MB/sec measurement

3. **Disk I/O**
   - dd sequential write
   - 1GB test file
   - Throughput calculation

4. **Kernel Parameters**
   - Snapshot of critical sysctl values
   - Before/after comparison

### Sample Results

```
=== Before Tuning ===
CPU: 45000 bogo ops/s
Memory: 2500 MB/sec
Disk: 450 MB/s

=== After Stage 3 ===
CPU: 58000 bogo ops/s (+28%)
Memory: 3200 MB/sec (+28%)
Disk: 890 MB/s (+98%)
```

---

## 🗂️ Project Structure

```
shellshocktune/
├── shellshocktune          # Main orchestrator
├── install.sh              # Installation script
├── modules/
│   ├── cpu-governor/       # CPU frequency control
│   │   ├── cpu-governor.c
│   │   └── cpu-governor    (compiled)
│   ├── kernel/             # Kernel parameter modules
│   │   ├── memory.sh
│   │   ├── network.sh
│   │   └── scheduler.sh
│   ├── network/            # Network optimization
│   │   ├── tcp-tuning.sh
│   │   └── bbr.sh
│   ├── filesystem/         # Filesystem optimization
│   │   ├── io-scheduler.sh
│   │   └── mount-opts.sh
│   ├── security/           # Security tools installer
│   │   ├── wireless.sh
│   │   └── redteam.sh
│   └── monitoring/         # Benchmarking tools
│       ├── benchmark.sh
│       └── compare.sh
├── profiles/
│   ├── redteam.conf        # Stage 4 profile
│   ├── developer.conf      # Development profile
│   ├── extreme.conf        # Stage 3 profile
│   └── gaming.conf         # Gaming profile
├── scripts/
│   ├── apply-stage.sh      # Stage application logic
│   ├── verify.sh           # Verification script
│   ├── backup.sh           # Backup management
│   └── restore.sh          # Restoration script
├── LICENSE                 # MIT License
└── README.md              # This file
```

---

## 🔧 Advanced Usage

### Command-Line Mode

```bash
# Apply a stage directly
sudo shellshocktune --stage 2

# Run benchmark
sudo shellshocktune --benchmark

# Restore system
sudo shellshocktune --restore

# Load profile
sudo shellshocktune --profile redteam

# View current configuration
sudo shellshocktune --status
```

### Profile System

Create custom profiles in `profiles/`:

```ini
# custom.conf
STAGE=2
CPU_GOVERNOR=performance
IO_SCHEDULER=kyber
SWAPPINESS=5
NETWORK_BUFFERS=32MB
ENABLE_BBR=true
```

Load with:
```bash
sudo shellshocktune --profile custom
```

### Integration with Systemd

Auto-apply on boot:

```bash
# Create service
sudo systemctl edit --force --full shellshocktune.service
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

```bash
# Enable
sudo systemctl enable shellshocktune.service
```

---

## 🔍 Troubleshooting

### Common Issues

**Issue**: "cpu-governor failed to compile"
```bash
# Install build dependencies
# Arch
sudo pacman -S base-devel

# Debian/Ubuntu
sudo apt install build-essential

# Fedora
sudo dnf groupinstall "Development Tools"
```

**Issue**: "Cannot write to /sys/devices/..."
```bash
# Ensure running as root
sudo shellshocktune

# Check if cpufreq is available
ls /sys/devices/system/cpu/cpu0/cpufreq/
```

**Issue**: "Stage application failed"
```bash
# System automatically restores backup
# Check logs
sudo cat /var/log/shellshocktune.log

# Manual restore
sudo shellshocktune --restore
```

**Issue**: "Missing dependencies"
```bash
# Install manually
# Arch
sudo pacman -S dialog stress-ng sysbench

# Debian/Ubuntu
sudo apt install dialog stress-ng sysbench

# Fedora
sudo dnf install dialog stress-ng sysbench
```

### Logs

View detailed logs:
```bash
# Main log
sudo tail -f /var/log/shellshocktune.log

# Benchmark results
ls /var/lib/shellshocktune/backups/benchmarks/
```

---

## 🛡️ Safety & Recovery

### Automatic Backups

Before any changes, ShellShockTune backs up:
- `/etc/sysctl.conf`
- `/etc/sysctl.d/`
- `/etc/default/grub`
- `/etc/fstab`
- `/etc/security/limits.conf`
- `/etc/modprobe.d/`
- Current kernel parameters

### Instant Rollback

```bash
# Via menu
sudo shellshocktune
# Select "8. Restore System"

# Via command
sudo shellshocktune --restore
```

### Failure Handling

If stage application fails:
1. ❌ Error detected
2. 🔄 Automatic restore triggered
3. ✅ System reverted to backup
4. 📝 Error logged

No manual intervention needed.

---

## 🚀 Performance Tips

### For Maximum Performance (Stage 3/4)

1. **Disable unnecessary services**:
   ```bash
   sudo systemctl disable bluetooth.service
   sudo systemctl disable cups.service
   ```

2. **Use performance CPU governor**:
   Always active in Stage 2+

3. **Disable swap entirely** (if you have enough RAM):
   ```bash
   sudo swapoff -a
   # Comment out swap in /etc/fstab
   ```

4. **Use lightweight desktop environment**:
   - i3, Openbox, or XFCE
   - Disable compositing

5. **Optimize filesystem mount**:
   ```bash
   # /etc/fstab
   /dev/sda1 / ext4 noatime,nodiratime,discard 0 1
   ```

### For Gaming

1. Apply Stage 2 or 3
2. Disable compositor
3. Use `gamemode` integration (coming soon)
4. Close background applications

### For Pentesting/Security

1. Apply Stage 4
2. Verify wireless card supports monitor mode:
   ```bash
   sudo airmon-ng
   ```
3. Test packet injection:
   ```bash
   sudo aireplay-ng --test wlan0
   ```

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Fork** the repository
2. **Create** a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit** your changes
   ```bash
   git commit -m "Add amazing feature"
   ```
4. **Push** to your branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open** a Pull Request

### Development Setup

```bash
# Clone
git clone https://github.com/0xb0rn3/shellshocktune.git
cd shellshocktune

# Test locally
sudo ./shellshocktune

# Make changes
# Test thoroughly on multiple distributions
```

### Coding Standards

- Shell scripts: Follow ShellCheck recommendations
- Comments: Explain *why*, not *what*
- Error handling: Always use `set -euo pipefail`
- Logging: Use consistent log levels

---

## 📜 License

MIT License

Copyright (c) 2024 0xbv1 | 0xb0rn3 {shell shock}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## 👨‍💻 Author

**0xbv1 | 0xb0rn3 {shell shock}**

- 🌐 GitHub: [@0xb0rn3](https://github.com/0xb0rn3)
- 🐦 X/Twitter: [@oxbv1](https://twitter.com/oxbv1)
- 💬 Discord: `oxbv1`

---

## 🙏 Acknowledgments

- **cpu-governor**: Integrated module for CPU frequency control
- **Linux Community**: For endless documentation and support
- **Security Researchers**: For tool recommendations
- **Performance Engineers**: For optimization techniques

---

## 🗺️ Roadmap

### v0.1.0 (Next Release)
- [ ] Profile save/load functionality
- [ ] Command-line mode
- [ ] GPU optimization (CUDA/ROCm)
- [ ] Custom kernel compilation wizard
- [ ] Gamemode integration
- [ ] Real-time kernel support

### v0.2.0
- [ ] Web UI for remote management
- [ ] Multi-system orchestration
- [ ] Advanced monitoring dashboard
- [ ] Automated regression testing
- [ ] Container/VM optimization

### v1.0.0
- [ ] Stable API
- [ ] Plugin system
- [ ] Cloud provider optimization
- [ ] Comprehensive documentation
- [ ] Video tutorials

---

## 📚 Resources

### Documentation
- [Kernel Documentation](https://www.kernel.org/doc/html/latest/)
- [sysctl Parameters](https://www.kernel.org/doc/Documentation/sysctl/)
- [BBR Congestion Control](https://github.com/google/bbr)

### Related Projects
- [cpu-governor](https://github.com/0xb0rn3/cpu-governor)
- [linux-zen kernel](https://github.com/zen-kernel/zen-kernel)
- [GameMode](https://github.com/FeralInteractive/gamemode)

### Performance Testing
- [Phoronix Test Suite](https://www.phoronix-test-suite.com/)
- [stress-ng](https://kernel.ubuntu.com/~cking/stress-ng/)
- [sysbench](https://github.com/akopytov/sysbench)

---

<div align="center">

**Made with ⚡ for Linux power users and security professionals**

**Star ⭐ this repo if ShellShockTune helped you!**

</div>