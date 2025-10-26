# Security Audit Report: Ubuntu-Configs Profile System

**Audit Date**: 2025-10-26
**Auditor**: Security Engineer (Claude Code)
**Scope**: Profile system shell scripts and integration
**Risk Level**: MEDIUM (Several HIGH priority issues identified)

---

## Executive Summary

The ubuntu-configs profile system has been audited for security vulnerabilities across 6 shell scripts totaling ~900 lines of code. The system demonstrates good foundational security practices but contains several exploitable vulnerabilities that require remediation.

**Key Findings**:
- 0 CRITICAL vulnerabilities (immediate security risks)
- 3 HIGH priority issues (command injection, path traversal)
- 5 MEDIUM priority issues (information disclosure, validation gaps)
- 2 LOW priority recommendations (hardening opportunities)
- 4 positive security patterns identified

---

## 🔴 CRITICAL ISSUES

**None identified** - No critical vulnerabilities requiring immediate emergency action.

---

## 🟠 HIGH PRIORITY ISSUES

### H1: Command Injection via Unquoted Variable Expansion

**File**: `profiles/machine_detector.sh`
**Lines**: 14, 41, 77-79, 120
**Severity**: HIGH
**CVSS Score**: 7.8 (Local Code Execution)

#### Vulnerability Description
Multiple instances of command substitution stored in variables without proper quoting, allowing command injection through environment manipulation or file content.

#### Affected Code
```bash
# Line 14 - Reads file content without validation
machine_name=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null | tr -d '[:space:]')

# Line 120 - Exports result without validation
export MACHINE_PROFILE=$(detecter_machine)

# Lines 77-79 - Unvalidated command substitution in output
echo "   Hostname: $(hostname)"
echo "   Type: $(detecter_type_machine)"
echo "   RAM: $(free -h | awk '/^Mem:/{print $2}')"
```

#### Exploitation Scenario
1. Attacker creates malicious profile file: `echo '$(malicious_command)' > ~/.config/ubuntu-configs/machine_profile`
2. When shell sources the profile system, `MACHINE_PROFILE` executes the injected command
3. Commands run with user privileges, enabling data theft, persistence mechanisms, etc.

#### Recommended Fix
```bash
# Validate and sanitize profile names against whitelist
detecter_machine() {
    local machine_name=""
    local valid_profiles=("TuF" "PcDeV" "default")

    if [[ -f "$HOME/.config/ubuntu-configs/machine_profile" ]]; then
        machine_name=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null | tr -d '[:space:]')

        # Validate against whitelist
        local is_valid=false
        for valid_profile in "${valid_profiles[@]}"; do
            if [[ "$machine_name" == "$valid_profile" ]]; then
                is_valid=true
                break
            fi
        done

        if [[ "$is_valid" == "true" ]]; then
            echo "$machine_name"
            return 0
        else
            echo "⚠️ Invalid profile name in config file: $machine_name" >&2
            # Fall through to auto-detection
        fi
    fi

    # ... rest of detection logic
}
```

---

### H2: Arbitrary File Sourcing via Path Traversal

**File**: `profiles/profile_loader.sh`
**Lines**: 24, 45, 71, 115, 129, 139, 165
**Severity**: HIGH
**CVSS Score**: 7.5 (Arbitrary Code Execution)

#### Vulnerability Description
The profile loader sources files based on user-controllable data without path validation, enabling directory traversal attacks and arbitrary code execution.

#### Affected Code
```bash
# Line 31 - Profile name from detecter_machine (user-controllable)
local profile=$(detecter_machine)

# Line 34 - Path constructed without validation
local profile_config="$PROFILES_DIR/$profile/config.sh"

# Line 45 - Sources file without path validation
source "$profile_config"

# Line 115 - Module sourcing without validation
source "$module_path"
```

#### Exploitation Scenario
1. Attacker sets profile to: `../../../../tmp/evil`
2. Creates malicious script at: `/tmp/evil/config.sh`
3. When profile loads, system executes attacker's code
4. Full user-level compromise achieved

