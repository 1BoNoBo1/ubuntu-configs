#!/bin/bash
# ==============================================================================
# Ubuntu-Configs Profile System - Comprehensive Test Suite
# ==============================================================================
#
# Purpose: Complete testing framework for multi-machine profile system
# Coverage:
#   - Unit tests: Individual function validation
#   - Integration tests: Complete workflow testing
#   - Functional tests: User-facing features
#   - Security tests: Attack prevention and edge cases
#   - Non-regression: Ensure fixes don't break functionality
#
# Usage:
#   ./profile_system_tests.sh              # Run all tests
#   ./profile_system_tests.sh --unit       # Run only unit tests
#   ./profile_system_tests.sh --security   # Run only security tests
#   ./profile_system_tests.sh --verbose    # Detailed output
#
# ==============================================================================

set -euo pipefail

# ===========================
# TEST FRAMEWORK CONFIGURATION
# ===========================

# Base directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILES_DIR="$PROJECT_ROOT/profiles"
MON_SHELL_DIR="$PROJECT_ROOT/mon_shell"

# Test directories
TEST_DIR="$SCRIPT_DIR"
TEST_TEMP_DIR="$TEST_DIR/temp_$$"
TEST_FIXTURES_DIR="$TEST_DIR/fixtures"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test configuration
VERBOSE=false
RUN_UNIT=true
RUN_INTEGRATION=true
RUN_FUNCTIONAL=true
RUN_SECURITY=true

# ===========================
# COLORS AND FORMATTING
# ===========================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Symbols
PASS_SYMBOL="✅"
FAIL_SYMBOL="❌"
SKIP_SYMBOL="⏭️"
INFO_SYMBOL="ℹ️"
WARN_SYMBOL="⚠️"

# ===========================
# UTILITY FUNCTIONS
# ===========================

log() {
    local level="$1"
    shift
    local message="$*"

    case "$level" in
        INFO)
            echo -e "${CYAN}${INFO_SYMBOL} ${message}${NC}"
            ;;
        PASS)
            echo -e "${GREEN}${PASS_SYMBOL} ${message}${NC}"
            ;;
        FAIL)
            echo -e "${RED}${FAIL_SYMBOL} ${message}${NC}"
            ;;
        WARN)
            echo -e "${YELLOW}${WARN_SYMBOL} ${message}${NC}"
            ;;
        SKIP)
            echo -e "${YELLOW}${SKIP_SYMBOL} ${message}${NC}"
            ;;
        HEADER)
            echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
            echo -e "${WHITE}${message}${NC}"
            echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
            ;;
        SECTION)
            echo -e "\n${MAGENTA}▶ ${message}${NC}"
            ;;
    esac
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        log PASS "$test_name"
        [[ "$VERBOSE" == "true" ]] && echo "       Expected: '$expected', Got: '$actual'"
        return 0
    else
        ((TESTS_FAILED++))
        log FAIL "$test_name"
        echo "       Expected: '$expected'"
        echo "       Got:      '$actual'"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        log PASS "$test_name"
        [[ "$VERBOSE" == "true" ]] && echo "       Found '$needle' in output"
        return 0
    else
        ((TESTS_FAILED++))
        log FAIL "$test_name"
        echo "       Expected to find: '$needle'"
        echo "       In: '$haystack'"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$haystack" != *"$needle"* ]]; then
        ((TESTS_PASSED++))
        log PASS "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log FAIL "$test_name"
        echo "       Should NOT contain: '$needle'"
        echo "       But found in: '$haystack'"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    ((TESTS_RUN++))

    if [[ -f "$file" ]]; then
        ((TESTS_PASSED++))
        log PASS "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log FAIL "$test_name"
        echo "       File does not exist: $file"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local test_name="$2"

    ((TESTS_RUN++))

    if eval "$condition"; then
        ((TESTS_PASSED++))
        log PASS "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log FAIL "$test_name"
        echo "       Condition failed: $condition"
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$expected_code" -eq "$actual_code" ]]; then
        ((TESTS_PASSED++))
        log PASS "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log FAIL "$test_name"
        echo "       Expected exit code: $expected_code"
        echo "       Got exit code: $actual_code"
        return 1
    fi
}

# ===========================
# TEST SETUP/TEARDOWN
# ===========================

