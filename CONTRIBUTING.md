# 🤝 Contributing to ShellShockTune

Thank you for your interest in contributing to **ShellShockTune**! This document will guide you through the contribution process.

---

## 📁 Repository Structure

```
shellshocktune/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # CI/CD pipeline
│   │   └── release.yml         # Automated releases
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── module_submission.md
│   └── PULL_REQUEST_TEMPLATE.md
│
├── docs/
│   ├── API.md                  # Module API documentation
│   ├── ARCHITECTURE.md         # System architecture
│   ├── BENCHMARKS.md           # Performance benchmarks
│   ├── SECURITY.md             # Security considerations
│   └── TROUBLESHOOTING.md      # Common issues
│
├── modules/
│   ├── cpu-governor/           # CPU frequency control
│   │   └── README.md
│   ├── kernel/                 # Kernel parameter tuning
│   │   ├── memory.sh
│   │   ├── scheduler.sh
│   │   └── README.md
│   ├── network/                # Network stack optimization
│   │   ├── network.sh
│   │   ├── tcp.sh
│   │   ├── udp.sh
│   │   └── README.md
│   ├── filesystem/             # Filesystem & I/O
│   │   ├── io-scheduler.sh
│   │   ├── mount-opts.sh
│   │   └── README.md
│   ├── security/               # Security tools
│   │   ├── wireless.sh
│   │   ├── redteam.sh
│   │   └── README.md
│   ├── monitoring/             # Benchmarking & monitoring
│   │   ├── benchmark.sh
│   │   ├── compare.sh
│   │   └── README.md
│   └── _template/              # Module template
│       ├── template.sh
│       └── README.md
│
├── profiles/
│   ├── gaming.conf
│   ├── developer.conf
│   ├── extreme.conf
│   ├── redteam.conf
│   ├── server.conf
│   └── README.md
│
├── scripts/
│   ├── apply-stage.sh          # Stage application logic
│   ├── backup.sh               # Backup management
│   ├── restore.sh              # System restoration
│   ├── verify.sh               # Configuration verification
│   └── utils.sh                # Shared utilities
│
├── tests/
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   ├── e2e/                    # End-to-end tests
│   └── fixtures/               # Test data
│
├── shellshocktune              # Main executable
├── install.sh                  # Installation script
├── uninstall.sh                # Uninstallation script
│
├── LICENSE                     # MIT License
├── README.md                   # Main documentation
├── SETUP.md                    # Setup guide
├── CONTRIBUTING.md             # This file
├── CHANGELOG.md                # Version history
├── CODE_OF_CONDUCT.md          # Community guidelines
│
└── .shellcheckrc               # ShellCheck configuration
```

---

## 🚀 Getting Started

### 1. Fork the Repository

```bash
# Click "Fork" on GitHub, then:
git clone https://github.com/YOUR_USERNAME/shellshocktune.git
cd shellshocktune
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `bugfix/` - Bug fixes
- `module/` - New modules
- `docs/` - Documentation updates
- `test/` - Test additions/improvements

### 3. Make Your Changes

Follow our coding standards (see below).

### 4. Test Your Changes

```bash
# Run shellcheck
shellcheck shellshocktune scripts/*.sh modules/**/*.sh

# Test installation
sudo ./install.sh

# Test functionality
sudo ./shellshocktune
```

### 5. Commit Your Changes

```bash
git add .
git commit -m "feat: add support for XYZ"
```

Commit message format:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test additions
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `chore:` - Maintenance tasks

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

---

## 📝 Coding Standards

### Shell Script Standards

1. **Shebang**: Always use `#!/bin/bash`

2. **Strict Mode**: Start with
   ```bash
   set -euo pipefail
   ```

3. **Error Handling**: Use traps
   ```bash
   trap 'log ERROR "Failed at line $LINENO"' ERR
   ```

4. **Quoting**: Always quote variables
   ```bash
   # Good
   echo "$variable"
   
   # Bad
   echo $variable
   ```

