# Git SH1 Modular System - Maintenance Guide

## Overview

This guide provides comprehensive information for maintaining and extending the git_sh1 modular system. The system consists of 18 modules across 7 directories with clear separation of concerns.

## System Architecture

### Core Components
- **Entry Points**: `git_sh1_modular.sh` (primary), `git_sh1_main.sh` (advanced)
- **Module Base**: `git_sh1_modules/` directory with hierarchical organization
- **Configuration**: Repository map in `core/config.sh`
- **Testing**: Built-in test framework with `test` command

## Regular Maintenance Tasks

### Daily Operations
```bash
# System health check
./git_sh1_modular.sh test

# Clear completion cache if needed
./git_sh1_modular.sh --clear-cache

# Check log files (auto-generated)
ls -la git_sh1_*.log
```

### Weekly Tasks
```bash
# Update repository configurations
vim git_sh1_modules/core/config.sh

# Test all major workflows
./git_sh1_modular.sh repos
./git_sh1_modular.sh verify all
./git_sh1_modular.sh feature list
./git_sh1_modular.sh profile list
```

### Monthly Tasks
```bash
# Performance baseline test
time ./git_sh1_modular.sh --help >/dev/null

# Completion system check
./install_completion.sh --test

# Module dependency audit
grep -r "load_module\|source" git_sh1_modules/
```

## Adding New Repositories

### Update Configuration
Edit `git_sh1_modules/core/config.sh`:
```bash
# Add to repo_map array
declare -A repo_map=(
    # ... existing entries ...
    ["new_repo"]="path/to/new_repo"
)
```

### Test New Repository
```bash
# Verify repository is recognized
./git_sh1_modular.sh repos | grep new_repo

# Test operations
./git_sh1_modular.sh verify new_repo
```

### Update Completion
```bash
# Clear cache to pick up new repository
./git_sh1_modular.sh --clear-cache

# Test completion
./git_sh1_modular.sh verify [TAB]  # Should include new_repo
```

## Module Development

### Creating New Modules

1. **Choose Directory**: Place in appropriate functional directory
2. **Add Dependencies**: Document at file header
3. **Implement Interface**: Follow existing patterns
4. **Add Loading**: Update `lib/module_loader.sh`
5. **Create Tests**: Add test cases
6. **Update Documentation**: Document public interface

### Module Template
```bash
#!/bin/bash

# path/new_module.sh - Brief description
# Depends on: core/config.sh, other/dependencies.sh

# Public function with consistent naming
cmd_new_function() {
    local param1="$1"
    local param2="$2"
    
    # Validate inputs
    if [[ -z "$param1" ]]; then
        log "ERROR" "Parameter 1 is required"
        return 1
    fi
    
    # Implementation here
    log "INFO" "Executing new function with $param1"
    
    return 0
}

# Private helper function
_private_helper() {
    # Internal implementation
    return 0
}
```

### Module Standards
- **Size Limit**: Maximum 200 lines per module
- **Error Handling**: Use `log()` function, return proper codes
- **Input Validation**: Validate all user inputs with `core/validation.sh`
- **Performance**: Cache expensive operations when appropriate
- **Testing**: Include test cases for all public functions

## Troubleshooting Common Issues

### Module Loading Errors

**Symptom**: "command not found" errors
**Cause**: Module not loaded before function call
**Solution**: 
```bash
# In CLI dispatcher, load required modules first
load_module "path/to/required_module.sh" || return 1
```

### Performance Degradation

**Symptom**: Slow startup times (>100ms)
**Diagnosis**:
```bash
# Time individual components
time ./git_sh1_modular.sh --version
VERBOSE=true ./git_sh1_modular.sh test

# Check module loading order
grep -n "load_module" git_sh1_modules/lib/module_loader.sh
```

**Solutions**:
- Optimize module loading order
- Implement lazy loading for heavy modules
- Cache expensive operations

### Completion System Issues

**Symptom**: Tab completion not working
**Diagnosis**:
```bash
# Test completion loading
source git_sh1_completion.bash

# Check function registration
complete -p | grep git_sh1

# Verify cache
ls -la ~/.cache/git_sh1_modular/
```

**Solutions**:
```bash
# Reinstall completion
./install_completion.sh --force

# Clear cache
./git_sh1_modular.sh --clear-cache

# Debug completion
GIT_SH1_DEBUG=1 ./git_sh1_modular.sh [TAB]
```

### Repository Discovery Problems

