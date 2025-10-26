# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a comprehensive Ubuntu/Debian configuration system providing:
- **Multi-machine profile system** (`profiles/`) with automatic detection and adaptation
- **Modular shell environment** (`mon_shell/`) with color-coded functions, aliases, and system utilities
- **Automated backup system** with restic (AES-256 encryption and deduplication)
- **System maintenance tools** with integrated security, monitoring, and cleanup functions
- **Audio/hardware fixes** for modern Ubuntu systems (PipeWire, Bluetooth)

## Multi-Machine Profile System

### Overview
Automatic profile detection and loading system that adapts configuration based on the machine being used. Supports multiple machines with different hardware and usage patterns.

### Profile Structure (`profiles/`)
```
profiles/
├── machine_detector.sh      # Automatic machine detection
├── profile_loader.sh         # Orchestrated profile loading
├── TuF/                      # Desktop profile (gaming/production)
│   ├── config.sh
│   └── scripts/
│       └── fix_pipewire_bt.sh
├── PcDeV/                    # Ultraportable profile
│   └── config.sh
└── default/                  # Universal fallback
    └── config.sh
```

### Available Profiles

**TuF (Desktop):**
- **Type:** Desktop gaming/production
- **Mode:** PERFORMANCE (all modules loaded)
- **RAM:** 8GB+
- **Specific Features:**
  - PipeWire Bluetooth audio fix
  - Complete developer tools
  - Advanced system monitoring
  - Docker and virtualization support
- **Commands:** `fix-audio`, `restart-pipewire`, `status-audio`, `system-monitor`

**PcDeV (Ultraportable):**
- **Type:** Ultraportable laptop
- **Mode:** MINIMAL (essential modules only)
- **RAM:** 1-4GB
- **Specific Features:**
  - Battery optimization
  - WiFi/Bluetooth management
  - Brightness control
  - Eco/Performance modes
- **Commands:** `battery`, `eco-mode`, `perf-mode`, `wifi-on/off`, `bt-on/off`, `quick-status`

**default (Universal):**
- **Type:** Unknown/generic machine
- **Mode:** STANDARD (auto-detection)
- **RAM:** Variable
- **Specific Features:**
  - Balanced configuration
  - Automatic resource detection
  - Universal compatibility
- **Commands:** `system-info`, `quick-monitor`, `set-profile`, `show-profile`

### Automatic Detection
Detection priority order:
1. Manual configuration file (`~/.config/ubuntu-configs/machine_profile`)
2. Hostname matching (TuF, PcDeV)
3. Hardware characteristics (battery, RAM, audio devices)
4. Presence of specific scripts
5. Fallback to `default` profile

### Profile Management Commands
```bash
show-profile          # Display current profile
list-profiles         # List all available profiles
set-profile [name]    # Set profile manually (TuF|PcDeV|default)
switch-profile [name] # Same as set-profile
reload-profile        # Reload current profile
```

### Integration
The profile system integrates with:
- **Adaptive System:** Resource detection (MINIMAL/STANDARD/PERFORMANCE)
- **Module Loading:** Selective loading based on profile
- **Aliases:** Common + profile-specific commands
- **Shell RC Files:** Automatic loading via `.bashrc` and `.zshrc`

**Documentation:** See [README_PROFILS.md](README_PROFILS.md) for complete guide

## Architecture Overview

### Shell Configuration System (`mon_shell/`)
- **Modular Design**: 10 specialized modules with French naming for clarity
- **Color System**: Standardized color variables (`$VERT`, `$ROUGE`, etc.) for consistent UI
- **Module Categories**:
  - `utilitaires_systeme.sh`: System info, monitoring, maintenance
  - `outils_fichiers.sh`: Smart file management and organization
  - `outils_productivite.sh`: Notes, Pomodoro, password gen, tasks
  - `outils_developpeur.sh`: Project analysis, Git tools, dev servers
  - `outils_reseau.sh`: Network diagnostics, WiFi, connectivity
  - `outils_multimedia.sh`: Image/video/audio/PDF tools
  - `aide_memoire.sh`: Interactive help system (Git, system, network)
  - `raccourcis_pratiques.sh`: Ultra-fast navigation shortcuts
  - `nettoyage_securise.sh`: Ultra-secure cleanup with 4-level protection
  - `chargeur_modules.sh`: Intelligent module loading system
- **Loading Pattern**: Profile-based selective loading via `profile_loader.sh`
  - Loads modules appropriate to machine profile (minimal/standard/complete)
  - Integrated with `.bashrc` and `.zshrc` for automatic initialization

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