5. **Functions**: Document with comments
   ```bash
   # Description of what function does
   # Args:
   #   $1 - First argument description
   # Returns:
   #   0 on success, 1 on failure
   function_name() {
       local arg1=$1
       # Implementation
   }
   ```

6. **Logging**: Use consistent logging
   ```bash
   log INFO "Starting process..."
   log SUCCESS "Process completed"
   log WARNING "Potential issue detected"
   log ERROR "Process failed"
   ```

7. **Indentation**: 4 spaces, no tabs

8. **Line Length**: Maximum 100 characters

9. **Comments**: Explain *why*, not *what*
   ```bash
   # Good: Disable swap to prevent disk thrashing under memory pressure
   swapoff -a
   
   # Bad: Turn off swap
   swapoff -a
   ```

10. **ShellCheck**: Must pass with no errors
    ```bash
    shellcheck your-script.sh
    ```

---

## 🧩 Creating a New Module

### Step 1: Copy the Template

```bash
cp modules/_template/template.sh modules/your-module/your-module.sh
```

### Step 2: Customize Module Information

```bash
MODULE_NAME="your_module"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="Your Name"
MODULE_DESCRIPTION="What your module does"
```

### Step 3: Implement Stage Functions

```bash
module_apply_stage_1() {
    # Stage 1 implementation
}

module_apply_stage_2() {
    # Stage 2 implementation
}

# ... stages 3 and 4
```

### Step 4: Add Tests

Create `tests/modules/test_your_module.sh`:

```bash
#!/bin/bash

test_module_stage_1() {
    # Test Stage 1 application
    modules/your-module/your-module.sh apply 1
    # Verify changes
    # Assert expectations
}

test_module_restore() {
    # Test restoration
}
```

### Step 5: Document Your Module

Create `modules/your-module/README.md`:

```markdown
# Your Module Name

## Description
What this module does

## Stages
- Stage 1: Description
- Stage 2: Description
- Stage 3: Description
- Stage 4: Description

## Safety
- Safety level: X/5
- Known risks: ...

## Dependencies
- package1
- package2

## Testing
How to test the module
```

### Step 6: Submit PR

Include:
- Module implementation
- Tests
- Documentation
- Example usage

---

## 🧪 Testing Guidelines

### Manual Testing

```bash
# Test on multiple distributions
# - Arch Linux
# - Ubuntu/Debian
# - Fedora

# Test scenarios:
1. Fresh installation
2. Stage application (all stages)
3. System restoration
4. Error conditions
5. Edge cases
```

### Automated Testing (Coming Soon)

```bash
# Run test suite
./tests/run_tests.sh

# Run specific test
./tests/run_tests.sh test_network_module
```

---

## 📋 Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code follows shell script standards
- [ ] Passes ShellCheck with no errors
- [ ] Tested on at least 2 Linux distributions
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] No hardcoded paths (use variables)
- [ ] Error handling implemented
- [ ] Logging statements added
- [ ] Backup/restore tested
- [ ] No breaking changes (or documented)

---

## 🐛 Bug Reports

### Before Reporting

1. Check existing issues
2. Search documentation
3. Try latest version
4. Test on clean system

### What to Include

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step one
2. Step two
3. ...

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Distribution: Arch Linux
- Kernel: 6.1.0
- ShellShockTune Version: 0.0.1

## Logs
```
Paste relevant logs from /var/log/shellshocktune.log
```

## Screenshots
If applicable
```

---

## 💡 Feature Requests

### Feature Request Template

```markdown
## Feature Description
Clear description of the feature

## Use Case
Why is this feature needed?

## Proposed Implementation
How should it work?

## Alternatives Considered
What other solutions did you consider?