**Symptom**: Cannot find repositories or git-depot
**Diagnosis**:
```bash
# Check discovery system
VERBOSE=true ./git_sh1_modular.sh repos

# Verify paths
./git_sh1_modular.sh test | grep -A 10 "Repository system"
```

**Solutions**:
- Verify working directory is correct
- Check repository map configuration
- Update path discovery logic if needed

## Performance Monitoring

### Baseline Metrics
- **Startup Time**: ~0.041 seconds (target: <0.050s)
- **Memory Usage**: ~8MB full load (target: <10MB)  
- **Module Loading**: ~41ms total (target: <50ms)

### Monitoring Commands
```bash
# Startup performance
time ./git_sh1_modular.sh --version

# Memory usage (if available)
/usr/bin/time -l ./git_sh1_modular.sh --help >/dev/null

# Module loading details
VERBOSE=true ./git_sh1_modular.sh test 2>&1 | grep "Loaded module"
```

### Performance Optimization
- Keep modules under 200 lines
- Use on-demand loading where possible
- Cache expensive operations (repository discovery, etc.)
- Minimize external command calls in hot paths

## Security Considerations

### Input Validation
All user inputs must be validated:
```bash
# Use validation functions
validate_repo_name "$repo_name"
validate_path "$file_path"
sanitize_input "$user_input"
```

### Path Sanitization
Prevent directory traversal:
```bash
# Always validate paths
if ! validate_path "$user_path"; then
    log "ERROR" "Invalid path: $user_path"
    return 1
fi
```

### Command Injection Prevention
```bash
# Use proper quoting
execute_command "git status" "Checking repository status"

# Avoid eval and unsafe expansions
# NEVER: eval "$user_command"
# GOOD: "$validated_command" "$sanitized_args"
```

## Backup and Recovery

### System Backup
```bash
# Backup entire modular system
tar -czf git_sh1_modular_backup_$(date +%Y%m%d).tar.gz \
    git_sh1_modular.sh git_sh1_main.sh git_sh1_modules/ \
    git_sh1_completion.bash install_completion.sh \
    MIGRATION_GUIDE.md MODULE_DOCUMENTATION.md
```

### Rollback Procedure
```bash
# If original script was preserved
mv git_sh1.sh git_sh1_modular.sh  # Backup modular
mv git_sh1_original.sh git_sh1.sh  # Restore original

# Remove completion
./install_completion.sh --uninstall

# Clean up modular files
rm -rf git_sh1_modules/ ~/.cache/git_sh1_modular/
```

### Recovery Testing
```bash
# Test basic functionality after changes
./git_sh1_modular.sh test
./git_sh1_modular.sh repos
./git_sh1_modular.sh --help
```

## Version Control

### Branching Strategy
- **master**: Stable, production-ready code
- **development**: Integration branch for new features
- **feature/***: Individual feature development
- **hotfix/***: Critical bug fixes

### Release Process
1. **Testing**: Full regression test suite
2. **Documentation**: Update guides and documentation
3. **Performance**: Verify performance benchmarks
4. **Compatibility**: Test backward compatibility
5. **Deployment**: Create versioned release

### Change Management
```bash
# Before major changes
git branch backup-$(date +%Y%m%d)
git checkout -b feature/new-functionality

# After testing
git checkout master
git merge --no-ff feature/new-functionality
git tag v2.x.x
```

## Monitoring and Logging

### Log Management
```bash
# Log files auto-generated with timestamps
# Location: git_sh1_YYYYMMDD_HHMMSS.log

# Clean old logs (older than 30 days)
find . -name "git_sh1_*.log" -mtime +30 -delete

# Monitor log growth
du -sh git_sh1_*.log
```

### Error Monitoring
```bash
# Check for errors in logs
grep -i error git_sh1_*.log

# Monitor system health
./git_sh1_modular.sh test 2>&1 | tee health_check.log
```

## Contact and Support

### Internal Documentation
- `MODULE_DOCUMENTATION.md`: Technical module details
- `MIGRATION_GUIDE.md`: User migration information
- Inline code comments: Function-level documentation

### Development Environment
- **Bash Version**: 4.0+ recommended
- **Dependencies**: Standard Unix tools (grep, sed, awk, find)
- **Optional**: xmllint for manifest parsing

### Testing Environment
```bash
# Set up test environment
mkdir -p test_area
cd test_area
ln -s ../git_sh1_modular.sh ./
./git_sh1_modular.sh test
```

This maintenance guide ensures the long-term health and sustainability of the git_sh1 modular system.