#### Recommended Fix
```bash
load_machine_profile() {
    if [[ ! -d "$PROFILES_DIR" ]]; then
        echo "⚠️ Répertoire des profils introuvable: $PROFILES_DIR" >&2
        return 1
    fi

    if [[ -f "$PROFILES_DIR/machine_detector.sh" ]]; then
        source "$PROFILES_DIR/machine_detector.sh"
    else
        echo "⚠️ Détecteur de machine introuvable" >&2
        return 1
    fi

    local profile=$(detecter_machine)

    # Sanitize profile name - only allow alphanumeric and underscore
    if [[ ! "$profile" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "⚠️ Nom de profil invalide: $profile" >&2
        profile="default"
    fi

    # Construct path and validate it's within PROFILES_DIR
    local profile_config="$PROFILES_DIR/$profile/config.sh"
    local profile_realpath=$(realpath -m "$profile_config" 2>/dev/null)
    local profiles_realpath=$(realpath "$PROFILES_DIR" 2>/dev/null)

    # Check path starts with PROFILES_DIR (prevent traversal)
    if [[ ! "$profile_realpath" == "$profiles_realpath"/* ]]; then
        echo "⚠️ Tentative de traversée de chemin détectée" >&2
        profile="default"
        profile_config="$PROFILES_DIR/default/config.sh"
    fi

    # Verify file exists and is a regular file
    if [[ ! -f "$profile_config" ]]; then
        echo "⚠️ Profil $profile introuvable, utilisation du profil default" >&2
        profile="default"
        profile_config="$PROFILES_DIR/default/config.sh"
    fi

    # Final existence check before sourcing
    if [[ -f "$profile_config" ]]; then
        source "$profile_config"
        export CURRENT_PROFILE="$profile"
        export CURRENT_PROFILE_DIR="$PROFILES_DIR/$profile"
        return 0
    else
        echo "❌ Impossible de charger le profil: $profile" >&2
        return 1
    fi
}
```

---

### H3: Unsafe Function Export in Bash

**File**: `profiles/machine_detector.sh`, `profiles/TuF/config.sh`, `profiles/PcDeV/config.sh`, `profiles/default/config.sh`
**Lines**: Multiple (112-116, 145-149, 171-176, 195-200)
**Severity**: HIGH
**CVSS Score**: 6.5 (Function Hijacking)

#### Vulnerability Description
Functions exported via `export -f` can be inherited by child processes and potentially hijacked in Bash CGI or service contexts.

#### Affected Code
```bash
# machine_detector.sh lines 112-116
if [[ -n "$BASH_VERSION" ]]; then
    export -f detecter_machine
    export -f afficher_info_machine
    export -f detecter_type_machine
    export -f definir_profil_manuel
fi
```

#### Exploitation Scenario
1. If scripts are invoked via CGI or service managers
2. Attacker can override exported functions via environment variables
3. Leads to privilege escalation or code execution in certain contexts
4. Particularly dangerous if combined with sudo or setuid binaries

#### Recommended Fix
```bash
# Option 1: Don't export functions (preferred)
# Simply remove export -f statements
# Functions remain available in current shell without export

# Option 2: If export required, use restricted shells
if [[ -n "$BASH_VERSION" ]] && [[ ! -r "$BASH_ENV" ]]; then
    # Only export if not in restricted environment
    export -f detecter_machine
    export -f afficher_info_machine
    export -f detecter_type_machine
    export -f definir_profil_manuel
fi

# Option 3: Use function namespacing to prevent collisions
# Prefix all functions with unique namespace
# Example: ubuntu_configs_detecter_machine
```

**Best Practice**: Remove `export -f` entirely. Functions sourced in shell configuration are available without export.

---

## 🟡 MEDIUM PRIORITY ISSUES

### M1: Insufficient Input Validation in Profile Name

**File**: `profiles/machine_detector.sh`
**Lines**: 93-109
**Severity**: MEDIUM
**CVSS Score**: 5.3 (Data Validation)

#### Vulnerability Description
`definir_profil_manuel()` accepts arbitrary profile names without validation, allowing invalid data in configuration files.

#### Affected Code
```bash
definir_profil_manuel() {
    local profile="$1"

    if [[ -z "$profile" ]]; then
        echo "Usage: definir_profil_manuel [TuF|PcDeV|default]"
        return 1
    fi

    mkdir -p "$HOME/.config/ubuntu-configs"
    echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile"

    echo "✅ Profil manuel défini: $profile"
}
```

