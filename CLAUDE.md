# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a comprehensive Ubuntu/Debian configuration system providing:
- **Modular shell environment** (`mon_shell/`) with color-coded functions, aliases, and system utilities
- **Automated backup system** (transitioning from BorgBackup to restic)
- **System maintenance tools** with integrated security, monitoring, and cleanup functions
- **Audio/hardware fixes** for modern Ubuntu systems (PipeWire, Bluetooth)

## Architecture Overview

### Shell Configuration System (`mon_shell/`)
- **Modular Design**: Separate files for aliases, colors, functions (system, security, utils)
- **Color System**: Standardized color variables (`$VERT`, `$ROUGE`, etc.) for consistent UI
- **Function Categories**:
  - `functions_system.sh`: System maintenance, snapshots, Docker, disk analysis
  - `functions_security.sh`: UFW firewall management
  - `functions_utils.sh`: Utility functions, dynamic alias creation, backups
- **Loading Pattern**: Both `.bashrc` and `.zshrc` source all `~/.mon_shell/*.sh` files

### Modern Backup System
- **Engine**: restic with AES-256 encryption and deduplication
- **Storage**: Adaptive local/cloud storage via WebDAV kDrive integration
- **Automation**: systemd timers with intelligent scheduling
- **Location**: `~/SAUVEGARDE/restic-repo` (adaptive symlink to local/cloud)

### Audio/Hardware Support (`script/son/`)
- PipeWire Bluetooth latency fixes
- Python environment setup
- Post-installation configuration scripts

## Key Commands

### Development & Maintenance
```bash
# Shell configuration testing
source ~/.zshrc                    # Reload shell environment
reload                            # Alias for shell reload with confirmation

# System maintenance (provided by functions_system.sh)
maj_ubuntu                        # Complete system update (apt, flatpak, snap)
snapshot_rapide                   # Create Timeshift snapshot
nettoyer_logs                     # Clean system journals
docker_mise_a_jour               # Docker cleanup and optimization
analyse_disque                    # Comprehensive disk analysis
```

### Backup Operations
```bash
# Modern Restic Backup System
backup-now                      # Manual backup trigger (restic)
backup-list                     # List snapshots
backup-restore                  # Interactive restore
backup-status                   # Check backup service status
backup-check                    # Verify repository integrity

# Advanced Operations
restic-mount                    # Mount backup as filesystem
restic-browser                  # Interactive snapshot browser (fzf)
restic-stats                    # Repository statistics
```

### Security Management
```bash
# UFW management (functions_security.sh)
activer_ufw                     # Enable firewall with safe defaults
desactiver_ufw                  # Disable firewall
status_ufw                      # Show detailed firewall status
bloquer_tout                    # Emergency lockdown mode
```

## Modern Backup Architecture

### Core Components
1. **WebDAV Integration**: `davfs2` for mounting Infomaniak kDrive
2. **Adaptive Storage**: Automatic switching between local/cloud storage
3. **Secure Configuration**: Credentials in `~/.davfs2/secrets` (600 permissions)
4. **Systemd Integration**: Auto-mount service and backup scheduling

### Restic Configuration
1. **Modern Engine**: Latest restic with AES-256 encryption
2. **Repository**: Encrypted repo in `~/SAUVEGARDE/restic-repo/` (adaptive symlink)
3. **Configuration**: `/etc/restic.conf` with secure environment variables
4. **Exclusions**: Optimized patterns in `/etc/restic_excludes.txt`

### Service Architecture
1. **Backup Service**: `restic-backup.service` with resource optimization
2. **Timer Schedule**: Intelligent scheduling with randomized delays
3. **Shell Integration**: Intuitive aliases and functions
4. **Monitoring**: Comprehensive logging and status checking

### Enhanced Features
1. **Interactive Tools**: `fzf` integration for snapshot browsing
2. **Adaptive Behavior**: Seamless local/cloud switching
3. **Performance**: Optimized compression and deduplication
4. **Security**: Multi-layer encryption and access control

