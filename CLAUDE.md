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

### Backup System (Legacy → Modern)
- **Current**: BorgBackup with systemd timers → kDrive sync
- **Target**: restic + WebDAV direct integration to Infomaniak kDrive
- **Integration**: Shell aliases provide intuitive backup/restore commands
- **Location**: Migrating from `~/kDrive/INFORMATIQUE/PC_TUF/borgrepo` to `~/SAUVEGARDE/`

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
# Current BorgBackup (legacy)
borg-backup-now                  # Manual backup trigger
borg-list                       # List available archives
borg-restore-last               # Restore latest archive
borg-check-timer                # Verify systemd timer status

# Target restic commands (to be implemented)
restic-backup-now               # Manual restic backup
restic-list                     # List snapshots
restic-restore                  # Interactive restore
restic-mount                    # Mount backup as filesystem
```

### Security Management
```bash
# UFW management (functions_security.sh)
activer_ufw                     # Enable firewall with safe defaults
desactiver_ufw                  # Disable firewall
status_ufw                      # Show detailed firewall status
bloquer_tout                    # Emergency lockdown mode
```

## Refactoring Strategy: Borg → Restic Migration

### Phase 1: WebDAV Integration
1. **Install WebDAV tools**: `davfs2` for mounting Infomaniak kDrive
2. **Create mount point**: `~/SAUVEGARDE/` with automatic mounting
3. **Configure credentials**: Secure storage in `~/.davfs2/secrets`
4. **Systemd integration**: Auto-mount service for kDrive WebDAV

### Phase 2: Restic Installation & Configuration
1. **Install restic**: Latest binary with verification
2. **Repository initialization**: Encrypted repo in `~/SAUVEGARDE/restic-repo/`
3. **Configuration files**: `/etc/restic.conf` with environment variables
4. **Exclude patterns**: Migrate from `/etc/borg_excludes.txt` to restic format

### Phase 3: Systemd Services Migration
1. **New service files**: `restic-backup.service` and `restic-backup.timer`
2. **Script migration**: Convert `/usr/local/sbin/borg_*.sh` to restic equivalents
3. **Alias updates**: Update `mon_shell/aliases.sh` with restic commands
4. **Parallel operation**: Run both systems during transition

### Phase 4: Enhanced Geek Features
1. **Interactive tools**: `fzf` integration for backup browsing
2. **Monitoring**: Prometheus metrics, Grafana dashboards
3. **Notifications**: Desktop/email alerts for backup status
4. **Performance**: Parallel backups, compression optimization

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
- `borg_setup.sh`: Template for `restic_setup.sh` migration
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

### Backup System Changes
1. **Test in isolation**: Use separate repository for testing
2. **Maintain backward compatibility**: Keep existing aliases during transition
3. **Document changes**: Update both README files and alias comments
4. **Verify systemd integration**: Test timers and service dependencies

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
- **Backup management**: Parallel borg/restic with adaptive kDrive integration

This architecture enables a geek-friendly, highly automated Ubuntu configuration system with modern backup solutions, comprehensive CLI tools, and seamless cloud integration capabilities.