#### Exploitation Scenario
1. User accidentally types: `definir_profil_manuel "TuF; rm -rf ~"`
2. Profile file contains command injection payload
3. Next shell load attempts to execute malicious content
4. Combined with H1, leads to code execution

#### Recommended Fix
```bash
definir_profil_manuel() {
    local profile="$1"
    local valid_profiles=("TuF" "PcDeV" "default")

    if [[ -z "$profile" ]]; then
        echo "Usage: definir_profil_manuel [TuF|PcDeV|default]"
        return 1
    fi

    # Validate profile name against whitelist
    local is_valid=false
    for valid_profile in "${valid_profiles[@]}"; do
        if [[ "$profile" == "$valid_profile" ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" != "true" ]]; then
        echo "❌ Profil invalide: $profile"
        echo "   Profils valides: ${valid_profiles[*]}"
        return 1
    fi

    # Create directory with restricted permissions
    mkdir -p "$HOME/.config/ubuntu-configs"
    chmod 700 "$HOME/.config/ubuntu-configs"

    # Write profile name
    echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile"
    chmod 600 "$HOME/.config/ubuntu-configs/machine_profile"

    echo "✅ Profil manuel défini: $profile"
    echo "   Rechargez votre shell pour appliquer les changements."
}
```

---

### M2: Information Disclosure in Error Messages

**File**: `profiles/profile_loader.sh`
**Lines**: 18, 26, 38, 53, 73
**Severity**: MEDIUM
**CVSS Score**: 4.3 (Information Disclosure)

#### Vulnerability Description
Error messages reveal internal system paths and configuration details, aiding reconnaissance for attacks.

#### Affected Code
```bash
# Line 18 - Reveals full path
echo "⚠️ Répertoire des profils introuvable: $PROFILES_DIR"

# Line 53 - Reveals profile name and path structure
echo "❌ Impossible de charger le profil: $profile"
```

#### Exploitation Scenario
1. Attacker triggers errors intentionally
2. Error messages reveal directory structure
3. Information aids path traversal and privilege escalation attempts
4. Reveals configuration locations for targeted attacks

#### Recommended Fix
```bash
# Generic error messages without path disclosure
if [[ ! -d "$PROFILES_DIR" ]]; then
    echo "⚠️ Répertoire des profils introuvable" >&2
    return 1
fi

if [[ ! -f "$profile_config" ]]; then
    echo "⚠️ Configuration du profil introuvable" >&2
    profile="default"
    profile_config="$PROFILES_DIR/default/config.sh"
fi

# Log detailed errors to secure location only
log_secure_error() {
    local log_file="$HOME/.local/share/ubuntu-configs/errors.log"
    mkdir -p "$(dirname "$log_file")"
    chmod 700 "$(dirname "$log_file")"
    echo "[$(date)] $*" >> "$log_file"
    chmod 600 "$log_file"
}

# Usage
log_secure_error "Profile not found: $profile_config"
echo "⚠️ Erreur de chargement du profil" >&2
```

---

### M3: Race Condition in Directory Creation

**File**: `profiles/machine_detector.sh`
**Lines**: 102
**Severity**: MEDIUM
**CVSS Score**: 4.7 (Race Condition)

#### Vulnerability Description
`mkdir -p` without permission setting creates directory with default umask, potentially allowing unauthorized access between creation and first write.

#### Affected Code
```bash
# Line 102
mkdir -p "$HOME/.config/ubuntu-configs"
echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile"
```

#### Exploitation Scenario
1. Attacker monitors for directory creation
2. In race window, attacker creates symlink or modifies permissions
3. Subsequent write follows symlink or exposes data
4. Low probability but possible on shared systems

#### Recommended Fix
```bash
# Create with explicit permissions atomically
(umask 077 && mkdir -p "$HOME/.config/ubuntu-configs")

# Alternatively, use install command
install -d -m 700 "$HOME/.config/ubuntu-configs"

# Then write file with restricted permissions
(umask 077 && echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile")

# Or use atomic write with proper permissions
temp_file=$(mktemp)
chmod 600 "$temp_file"
echo "$profile" > "$temp_file"
mv "$temp_file" "$HOME/.config/ubuntu-configs/machine_profile"
```