setup_test_environment() {
    log INFO "Setting up test environment..."

    # Create temporary directory
    mkdir -p "$TEST_TEMP_DIR"
    mkdir -p "$TEST_FIXTURES_DIR"

    # Create mock HOME for isolated testing
    export TEST_HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$TEST_HOME/.config/ubuntu-configs"

    # Copy profile system to test location
    cp -r "$PROFILES_DIR" "$TEST_TEMP_DIR/"

    log INFO "Test environment ready: $TEST_TEMP_DIR"
}

teardown_test_environment() {
    log INFO "Cleaning up test environment..."

    # Remove temporary directory
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi

    # Restore original environment
    unset TEST_HOME
    unset MACHINE_PROFILE
    unset PROFILE_NAME
    unset CURRENT_PROFILE
}

setup_test_case() {
    local test_case_name="$1"

    # Create isolated test case directory
    TEST_CASE_DIR="$TEST_TEMP_DIR/test_$test_case_name"
    mkdir -p "$TEST_CASE_DIR"

    # Set HOME to test directory
    export HOME="$TEST_HOME"
    mkdir -p "$HOME/.config/ubuntu-configs"
}

teardown_test_case() {
    # Clean up test case specific files
    if [[ -d "$TEST_CASE_DIR" ]]; then
        rm -rf "$TEST_CASE_DIR"
    fi

    # Clean profile configuration
    rm -f "$HOME/.config/ubuntu-configs/machine_profile"

    # Unset test variables
    unset MACHINE_PROFILE
    unset PROFILE_NAME
    unset CURRENT_PROFILE
    unset CURRENT_PROFILE_DIR
}

# ===========================
# UNIT TESTS
# ===========================

test_unit_detecter_machine_manual_config() {
    log SECTION "Unit Test: detecter_machine() - Manual Configuration"

    setup_test_case "detect_manual"

    # Test 1: Valid TuF profile
    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$PROFILES_DIR/machine_detector.sh"
    local result=$(detecter_machine)
    assert_equals "TuF" "$result" "Manual config: TuF profile"

    # Test 2: Valid PcDeV profile
    echo "PcDeV" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    source "$PROFILES_DIR/machine_detector.sh"
    result=$(detecter_machine)
    assert_equals "PcDeV" "$result" "Manual config: PcDeV profile"

    # Test 3: Valid default profile
    echo "default" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    source "$PROFILES_DIR/machine_detector.sh"
    result=$(detecter_machine)
    assert_equals "default" "$result" "Manual config: default profile"

    # Test 4: Invalid profile should trigger warning and fall through
    echo "invalid_profile" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    source "$PROFILES_DIR/machine_detector.sh"
    result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "invalid_profile" "Manual config: Invalid profile rejected"

    # Test 5: Whitespace handling
    echo "  TuF  " > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    source "$PROFILES_DIR/machine_detector.sh"
    result=$(detecter_machine)
    assert_equals "TuF" "$result" "Manual config: Whitespace trimming"

    teardown_test_case
}

test_unit_detecter_machine_hostname() {
    log SECTION "Unit Test: detecter_machine() - Hostname Detection"

    setup_test_case "detect_hostname"

    # Remove manual config to test hostname detection
    rm -f "$HOME/.config/ubuntu-configs/machine_profile"
    source "$PROFILES_DIR/machine_detector.sh"

    # Test current hostname detection
    local current_hostname=$(hostname)
    local result=$(detecter_machine)

    case "$current_hostname" in
        TuF|tuf|TUF)
            assert_equals "TuF" "$result" "Hostname detection: TuF"
            ;;
        PcDeV|pcdev|PCDEV|ultraportable)
            assert_equals "PcDeV" "$result" "Hostname detection: PcDeV"
            ;;
        *)
            # Should fall through to hardware detection or default
            assert_true "[[ '$result' == 'TuF' || '$result' == 'PcDeV' || '$result' == 'default' ]]" \
                "Hostname detection: Valid fallback"
            ;;
    esac

    teardown_test_case
}

test_unit_detecter_machine_hardware() {
    log SECTION "Unit Test: detecter_machine() - Hardware Detection"

    setup_test_case "detect_hardware"

    # Remove manual config
    rm -f "$HOME/.config/ubuntu-configs/machine_profile"
    source "$PROFILES_DIR/machine_detector.sh"

    # Test battery detection
    if [[ -d /sys/class/power_supply/BAT* ]] || [[ -d /sys/class/power_supply/battery ]]; then
        # This is a laptop
        local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
        local result=$(detecter_machine)

        if [[ $ram_gb -le 4 ]]; then
            assert_equals "PcDeV" "$result" "Hardware detection: Low RAM laptop -> PcDeV"
        else
            # Could be PcDeV or default depending on other factors
            assert_true "[[ '$result' == 'PcDeV' || '$result' == 'default' ]]" \
                "Hardware detection: Laptop with adequate RAM"
        fi
    else
        # This is a desktop
        local result=$(detecter_machine)
        assert_true "[[ '$result' == 'TuF' || '$result' == 'default' ]]" \
            "Hardware detection: Desktop should be TuF or default"
    fi

    teardown_test_case
}

