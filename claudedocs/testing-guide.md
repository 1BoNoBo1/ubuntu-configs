# Profile System Testing Guide

## Overview

Comprehensive testing documentation for the ubuntu-configs multi-machine profile system with automatic detection, security hardening, and adaptive module loading.

## Test Suite Architecture

### Test Categories

1. **Unit Tests** - Individual function validation
   - Profile detection methods (5-level priority)
   - Manual profile setting and validation
   - Path validation and security checks
   - Module whitelist enforcement

2. **Integration Tests** - Complete workflow testing
   - Profile detection → loading → module initialization
   - Bash/Zsh shell compatibility
   - Profile switching scenarios
   - Fallback mechanisms

3. **Functional Tests** - User-facing feature validation
   - Profile-specific commands (fix-audio, battery, eco-mode)
   - Adaptive system integration (MINIMAL/STANDARD/PERFORMANCE)
   - Module loading per profile
   - Profile management commands

4. **Security Tests** - Attack prevention and edge cases
   - Command injection prevention
   - Path traversal protection
   - Symlink attack mitigation
   - File permission security
   - Race condition handling
   - Input validation (null bytes, unicode, control chars)

5. **Non-Regression Tests** - Ensure fixes don't break functionality
   - Legitimate profiles remain functional
   - All commands work correctly
   - Performance not degraded

## Quick Start

### Run All Tests

```bash
cd ~/ubuntu-configs/tests
chmod +x profile_system_tests.sh
./profile_system_tests.sh
```

### Run Specific Test Categories

```bash
# Unit tests only
./profile_system_tests.sh --unit

# Integration tests only
./profile_system_tests.sh --integration

# Functional tests only
./profile_system_tests.sh --functional

# Security tests only
./profile_system_tests.sh --security

# Verbose output
./profile_system_tests.sh --verbose
```

## Test Coverage Matrix

### Unit Tests (7 test functions)

| Test Function | Coverage | Key Validations |
|--------------|----------|----------------|
| `test_unit_detecter_machine_manual_config` | Manual configuration file detection (Priority 1) | Valid profiles (TuF/PcDeV/default), invalid profile rejection, whitespace handling |
| `test_unit_detecter_machine_hostname` | Hostname-based detection (Priority 2) | Hostname matching, case-insensitivity, fallback to hardware detection |
| `test_unit_detecter_machine_hardware` | Hardware characteristics detection (Priority 3-4) | Battery presence, RAM-based classification, desktop vs laptop |
| `test_unit_definir_profil_manuel` | Manual profile setting function | Whitelist validation, secure file permissions (600), atomic writes |
| `test_unit_load_machine_profile` | Profile loader functionality | Profile sourcing, environment variable setting, error handling |
| `test_unit_profile_path_validation` | Path security validation | Regex validation, traversal prevention, special character blocking |
| `test_unit_module_whitelist` | Module whitelist enforcement | Valid module acceptance, invalid rejection, path injection prevention |

### Integration Tests (4 test functions)

| Test Function | Workflow Tested | Success Criteria |
|--------------|-----------------|------------------|
| `test_integration_profile_detection_to_loading` | Complete detection → loading pipeline | All environment variables set correctly (MACHINE_PROFILE, PROFILE_NAME, PROFILE_TYPE, PROFILE_MODE) |
| `test_integration_bash_zsh_compatibility` | Shell compatibility | Scripts execute without errors in both bash and zsh |
| `test_integration_profile_switching` | Profile change scenarios | Successful transition between TuF → PcDeV → default with correct state |
| `test_integration_fallback_mechanisms` | Error recovery | Invalid profiles fall back to default, missing configs handled gracefully |

### Functional Tests (3 test functions)

| Test Function | Features Tested | Expected Behavior |
|--------------|----------------|-------------------|
| `test_functional_profile_commands` | Profile-specific commands | TuF: restart-pipewire, fix-audio; PcDeV: battery-status, eco-mode; default: system-info |
| `test_functional_adaptive_integration` | Adaptive mode integration | TuF sets PERFORMANCE, PcDeV sets MINIMAL, default uses STANDARD |
| `test_functional_module_loading` | Profile module arrays | TuF loads comprehensive modules (>5), PcDeV loads minimal (≤5) |

### Security Tests (6 test functions)

| Test Function | Attack Vector | Mitigation Verified |
|--------------|---------------|---------------------|
| `test_security_command_injection` | Command substitution $(), backticks, semicolons | Whitelist validation blocks execution |
| `test_security_path_traversal` | ../ sequences, absolute paths | Regex + realpath validation prevents traversal |
| `test_security_symlink_attacks` | Symlinks outside profiles directory | Realpath resolution detects escapes |
| `test_security_file_permissions` | World-readable config files | Directory 700, files 600 permissions enforced |
| `test_security_race_conditions` | Concurrent profile writes | Atomic writes with umask 077 |
| `test_security_input_validation` | Null bytes, unicode, control chars, buffer overflow | Whitespace stripping + whitelist validation |

### Non-Regression Tests (3 test functions)

| Test Function | Validation | Ensures |
|--------------|-----------|---------|
| `test_regression_legitimate_profiles` | All valid profiles load | Security fixes don't break TuF/PcDeV/default |
| `test_regression_command_functionality` | User commands available | Functions remain accessible after changes |
| `test_regression_performance` | Profile load time < 1000ms | No performance degradation from security enhancements |

## Test Results Interpretation

### Output Format