## Modern Tool Integration

### Recommended Geek-Level Enhancements
```bash
# Modern CLI tools to integrate
sudo apt install fzf ripgrep fd-find bat exa zoxide
# Add to functions: fzf-powered file/backup browsing
# ripgrep integration for log analysis
# bat for syntax-highlighted file previews
```

### Shell Environment Enhancements
- **ZSH plugins**: Add `zsh-autosuggestions`, `zsh-syntax-highlighting`
- **Prompt enhancement**: Starship or Powerlevel10k integration
- **Command completion**: restic, docker, kubectl completions
- **Directory navigation**: `zoxide` for smart directory jumping

## Configuration Files Integration

### Critical Files to Maintain
- `mon_shell/aliases.sh`: Central command shortcuts
- Legacy system replaced by modern restic architecture
- Shell RC files: Consistent loading pattern across bash/zsh

### WebDAV Configuration Template
```bash
# /etc/davfs2/davfs2.conf additions
use_locks 0
if_match_bug 1
drop_weak_etags 1

# ~/.davfs2/secrets format
https://kDrive.infomaniak.com/remote.php/dav/files/USERNAME/ USERNAME PASSWORD
```

## Development Workflow

### Adding New Functions
1. **Choose appropriate file**: system, security, or utils based on function purpose
2. **Follow naming pattern**: `unalias function_name 2>/dev/null` before definition
3. **Use color system**: Employ `echo_color` with standardized color variables
4. **Test thoroughly**: Verify in both bash and zsh environments

### Backup System Management
1. **Test in isolation**: Use separate repository for testing
2. **Adaptive switching**: Use `kdrive_switch_mode` for storage backend changes
3. **Document changes**: Update README files and function comments
4. **Service monitoring**: Verify systemd timers and service dependencies

### Error Handling Standards
- All scripts use `set -euo pipefail` for strict error handling
- Functions provide colored status messages (success/warning/error)
- Critical operations include rollback mechanisms
- Logs are centralized in `/var/log/` with proper rotation

## Security Considerations

- Backup credentials stored securely with proper file permissions (600)
- WebDAV passwords not stored in plain text in scripts
- UFW configurations provide sensible defaults while maintaining usability
- All system modifications require explicit user confirmation

## Testing Strategy

```bash
# Function testing
source mon_shell/functions_system.sh && maj_ubuntu --dry-run

# Backup testing
restic check
restic backup --dry-run /home

# Integration testing
systemctl --user daemon-reload
systemctl status restic-backup.timer
```

## Complete System Enhancement

### Master Enhancement Script
The `enhance_ubuntu_geek.sh` script provides complete transformation:
- **Phase 1**: System updates and essential tools
- **Phase 2**: Modern shell (Oh My Zsh + plugins + Starship)
- **Phase 3**: Modern CLI tools (fzf, ripgrep, bat, exa, zoxide, etc.)
- **Phase 4**: Development environment (Node.js, Docker, Python)
- **Phase 5**: Security hardening (UFW, Fail2Ban, SSH)
- **Phase 6**: Integration of all configurations
- **Phase 7**: Performance optimizations

### Execution Order
```bash
# Complete transformation (recommended)
sudo ./enhance_ubuntu_geek.sh

# Or individual components
sudo ./setup_webdav_kdrive.sh
sudo ./setup_restic_modern.sh
```

### Post-Installation
- **Shell reload**: `source ~/.zshrc`
- **Modern navigation**: `z` (zoxide), `exa` instead of `ls`
- **Enhanced search**: `rg` instead of `grep`, `fd` instead of `find`
- **Interactive tools**: `fzf` for fuzzy finding, `lazygit` for Git TUI
- **Backup management**: Modern restic with adaptive kDrive integration

This architecture enables a geek-friendly, highly automated Ubuntu configuration system with modern backup solutions, comprehensive CLI tools, and seamless cloud integration capabilities.