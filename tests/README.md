# Profile System Tests - Quick Reference

## Run Tests

```bash
# All tests
./profile_system_tests.sh

# Specific categories
./profile_system_tests.sh --unit
./profile_system_tests.sh --integration
./profile_system_tests.sh --functional
./profile_system_tests.sh --security

# Verbose output
./profile_system_tests.sh --verbose
```

## Test Coverage

| Category | Tests | Coverage |
|----------|-------|----------|
| **Unit** | 7 | Profile detection (5 methods), validation, whitelist |
| **Integration** | 4 | Full workflows, shell compatibility, fallbacks |
| **Functional** | 3 | Commands, adaptive modes, module loading |
| **Security** | 6 | Injection, traversal, symlinks, permissions, race conditions |
| **Non-Regression** | 3 | Legitimate profiles, commands, performance |
| **Total** | 23 | Comprehensive system validation |

## Key Security Tests

✅ **Command Injection**: Blocks $(), backticks, semicolons
✅ **Path Traversal**: Prevents ../ and absolute paths
✅ **Symlink Attacks**: Detects escapes via realpath
✅ **File Permissions**: Enforces 700/600 on configs
✅ **Input Validation**: Handles null bytes, unicode, control chars
✅ **Race Conditions**: Atomic writes with proper umask

## Test Results

- ✅ Green = Pass
- ❌ Red = Fail (needs investigation)
- ⏭️ Yellow = Skip (missing deps)
- ⚠️ Warning = Non-critical

## Expected Failures

If security tests fail, it indicates **real vulnerabilities** that must be fixed. See `claudedocs/security-audit-profile-system.md` for remediation guidance.

## Performance Targets

- Profile loading: < 1000ms
- Full test suite: < 60s

## Documentation

Full testing guide: `claudedocs/testing-guide.md`