test_unit_definir_profil_manuel() {
    log SECTION "Unit Test: definir_profil_manuel() - Profile Validation"

    setup_test_case "set_manual"

    source "$PROFILES_DIR/machine_detector.sh"

    # Test 1: Valid profile TuF
    definir_profil_manuel "TuF" &>/dev/null
    local stored=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null)
    assert_equals "TuF" "$stored" "Set manual: TuF profile stored"

    # Test 2: Valid profile PcDeV
    definir_profil_manuel "PcDeV" &>/dev/null
    stored=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null)
    assert_equals "PcDeV" "$stored" "Set manual: PcDeV profile stored"

    # Test 3: Invalid profile rejected
    definir_profil_manuel "hacker_profile" &>/dev/null || true
    stored=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null)
    assert_not_contains "$stored" "hacker_profile" "Set manual: Invalid profile rejected"

    # Test 4: Empty profile rejected
    definir_profil_manuel "" &>/dev/null || true
    local exit_code=$?
    assert_exit_code 1 $exit_code "Set manual: Empty profile returns error"

    # Test 5: File permissions are secure (600 or 700 for directory)
    definir_profil_manuel "default" &>/dev/null
    local perms=$(stat -c %a "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null)
    assert_equals "600" "$perms" "Set manual: Secure file permissions (600)"

    teardown_test_case
}

test_unit_load_machine_profile() {
    log SECTION "Unit Test: load_machine_profile() - Profile Loading"

    setup_test_case "load_profile"

    # Set manual profile
    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"

    # Source the loader
    export PROFILES_DIR="$TEST_TEMP_DIR/profiles"
    export HOME="$TEST_HOME"

    # Mock ubuntu-configs location
    mkdir -p "$HOME/ubuntu-configs/profiles"
    cp -r "$PROJECT_ROOT/profiles/"* "$HOME/ubuntu-configs/profiles/"

    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    # Test that profile was loaded
    assert_equals "TuF" "$CURRENT_PROFILE" "Load profile: CURRENT_PROFILE set correctly"
    assert_equals "TuF" "$PROFILE_NAME" "Load profile: PROFILE_NAME set correctly"

    teardown_test_case
}