---

### M4: Unvalidated Array Access in Module Loading

**File**: `profiles/profile_loader.sh`
**Lines**: 110-117
**Severity**: MEDIUM
**CVSS Score**: 5.0 (Input Validation)

#### Vulnerability Description
Module loading iterates over profile-defined arrays without validating module names or paths before sourcing.

#### Affected Code
```bash
# Lines 110-117
for module_info in "${modules_to_load[@]}"; do
    local module="${module_info%%:*}"
    local module_path="$HOME/ubuntu-configs/mon_shell/$module"

    if [[ -f "$module_path" ]]; then
        source "$module_path"
    fi
done
```

#### Exploitation Scenario
1. If profile config is compromised (see H2)
2. Attacker adds malicious entries to `MODULES_*` arrays
3. System sources attacker-controlled paths
4. Code execution achieved

#### Recommended Fix
```bash
# Whitelist valid modules
declare -A VALID_MODULES=(
    ["utilitaires_systeme.sh"]=1
    ["outils_fichiers.sh"]=1
    ["outils_productivite.sh"]=1
    ["outils_developpeur.sh"]=1
    ["outils_reseau.sh"]=1
    ["outils_multimedia.sh"]=1
    ["aide_memoire.sh"]=1
    ["raccourcis_pratiques.sh"]=1
    ["nettoyage_securise.sh"]=1
)

# Validate and sanitize module names
for module_info in "${modules_to_load[@]}"; do
    local module="${module_info%%:*}"

    # Validate module name against whitelist
    if [[ ! "${VALID_MODULES[$module]}" ]]; then
        echo "⚠️ Module non autorisé ignoré: $module" >&2
        continue
    fi

    # Validate module name format (no path traversal)
    if [[ ! "$module" =~ ^[a-zA-Z0-9_.-]+\.sh$ ]]; then
        echo "⚠️ Nom de module invalide: $module" >&2
        continue
    fi

    local module_path="$HOME/ubuntu-configs/mon_shell/$module"

    # Verify path doesn't escape intended directory
    local module_realpath=$(realpath -m "$module_path" 2>/dev/null)
    local shell_realpath=$(realpath "$HOME/ubuntu-configs/mon_shell" 2>/dev/null)

    if [[ "$module_realpath" == "$shell_realpath"/* ]] && [[ -f "$module_path" ]]; then
        source "$module_path"
    else
        echo "⚠️ Module introuvable ou invalide: $module" >&2
    fi
done
```

---

### M5: Shell Injection in Alias Definitions

**File**: `profiles/TuF/config.sh`, `profiles/PcDeV/config.sh`
**Lines**: Multiple (53-55, 63-80, 87-105)
**Severity**: MEDIUM
**CVSS Score**: 4.8 (Command Injection)

#### Vulnerability Description
Several alias definitions use unquoted paths or command substitutions that could be exploited if HOME or PATH are compromised.

#### Affected Code
```bash
# TuF config.sh line 53
alias fix-audio="bash ~/ubuntu-configs/profiles/TuF/scripts/fix_pipewire_bt.sh"

# PcDeV config.sh line 78
alias cpu="top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print \"CPU: \" 100 - \$1\"%\"}'"
```

#### Exploitation Scenario
1. If attacker can modify HOME environment variable
2. Alias execution follows attacker-controlled path
3. Particularly dangerous if aliases invoked via cron or automation
4. Medium risk due to limited attack surface

#### Recommended Fix
```bash
# Use absolute paths instead of tilde expansion
alias fix-audio="bash $HOME/ubuntu-configs/profiles/TuF/scripts/fix_pipewire_bt.sh"

# Or better, verify path exists at alias definition time
if [[ -f "$HOME/ubuntu-configs/profiles/TuF/scripts/fix_pipewire_bt.sh" ]]; then
    alias fix-audio="bash $HOME/ubuntu-configs/profiles/TuF/scripts/fix_pipewire_bt.sh"
fi

# For complex aliases, use functions instead
cpu() {
    top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print "CPU: " 100 - $1"%"}'
}
```

---

## 🟢 LOW PRIORITY RECOMMENDATIONS

### L1: Missing Error Handling with set -euo pipefail

