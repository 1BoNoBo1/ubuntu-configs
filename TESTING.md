# Profile System Testing

## Quick Start

```bash
cd ~/ubuntu-configs/tests
./profile_system_tests.sh
```

## Test Categories

- **Unit Tests** (7): Individual function validation
- **Integration Tests** (4): Complete workflows
- **Functional Tests** (3): User-facing features
- **Security Tests** (6): Attack prevention
- **Non-Regression** (3): Ensure fixes don't break functionality

**Total**: 23 test functions, 45+ assertions

## Usage

```bash
# Run all tests
./tests/profile_system_tests.sh

# Run specific categories
./tests/profile_system_tests.sh --unit
./tests/profile_system_tests.sh --security
./tests/profile_system_tests.sh --integration

# Verbose output
./tests/profile_system_tests.sh --verbose

# Help
./tests/profile_system_tests.sh --help
```

## What's Tested

### Profile Detection (5-Level Priority)
1. Manual configuration file
2. Hostname detection
3. Hardware characteristics (battery, RAM)
4. Script presence detection
5. Default fallback

### Security
- Command injection prevention
- Path traversal protection
- Symlink attack mitigation
- File permission security (700/600)
- Race condition handling
- Input validation (null bytes, unicode, control chars)

### Profile Functionality
- TuF: Desktop with audio fixes (PERFORMANCE mode)
- PcDeV: Ultraportable battery optimization (MINIMAL mode)
- default: Universal configuration (STANDARD mode)

### Integration
- Bash and Zsh compatibility
- Profile switching
- Fallback mechanisms
- Adaptive system integration

## Expected Results

### Success
```
Total Tests:    45
Passed:         45 (100%)
Failed:         0
Skipped:        0

✅ ALL TESTS PASSED!
```

### Security Test Failures = Real Vulnerabilities
If security tests fail, it indicates actual vulnerabilities that must be fixed. See `claudedocs/security-audit-profile-system.md` for remediation guidance.

## Documentation

- **Quick Reference**: `tests/README.md`
- **Comprehensive Guide**: `claudedocs/testing-guide.md`
- **Implementation Summary**: `claudedocs/test-suite-summary.md`
- **Security Audit**: `claudedocs/security-audit-profile-system.md`

## Performance Targets

- Profile loading: < 1000ms
- Full test suite: < 60s

## CI/CD Integration

### Pre-Commit Hook

```bash
#!/bin/bash
cd tests && ./profile_system_tests.sh --unit --security
[[ $? -eq 0 ]] || { echo "Tests failed"; exit 1; }
```

### GitHub Actions

```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - run: cd tests && ./profile_system_tests.sh
```

## Maintenance

Update tests when:
- Adding new profiles
- Adding new commands
- Applying security fixes
- Modifying detection logic
- Changing module system

## Support

For issues, review:
1. This quick start
2. `tests/README.md` for command reference
3. `claudedocs/testing-guide.md` for detailed guide
4. Test output with `--verbose` flag