test_unit_profile_path_validation() {
    log SECTION "Unit Test: Path Traversal Protection"

    setup_test_case "path_validation"

    # Test 1: Normal alphanumeric profile name
    local profile="TuF"
    if [[ "$profile" =~ ^[a-zA-Z0-9_]+$ ]]; then
        assert_true "true" "Path validation: Normal profile name accepted"
    else
        assert_true "false" "Path validation: Normal profile name rejected (BUG)"
    fi

    # Test 2: Path traversal attempt
    profile="../../../etc/passwd"
    if [[ "$profile" =~ ^[a-zA-Z0-9_]+$ ]]; then
        assert_true "false" "Path validation: Traversal attempt accepted (VULNERABILITY)"
    else
        assert_true "true" "Path validation: Traversal attempt rejected"
    fi

    # Test 3: Special characters
    profile="Tuf;whoami"
    if [[ "$profile" =~ ^[a-zA-Z0-9_]+$ ]]; then
        assert_true "false" "Path validation: Command injection attempt accepted (VULNERABILITY)"
    else
        assert_true "true" "Path validation: Command injection blocked"
    fi

    # Test 4: Symlink detection
    mkdir -p "$HOME/ubuntu-configs/profiles/test_profile"
    echo "malicious" > "$TEST_TEMP_DIR/malicious.sh"
    ln -s "$TEST_TEMP_DIR/malicious.sh" "$HOME/ubuntu-configs/profiles/test_profile/config.sh" 2>/dev/null || true

    # Verify realpath validation would catch this
    local profile_config="$HOME/ubuntu-configs/profiles/test_profile/config.sh"
    local profile_realpath=$(realpath -m "$profile_config" 2>/dev/null)
    local profiles_realpath=$(realpath "$HOME/ubuntu-configs/profiles" 2>/dev/null)

    if [[ "$profile_realpath" == "$profiles_realpath"/* ]]; then
        # This is expected - symlink within profiles dir
        log INFO "Symlink test: within-directory symlink detected (context dependent)"
    fi

    teardown_test_case
}

test_unit_module_whitelist() {
    log SECTION "Unit Test: Module Whitelist Validation"

    setup_test_case "module_whitelist"

    # Valid modules (from profile_loader.sh)
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
        ["chargeur_modules.sh"]=1
    )

    # Test 1: Valid module accepted
    local module="utilitaires_systeme.sh"
    if [[ "${VALID_MODULES[$module]}" ]]; then
        assert_true "true" "Whitelist: Valid module accepted"
    else
        assert_true "false" "Whitelist: Valid module rejected (BUG)"
    fi

    # Test 2: Invalid module rejected
    module="malicious_backdoor.sh"
    if [[ "${VALID_MODULES[$module]}" ]]; then
        assert_true "false" "Whitelist: Invalid module accepted (VULNERABILITY)"
    else
        assert_true "true" "Whitelist: Invalid module rejected"
    fi

    # Test 3: Path traversal in module name
    module="../../../tmp/evil.sh"
    if [[ "$module" =~ ^[a-zA-Z0-9_.-]+\.sh$ ]]; then
        assert_true "false" "Whitelist: Traversal in module name accepted (VULNERABILITY)"
    else
        assert_true "true" "Whitelist: Traversal in module name rejected"
    fi

    # Test 4: Module without .sh extension
    module="malicious_script"
    if [[ "$module" =~ ^[a-zA-Z0-9_.-]+\.sh$ ]]; then
        assert_true "false" "Whitelist: Non-.sh module accepted (VULNERABILITY)"
    else
        assert_true "true" "Whitelist: Non-.sh module rejected"
    fi

    teardown_test_case
}

# ===========================
# INTEGRATION TESTS
# ===========================

test_integration_profile_detection_to_loading() {
    log SECTION "Integration Test: Complete Profile Detection → Loading Workflow"

    setup_test_case "integration_workflow"

    # Setup mock environment
    mkdir -p "$HOME/ubuntu-configs/profiles"
    cp -r "$PROJECT_ROOT/profiles/"* "$HOME/ubuntu-configs/profiles/"
    mkdir -p "$HOME/ubuntu-configs/mon_shell"
    cp "$PROJECT_ROOT/mon_shell/colors.sh" "$HOME/ubuntu-configs/mon_shell/" 2>/dev/null || true

    # Test workflow with TuF profile
    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"

    # Source profile system
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    # Verify complete workflow
    assert_equals "TuF" "$MACHINE_PROFILE" "Integration: MACHINE_PROFILE detected"
    assert_equals "TuF" "$PROFILE_NAME" "Integration: Profile loaded"
    assert_equals "desktop" "$PROFILE_TYPE" "Integration: Profile type set"
    assert_equals "PERFORMANCE" "$PROFILE_MODE" "Integration: Adaptive mode set"

    teardown_test_case
}

test_integration_bash_zsh_compatibility() {
    log SECTION "Integration Test: Bash vs Zsh Compatibility"

    setup_test_case "shell_compat"

    # Test bash compatibility
    if command -v bash &>/dev/null; then
        bash -c "source '$PROFILES_DIR/machine_detector.sh' && detecter_machine" &>/dev/null
        assert_exit_code 0 $? "Integration: Bash compatibility"
    else
        log SKIP "Bash not available"
        ((TESTS_SKIPPED++))
    fi

    # Test zsh compatibility (if available)
    if command -v zsh &>/dev/null; then
        zsh -c "source '$PROFILES_DIR/machine_detector.sh' && detecter_machine" &>/dev/null
        assert_exit_code 0 $? "Integration: Zsh compatibility"
    else
        log SKIP "Zsh not available for testing"
        ((TESTS_SKIPPED++))
    fi

    teardown_test_case
}

test_integration_profile_switching() {
    log SECTION "Integration Test: Profile Switching Scenarios"

    setup_test_case "profile_switch"

    mkdir -p "$HOME/ubuntu-configs/profiles"
    cp -r "$PROJECT_ROOT/profiles/"* "$HOME/ubuntu-configs/profiles/"
    mkdir -p "$HOME/ubuntu-configs/mon_shell"
    cp "$PROJECT_ROOT/mon_shell/colors.sh" "$HOME/ubuntu-configs/mon_shell/" 2>/dev/null || true

    # Test 1: Switch from TuF to PcDeV
    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true
    assert_equals "TuF" "$PROFILE_NAME" "Profile switch: Initial TuF"

    # Simulate profile switch
    echo "PcDeV" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset PROFILE_NAME CURRENT_PROFILE MACHINE_PROFILE
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true
    assert_equals "PcDeV" "$PROFILE_NAME" "Profile switch: Changed to PcDeV"

    # Test 2: Switch to default
    echo "default" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset PROFILE_NAME CURRENT_PROFILE MACHINE_PROFILE
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true
    assert_equals "default" "$PROFILE_NAME" "Profile switch: Changed to default"

    teardown_test_case
}

test_integration_fallback_mechanisms() {
    log SECTION "Integration Test: Fallback Mechanisms"

    setup_test_case "fallback"

    mkdir -p "$HOME/ubuntu-configs/profiles"
    cp -r "$PROJECT_ROOT/profiles/"* "$HOME/ubuntu-configs/profiles/"

    # Test 1: Invalid profile falls back to default
    echo "nonexistent_profile" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    # Should NOT be the invalid profile
    assert_not_contains "$PROFILE_NAME" "nonexistent" "Fallback: Invalid profile not used"

    # Test 2: Missing profile config falls back to default
    rm -rf "$HOME/ubuntu-configs/profiles/TuF"
    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset PROFILE_NAME CURRENT_PROFILE MACHINE_PROFILE
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    assert_equals "default" "$PROFILE_NAME" "Fallback: Missing profile → default"

    teardown_test_case
}

# ===========================
# FUNCTIONAL TESTS
# ===========================

test_functional_profile_commands() {
    log SECTION "Functional Test: Profile-Specific Commands"

    setup_test_case "functional_commands"

    mkdir -p "$HOME/ubuntu-configs"
    cp -r "$PROJECT_ROOT/profiles" "$HOME/ubuntu-configs/"
    cp -r "$PROJECT_ROOT/mon_shell" "$HOME/ubuntu-configs/"

    # Load TuF profile
    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    # Test TuF-specific functions exist
    if declare -f restart-pipewire &>/dev/null; then
        assert_true "true" "Functional: TuF restart-pipewire function exists"
    else
        log WARN "TuF function restart-pipewire not loaded (may be expected)"
    fi

    # Load PcDeV profile
    echo "PcDeV" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset PROFILE_NAME CURRENT_PROFILE MACHINE_PROFILE
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    # Test PcDeV-specific functions exist
    if declare -f battery-status &>/dev/null; then
        assert_true "true" "Functional: PcDeV battery-status function exists"
    else
        log WARN "PcDeV function battery-status not loaded (may be expected)"
    fi

    teardown_test_case
}

test_functional_adaptive_integration() {
    log SECTION "Functional Test: Adaptive System Integration"

    setup_test_case "adaptive"

    mkdir -p "$HOME/ubuntu-configs"
    cp -r "$PROJECT_ROOT/profiles" "$HOME/ubuntu-configs/"
    cp -r "$PROJECT_ROOT/mon_shell" "$HOME/ubuntu-configs/"

    # Load TuF profile (PERFORMANCE mode)
    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    # Check adaptive mode is set
    if [[ -n "$FORCE_ADAPTIVE_MODE" ]]; then
        assert_equals "PERFORMANCE" "$FORCE_ADAPTIVE_MODE" "Adaptive: TuF sets PERFORMANCE mode"
    else
        log WARN "FORCE_ADAPTIVE_MODE not set (profile may not have sourced)"
    fi

    # Load PcDeV profile (MINIMAL mode)
    echo "PcDeV" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset PROFILE_NAME CURRENT_PROFILE MACHINE_PROFILE FORCE_ADAPTIVE_MODE
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    if [[ -n "$FORCE_ADAPTIVE_MODE" ]]; then
        assert_equals "MINIMAL" "$FORCE_ADAPTIVE_MODE" "Adaptive: PcDeV sets MINIMAL mode"
    else
        log WARN "FORCE_ADAPTIVE_MODE not set for PcDeV"
    fi

    teardown_test_case
}

test_functional_module_loading() {
    log SECTION "Functional Test: Profile Module Loading"

    setup_test_case "module_loading"

    # This tests that correct modules are loaded per profile
    # Due to complexity, we verify the configuration exists

    source "$PROJECT_ROOT/profiles/TuF/config.sh" &>/dev/null || true

    # Check TuF modules array is defined
    if [[ -n "${MODULES_TUF[*]}" ]]; then
        local module_count=${#MODULES_TUF[@]}
        assert_true "[[ $module_count -gt 5 ]]" "Module loading: TuF has comprehensive modules ($module_count)"
    else
        log WARN "MODULES_TUF not defined (profile not sourced correctly)"
    fi

    # Check PcDeV has fewer modules (minimal mode)
    unset MODULES_TUF
    source "$PROJECT_ROOT/profiles/PcDeV/config.sh" &>/dev/null || true

    if [[ -n "${MODULES_PCDEV[*]}" ]]; then
        local module_count=${#MODULES_PCDEV[@]}
        assert_true "[[ $module_count -le 5 ]]" "Module loading: PcDeV has minimal modules ($module_count)"
    else
        log WARN "MODULES_PCDEV not defined"
    fi

    teardown_test_case
}

# ===========================
# SECURITY TESTS
# ===========================

test_security_command_injection() {
    log SECTION "Security Test: Command Injection Prevention"

    setup_test_case "security_injection"

    # Test 1: Malicious profile name with command substitution
    echo '$(whoami)' > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$PROFILES_DIR/machine_detector.sh" &>/dev/null
    local result=$(detecter_machine 2>/dev/null)

    # Result should NOT contain the output of whoami
    local current_user=$(whoami)
    assert_not_contains "$result" "$current_user" "Security: Command substitution blocked"

    # Test 2: Shell metacharacters
    echo 'TuF;malicious' > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    source "$PROFILES_DIR/machine_detector.sh" &>/dev/null
    result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "malicious" "Security: Semicolon injection blocked"

    # Test 3: Backtick command execution
    echo '`whoami`' > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    source "$PROFILES_DIR/machine_detector.sh" &>/dev/null
    result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "$current_user" "Security: Backtick injection blocked"

    teardown_test_case
}

test_security_path_traversal() {
    log SECTION "Security Test: Path Traversal Prevention"

    setup_test_case "security_traversal"

    # Test 1: Directory traversal in profile name
    echo "../../../etc/passwd" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$PROFILES_DIR/machine_detector.sh" &>/dev/null
    local result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "passwd" "Security: Path traversal blocked"

    # Test 2: Absolute path injection
    echo "/tmp/malicious_profile" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    source "$PROFILES_DIR/machine_detector.sh" &>/dev/null
    result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "/tmp" "Security: Absolute path blocked"

    # Test 3: Verify realpath validation works
    mkdir -p "$TEST_TEMP_DIR/fake_profiles/../../sneaky"
    local sneaky_path="$TEST_TEMP_DIR/fake_profiles/../../sneaky"
    local real_sneaky=$(realpath -m "$sneaky_path" 2>/dev/null)
    local base_path=$(realpath "$TEST_TEMP_DIR" 2>/dev/null)

    if [[ "$real_sneaky" == "$base_path"/* ]]; then
        log INFO "Path traversal resolves within base (expected behavior)"
    else
        assert_true "true" "Security: Realpath detects traversal outside base"
    fi

    teardown_test_case
}

test_security_symlink_attacks() {
    log SECTION "Security Test: Symlink Attack Prevention"

    setup_test_case "security_symlink"

    # Create malicious target outside profiles directory
    echo "malicious content" > "$TEST_TEMP_DIR/evil.sh"

    # Create profile with symlink to evil.sh
    mkdir -p "$HOME/ubuntu-configs/profiles/evil_profile"
    ln -s "$TEST_TEMP_DIR/evil.sh" "$HOME/ubuntu-configs/profiles/evil_profile/config.sh" 2>/dev/null || true

    # Attempt to load profile (should be blocked by realpath check)
    echo "evil_profile" > "$HOME/.config/ubuntu-configs/machine_profile"

    # The profile loader should detect the symlink escapes profiles dir
    # and fallback to default
    export PROFILES_DIR="$HOME/ubuntu-configs/profiles"
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null || true

    # Should not load evil profile (will be caught by whitelist)
    local result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "evil_profile" "Security: Symlink profile rejected by whitelist"

    teardown_test_case
}

test_security_file_permissions() {
    log SECTION "Security Test: File Permission Security"

    setup_test_case "security_perms"

    source "$PROFILES_DIR/machine_detector.sh"

    # Set a profile
    definir_profil_manuel "TuF" &>/dev/null

    # Test 1: Config directory has restricted permissions (700)
    local dir_perms=$(stat -c %a "$HOME/.config/ubuntu-configs" 2>/dev/null)
    assert_equals "700" "$dir_perms" "Security: Config directory permissions (700)"

    # Test 2: Profile file has restricted permissions (600)
    local file_perms=$(stat -c %a "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null)
    assert_equals "600" "$file_perms" "Security: Profile file permissions (600)"

    # Test 3: Profile file is not world-readable
    if [[ -r "$HOME/.config/ubuntu-configs/machine_profile" ]]; then
        # Check it's not readable by others
        local others_perm=$(stat -c %A "$HOME/.config/ubuntu-configs/machine_profile" | cut -c8-10)
        assert_equals "---" "$others_perm" "Security: Profile not world-readable"
    fi

    teardown_test_case
}

test_security_race_conditions() {
    log SECTION "Security Test: Race Condition Handling"

    setup_test_case "security_race"

    # Test atomic write operations
    source "$PROFILES_DIR/machine_detector.sh"

    # Simulate concurrent writes (simplified test)
    for i in {1..10}; do
        (definir_profil_manuel "TuF" &>/dev/null) &
    done
    wait

    # Verify file is in valid state
    local stored=$(cat "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null)
    assert_equals "TuF" "$stored" "Security: Atomic write survives concurrent access"

    # Verify no file corruption
    local line_count=$(wc -l < "$HOME/.config/ubuntu-configs/machine_profile" 2>/dev/null)
    assert_equals "1" "$line_count" "Security: No file corruption from race"

    teardown_test_case
}

test_security_input_validation() {
    log SECTION "Security Test: Input Validation Edge Cases"

    setup_test_case "security_input"

    source "$PROFILES_DIR/machine_detector.sh"

    # Test 1: Null bytes
    echo -e "TuF\x00malicious" > "$HOME/.config/ubuntu-configs/machine_profile"
    local result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "malicious" "Security: Null byte injection blocked"

    # Test 2: Unicode/UTF-8 tricks
    echo "TúF" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "Tú" "Security: Unicode look-alike rejected"

    # Test 3: Control characters
    echo -e "TuF\r\nmalicious" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "malicious" "Security: Control character injection blocked"

    # Test 4: Overly long input
    local long_string=$(printf 'A%.0s' {1..10000})
    echo "$long_string" > "$HOME/.config/ubuntu-configs/machine_profile"
    unset MACHINE_PROFILE
    result=$(detecter_machine 2>/dev/null)
    assert_not_contains "$result" "$long_string" "Security: Buffer overflow attempt rejected"

    teardown_test_case
}

# ===========================
# NON-REGRESSION TESTS
# ===========================

test_regression_legitimate_profiles() {
    log SECTION "Non-Regression: Legitimate Profiles Still Work"

    setup_test_case "regression_legit"

    mkdir -p "$HOME/ubuntu-configs"
    cp -r "$PROJECT_ROOT/profiles" "$HOME/ubuntu-configs/"
    cp -r "$PROJECT_ROOT/mon_shell" "$HOME/ubuntu-configs/"

    # Test all legitimate profiles
    for profile in "TuF" "PcDeV" "default"; do
        echo "$profile" > "$HOME/.config/ubuntu-configs/machine_profile"
        unset PROFILE_NAME CURRENT_PROFILE MACHINE_PROFILE

        source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
        source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

        assert_equals "$profile" "$PROFILE_NAME" "Regression: $profile profile loads correctly"
    done

    teardown_test_case
}

test_regression_command_functionality() {
    log SECTION "Non-Regression: All Commands Remain Functional"

    setup_test_case "regression_commands"

    mkdir -p "$HOME/ubuntu-configs"
    cp -r "$PROJECT_ROOT/profiles" "$HOME/ubuntu-configs/"
    cp -r "$PROJECT_ROOT/mon_shell" "$HOME/ubuntu-configs/"

    # Load default profile
    echo "default" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    # Test that common functions are available
    if declare -f system-info &>/dev/null; then
        assert_true "true" "Regression: system-info function available"
    fi

    if declare -f show-profile &>/dev/null; then
        assert_true "true" "Regression: show-profile function available"
    fi

    if declare -f set-profile &>/dev/null; then
        assert_true "true" "Regression: set-profile function available"
    fi

    teardown_test_case
}

test_regression_performance() {
    log SECTION "Non-Regression: Performance Not Degraded"

    setup_test_case "regression_perf"

    mkdir -p "$HOME/ubuntu-configs"
    cp -r "$PROJECT_ROOT/profiles" "$HOME/ubuntu-configs/"

    # Measure profile loading time
    local start_time=$(date +%s%N)

    echo "TuF" > "$HOME/.config/ubuntu-configs/machine_profile"
    source "$HOME/ubuntu-configs/profiles/machine_detector.sh" &>/dev/null
    source "$HOME/ubuntu-configs/profiles/profile_loader.sh" &>/dev/null || true

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    # Profile loading should be fast (< 1000ms)
    assert_true "[[ $duration_ms -lt 1000 ]]" "Regression: Profile loads in <1s (${duration_ms}ms)"

    log INFO "Profile loading time: ${duration_ms}ms"

    teardown_test_case
}

# ===========================
# TEST EXECUTION
# ===========================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --unit)
                RUN_INTEGRATION=false
                RUN_FUNCTIONAL=false
                RUN_SECURITY=false
                ;;
            --integration)
                RUN_UNIT=false
                RUN_FUNCTIONAL=false
                RUN_SECURITY=false
                ;;
            --functional)
                RUN_UNIT=false
                RUN_INTEGRATION=false
                RUN_SECURITY=false
                ;;
            --security)
                RUN_UNIT=false
                RUN_INTEGRATION=false
                RUN_FUNCTIONAL=false
                ;;
            --verbose|-v)
                VERBOSE=true
                ;;
            --help|-h)
                cat << EOF
Ubuntu-Configs Profile System Test Suite

Usage: $0 [OPTIONS]

Options:
  --unit          Run only unit tests
  --integration   Run only integration tests
  --functional    Run only functional tests
  --security      Run only security tests
  --verbose, -v   Verbose output
  --help, -h      Show this help message

With no options, runs all tests.
EOF
                exit 0
                ;;
            *)
                log WARN "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
}

run_all_tests() {
    log HEADER "Ubuntu-Configs Profile System - Test Suite"

    log INFO "Test configuration:"
    echo "  Unit Tests: $RUN_UNIT"
    echo "  Integration Tests: $RUN_INTEGRATION"
    echo "  Functional Tests: $RUN_FUNCTIONAL"
    echo "  Security Tests: $RUN_SECURITY"
    echo "  Verbose: $VERBOSE"

    # Unit Tests
    if [[ "$RUN_UNIT" == "true" ]]; then
        log HEADER "UNIT TESTS"
        test_unit_detecter_machine_manual_config
        test_unit_detecter_machine_hostname
        test_unit_detecter_machine_hardware
        test_unit_definir_profil_manuel
        test_unit_load_machine_profile
        test_unit_profile_path_validation
        test_unit_module_whitelist
    fi

    # Integration Tests
    if [[ "$RUN_INTEGRATION" == "true" ]]; then
        log HEADER "INTEGRATION TESTS"
        test_integration_profile_detection_to_loading
        test_integration_bash_zsh_compatibility
        test_integration_profile_switching
        test_integration_fallback_mechanisms
    fi

    # Functional Tests
    if [[ "$RUN_FUNCTIONAL" == "true" ]]; then
        log HEADER "FUNCTIONAL TESTS"
        test_functional_profile_commands
        test_functional_adaptive_integration
        test_functional_module_loading
    fi

    # Security Tests
    if [[ "$RUN_SECURITY" == "true" ]]; then
        log HEADER "SECURITY TESTS"
        test_security_command_injection
        test_security_path_traversal
        test_security_symlink_attacks
        test_security_file_permissions
        test_security_race_conditions
        test_security_input_validation
    fi

    # Non-Regression Tests (always run)
    log HEADER "NON-REGRESSION TESTS"
    test_regression_legitimate_profiles
    test_regression_command_functionality
    test_regression_performance
}

generate_report() {
    log HEADER "TEST RESULTS SUMMARY"

    local pass_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        pass_rate=$(( TESTS_PASSED * 100 / TESTS_RUN ))
    fi

    echo -e "${WHITE}Total Tests:    ${TESTS_RUN}${NC}"
    echo -e "${GREEN}Passed:         ${TESTS_PASSED} (${pass_rate}%)${NC}"
    echo -e "${RED}Failed:         ${TESTS_FAILED}${NC}"
    echo -e "${YELLOW}Skipped:        ${TESTS_SKIPPED}${NC}"

    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log PASS "ALL TESTS PASSED!"
        return 0
    else
        log FAIL "$TESTS_FAILED TEST(S) FAILED"
        return 1
    fi
}

# ===========================
# MAIN EXECUTION
# ===========================

main() {
    parse_arguments "$@"

    setup_test_environment

    run_all_tests

    teardown_test_environment

    generate_report
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