```
═══════════════════════════════════════════════════════
UNIT TESTS
═══════════════════════════════════════════════════════

▶ Unit Test: detecter_machine() - Manual Configuration
✅ Manual config: TuF profile
✅ Manual config: PcDeV profile
✅ Manual config: default profile
✅ Manual config: Invalid profile rejected
✅ Manual config: Whitespace trimming

...

═══════════════════════════════════════════════════════
TEST RESULTS SUMMARY
═══════════════════════════════════════════════════════
Total Tests:    45
Passed:         43 (95%)
Failed:         2
Skipped:        0

❌ 2 TEST(S) FAILED
```

### Success Indicators

- ✅ **Green checkmark**: Test passed
- ❌ **Red X**: Test failed (investigation required)
- ⏭️ **Skip symbol**: Test skipped (missing dependencies)
- ⚠️ **Warning**: Non-critical issue or expected limitation

### Common Failure Scenarios

1. **Permission Errors**
   - Cause: Test runs without proper file system access
   - Fix: Ensure test script is executable and user has write access to `tests/temp_*`

2. **Missing Dependencies**
   - Cause: `realpath`, `stat`, or other system commands unavailable
   - Fix: Install coreutils package

3. **Profile Loading Failures**
   - Cause: Profile config files have syntax errors
   - Fix: Run `bash -n profiles/*/config.sh` to check syntax

4. **Security Test Failures**
   - Expected: Some security tests may fail if vulnerabilities still exist
   - Fix: Implement recommended security fixes from audit report

## Test Development Guide

### Adding New Tests

1. **Choose Test Category**
   - Unit: Testing single function
   - Integration: Testing workflow
   - Functional: Testing user feature
   - Security: Testing attack prevention

2. **Follow Naming Convention**
   ```bash
   test_[category]_[descriptive_name]() {
       log SECTION "Test Category: Description"
       setup_test_case "unique_id"

       # Your test code
       assert_equals "expected" "actual" "Test description"

       teardown_test_case
   }
   ```

3. **Use Assertion Functions**
   - `assert_equals expected actual "description"`
   - `assert_contains haystack needle "description"`
   - `assert_not_contains haystack needle "description"`
   - `assert_file_exists file "description"`
   - `assert_true condition "description"`
   - `assert_exit_code expected actual "description"`

4. **Isolate Test Environment**
   - Always use `setup_test_case` and `teardown_test_case`
   - Use `$TEST_HOME` instead of `$HOME`
   - Clean up created files in teardown

### Example Test Function

```bash
test_unit_example_feature() {
    log SECTION "Unit Test: Example Feature"

    setup_test_case "example"

    # Arrange
    echo "test_value" > "$HOME/.config/test_file"

    # Act
    source "$PROFILES_DIR/example_script.sh"
    local result=$(example_function)

    # Assert
    assert_equals "expected_result" "$result" "Example feature works"

    teardown_test_case
}
```

## Continuous Integration

### Pre-Commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run tests before commit
cd "$(git rev-parse --show-toplevel)/tests"
./profile_system_tests.sh --unit --security

if [[ $? -ne 0 ]]; then
    echo "❌ Tests failed - commit aborted"
    exit 1
fi
```

### CI Pipeline Integration

For GitHub Actions, GitLab CI, etc.:

```yaml
test:
  script:
    - cd tests
    - ./profile_system_tests.sh
  artifacts:
    when: always
    reports:
      junit: tests/test-results.xml
```

## Troubleshooting

### Test Hangs or Timeouts

- **Cause**: Infinite loop or blocking I/O
- **Fix**: Add timeout wrapper: `timeout 30s ./profile_system_tests.sh`

### Inconsistent Test Results

- **Cause**: Race conditions or shared state between tests
- **Fix**: Ensure proper cleanup in `teardown_test_case`

### False Positives in Security Tests

- **Expected**: Some attacks may succeed if system has vulnerabilities
- **Action**: Review security audit report and apply recommended fixes

### Permission Denied Errors

- **Cause**: Script not executable or restrictive umask
- **Fix**: `chmod +x profile_system_tests.sh` and check umask

## Test Maintenance

### When to Update Tests

1. **Adding new profiles**: Update unit tests for profile detection
2. **Adding new commands**: Update functional tests
3. **Security fixes**: Add regression test to prevent reintroduction
4. **API changes**: Update integration tests

### Test Coverage Goals

- Unit tests: >90% function coverage
- Integration: All user workflows
- Security: All attack vectors from audit
- Non-regression: All critical features

## Performance Benchmarking

The test suite includes performance regression tests:

- **Profile loading**: < 1000ms
- **Full test suite**: < 60s on standard hardware

Monitor these metrics to detect performance degradation.

## Test Reporting

### Generate Coverage Report

```bash
# Run with verbose output and save to log
./profile_system_tests.sh --verbose > test-results.log 2>&1

# Extract summary
grep -E "✅|❌|Test|Summary" test-results.log
```

### Parse Results Programmatically

```bash
# Get pass rate
pass_rate=$(grep "Passed:" test-results.log | grep -oP '\d+%')

# Check if all passed
if grep -q "ALL TESTS PASSED" test-results.log; then
    echo "Success"
else
    echo "Failures detected"
    exit 1
fi
```

## Best Practices

1. **Run tests frequently**: Before commits, after profile changes
2. **Isolate test environment**: Never test against production HOME
3. **Clean up thoroughly**: Prevent test pollution
4. **Document failures**: Add issues for persistent failures
5. **Update tests with code**: Keep tests synchronized with implementation

## Security Testing Notes

Security tests intentionally attempt attacks:
- Command injection attempts
- Path traversal attacks
- Symlink exploits
- Input validation bypass

**All security test failures indicate real vulnerabilities that must be fixed.**

## Support

For test issues:
1. Check this guide
2. Review claudedocs/security-audit-profile-system.md
3. Examine test output with --verbose flag
4. Consult README_PROFILS.md for profile system architecture