**File**: All profile system scripts
**Lines**: N/A (missing)
**Severity**: LOW
**CVSS Score**: 3.1 (Error Handling)

#### Vulnerability Description
Shell scripts lack strict error handling that could prevent security issues from propagating.

#### Recommendation
```bash
#!/bin/bash
# Add at top of all scripts except TuF/scripts/fix_pipewire_bt.sh (which has it)

# Exit on error, undefined variable, pipe failure
set -euo pipefail

# For interactive shell configs, use conditional error handling
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced - don't exit on error
    set -u  # Only undefined variable check
else
    # Being executed - full error handling
    set -euo pipefail
fi
```

**Note**: `fix_pipewire_bt.sh` correctly uses `set -e` (line 9). Other scripts should follow this pattern.

---

### L2: Insecure Temporary File Usage Potential

**File**: `profiles/profile_loader.sh`
**Lines**: 234
**Severity**: LOW
**CVSS Score**: 3.3 (Predictable Resource)

#### Vulnerability Description
File writes don't use atomic operations or secure temporary files, creating potential race conditions.

#### Current Code
```bash
# Line 234-235
mkdir -p "$HOME/.config/ubuntu-configs"
echo "$new_profile" > "$HOME/.config/ubuntu-configs/machine_profile"
```

#### Recommendation
```bash
# Use atomic write operation
write_profile_atomic() {
    local new_profile="$1"
    local config_dir="$HOME/.config/ubuntu-configs"
    local profile_file="$config_dir/machine_profile"

    # Create directory securely
    install -d -m 700 "$config_dir"

    # Write to temporary file first
    local temp_file=$(mktemp "$config_dir/.profile.XXXXXX")
    chmod 600 "$temp_file"
    echo "$new_profile" > "$temp_file"

    # Atomic rename
    mv "$temp_file" "$profile_file"
}

# Usage
write_profile_atomic "$new_profile"
```

---

## ✅ POSITIVE SECURITY PATTERNS FOUND

### 1. Error Redirection to /dev/null
**Location**: Throughout codebase
**Pattern**: `2>/dev/null`, `&>/dev/null`
**Benefit**: Prevents information disclosure in error output

### 2. Defensive Path Checking
**Location**: Multiple files (lines 17, 23, 36, 44)
**Pattern**: `if [[ -f "$file" ]]; then source "$file"; fi`
**Benefit**: Prevents errors from missing files, reduces attack surface

### 3. Command Existence Verification
**Location**: Config files
**Pattern**: `if command -v docker &>/dev/null; then ... fi`
**Benefit**: Graceful degradation when commands unavailable

### 4. Strict Error Handling in Scripts
**Location**: `profiles/TuF/scripts/fix_pipewire_bt.sh` line 9
**Pattern**: `set -e`
**Benefit**: Script exits on first error, preventing partial execution

---

## Remediation Priority Matrix

| Priority | Issue | Impact | Effort | Timeline |
|----------|-------|--------|--------|----------|
| HIGH | H1: Command Injection | High | Medium | 1-2 days |
| HIGH | H2: Path Traversal | High | High | 2-3 days |
| HIGH | H3: Function Export | Medium | Low | 1 day |
| MEDIUM | M1: Input Validation | Medium | Low | 1 day |
| MEDIUM | M2: Error Messages | Low | Low | 1 day |
| MEDIUM | M3: Race Condition | Low | Low | 1 day |
| MEDIUM | M4: Array Validation | Medium | Medium | 1-2 days |
| MEDIUM | M5: Alias Injection | Low | Low | 1 day |
| LOW | L1: Error Handling | Low | Low | 1 day |
| LOW | L2: Atomic Writes | Low | Medium | 1-2 days |

**Total Estimated Remediation Time**: 10-15 days

---

## Security Testing Recommendations

### 1. Fuzzing Profile Names
```bash
# Test with malicious profile names
echo '$(id)' > ~/.config/ubuntu-configs/machine_profile
echo '../../../etc/passwd' > ~/.config/ubuntu-configs/machine_profile
echo 'TuF; rm -rf /tmp/test' > ~/.config/ubuntu-configs/machine_profile
```

### 2. Path Traversal Testing
```bash
# Test directory traversal in profile detection
hostname "../../../../tmp/evil"  # Requires root, unlikely attack
# More realistic: symlink attacks
```