## Additional Context
Any other information
```

---

## 🔐 Security

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Email: security@shellshocktune.example.com (or contact maintainer directly)

Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Considerations

When contributing:
- Never hardcode credentials
- Validate all inputs
- Use proper permissions (644 for files, 755 for executables)
- Backup before destructive operations
- Implement proper error handling
- Consider multi-user systems

---

## 📚 Documentation

### Documentation Standards

- Use Markdown
- Include code examples
- Add screenshots where helpful
- Keep language clear and concise
- Update relevant docs with code changes

### Documentation Structure

```markdown
# Feature Name

## Overview
Brief description

## Usage
```bash
# Example commands
```

## Options
| Option | Description | Default |
|--------|-------------|---------|
| --opt  | Description | value   |

## Examples
### Example 1
Description
```bash
command
```

## Notes
Important information

## See Also
- [Related Doc](link)
```

---

## 🎨 Code Style Examples

### Good Examples

```bash
#!/bin/bash
set -euo pipefail

# Global constants
readonly MODULE_NAME="example"
readonly CONFIG_FILE="/etc/example.conf"

# Function with proper documentation
# Applies network optimizations
# Args:
#   $1 - Stage number (1-4)
# Returns:
#   0 on success, 1 on failure
apply_network_optimization() {
    local stage=$1
    
    log INFO "Applying network optimization for stage $stage"
    
    # Backup before changes
    backup_file "$CONFIG_FILE"
    
    # Apply changes with error handling
    if ! write_config "parameter" "value"; then
        log ERROR "Failed to write configuration"
        return 1
    fi
    
    log SUCCESS "Network optimization applied"
    return 0
}

# Proper error handling
main() {
    if [[ $EUID -ne 0 ]]; then
        log ERROR "Root privileges required"
        exit 1
    fi
    
    apply_network_optimization "${1:-1}" || {
        log ERROR "Optimization failed"
        exit 1
    }
}

trap 'log ERROR "Script failed at line $LINENO"' ERR
main "$@"
```

### Bad Examples

```bash
#!/bin/bash
# No strict mode
# No error handling

apply() {
  # Unquoted variables
  echo $1
  
  # No error checking
  sysctl -w vm.swappiness=$2
  
  # No logging
  # No backup
  # Unclear function name
}

# No trap
# Minimal error handling
apply $1 $2
```

---

## 🏗️ Development Workflow

### 1. Planning Phase
- Discuss in GitHub Issues
- Get feedback from maintainers
- Create implementation plan

### 2. Development Phase
- Work in feature branch
- Commit frequently
- Test continuously

### 3. Review Phase
- Self-review code
- Run all tests
- Update documentation

### 4. Submission Phase
- Create PR
- Respond to feedback
- Make requested changes

### 5. Merge Phase
- Approved by maintainer
- Passes CI/CD
- Merged to main

---

## 🎯 Priority Areas

We especially welcome contributions in:

1. **New Modules**
   - GPU optimization
   - Disk I/O tuning
   - Container optimization
   - Gaming-specific tweaks

2. **Testing**
   - Automated test suite
   - CI/CD pipeline
   - Multi-distro testing

3. **Documentation**
   - Video tutorials
   - Translation
   - Use case examples

4. **Features**
   - Web UI
   - CLI enhancements
   - Profile system
   - Rollback improvements

---

## 📞 Communication

### Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: General questions, ideas
- **Discord**: `oxbv1` - Real-time chat
- **Twitter/X**: `@oxbv1` - Updates, announcements

### Response Times

- Critical bugs: 24-48 hours
- Feature requests: 1 week
- PRs: 3-5 days
- General questions: 2-3 days

---

## 🏆 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in module headers
- Given shoutouts on social media

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## ❓ Questions?

If you have questions about contributing:

1. Check existing documentation
2. Search closed issues
3. Ask in GitHub Discussions
4. Contact maintainer

---

**Thank you for contributing to ShellShockTune!**

*Making Linux faster, one commit at a time.* ⚡

*by 0xbv1 | 0xb0rn3 {shell shock}*