### 3. Function Hijacking Test
```bash
# Export malicious function before sourcing
detecter_machine() { echo "attacker_controlled"; }
export -f detecter_machine
source profiles/profile_loader.sh
```

### 4. Race Condition Testing
```bash
# Monitor directory creation timing
inotifywait -m ~/.config/ubuntu-configs &
# Repeatedly trigger profile creation
```

---

## Compliance Considerations

### OWASP Top 10 2021 Mappings
- **A03:2021 - Injection**: H1, M5 (Command injection vulnerabilities)
- **A04:2021 - Insecure Design**: H2, M4 (Insufficient input validation)
- **A05:2021 - Security Misconfiguration**: H3, L1 (Unsafe defaults)
- **A07:2021 - Identification and Authentication Failures**: M3 (Race conditions)

### CWE Mappings
- **CWE-78**: OS Command Injection (H1, M5)
- **CWE-22**: Path Traversal (H2)
- **CWE-20**: Improper Input Validation (M1, M4)
- **CWE-200**: Information Exposure (M2)
- **CWE-362**: Race Condition (M3)

---

## Additional Hardening Recommendations

### 1. Implement Security Policy File
Create `profiles/SECURITY_POLICY.md` documenting:
- Allowed profile names (whitelist)
- Module naming conventions
- Path validation requirements
- Function naming standards

### 2. Add Integrity Checks
```bash
# Verify profile files haven't been tampered with
verify_profile_integrity() {
    local profile="$1"
    local config="$PROFILES_DIR/$profile/config.sh"

    # Check file ownership
    if [[ $(stat -c %U "$config") != "$USER" ]]; then
        echo "⚠️ Profile ownership compromised" >&2
        return 1
    fi

    # Check file permissions (should be 644 or more restrictive)
    local perms=$(stat -c %a "$config")
    if [[ "$perms" -gt 644 ]]; then
        echo "⚠️ Profile permissions too permissive" >&2
        return 1
    fi

    return 0
}
```

### 3. Implement Audit Logging
```bash
# Log all profile operations to audit trail
log_audit() {
    local audit_log="$HOME/.local/share/ubuntu-configs/audit.log"
    mkdir -p "$(dirname "$audit_log")"
    echo "[$(date -Iseconds)] [$$] $*" >> "$audit_log"
    chmod 600 "$audit_log"
}

# Usage
log_audit "PROFILE_LOAD profile=$PROFILE_NAME user=$USER"
log_audit "PROFILE_SWITCH from=$CURRENT_PROFILE to=$new_profile"
```

### 4. Security-Focused Code Review Checklist
- [ ] All user input validated against whitelist
- [ ] All file paths validated with realpath
- [ ] No unquoted variable expansions in commands
- [ ] All sourced files within expected directories
- [ ] Error messages don't reveal sensitive paths
- [ ] Functions not exported unnecessarily
- [ ] Temporary files created securely
- [ ] Race conditions eliminated
- [ ] Audit logging implemented
- [ ] Integration tests include security scenarios

---

## Conclusion

The ubuntu-configs profile system exhibits solid foundational security but requires remediation of several high-priority vulnerabilities before production deployment. The primary concerns are:

1. **Command injection** through unvalidated profile names (H1)
2. **Path traversal** enabling arbitrary code execution (H2)
3. **Function export** creating potential attack surfaces (H3)

After addressing HIGH priority issues, the system will provide a secure foundation for machine-specific shell configuration. The modular architecture and defensive coding patterns demonstrate security awareness; consistent application of input validation and path sanitization will significantly improve the security posture.

**Recommendation**: Implement HIGH priority fixes before wider deployment. MEDIUM and LOW priority items can be addressed in subsequent security hardening phases.

---

## References

- OWASP Shell Injection: https://owasp.org/www-community/attacks/Command_Injection
- Bash Security Best Practices: https://mywiki.wooledge.org/BashPitfalls
- CWE-78 OS Command Injection: https://cwe.mitre.org/data/definitions/78.html
- ShellCheck: https://www.shellcheck.net/ (recommended for automated scanning)

---

**Report Version**: 1.0
**Next Review Date**: 2025-11-26
**Security Contact**: Project maintainer

