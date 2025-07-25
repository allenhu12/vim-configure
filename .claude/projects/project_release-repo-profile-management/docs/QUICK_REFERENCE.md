# git_sh1.sh Quick Reference Guide

## Command Syntax

```bash
./utility/git_sh1.sh [GLOBAL_OPTIONS] COMMAND [COMMAND_OPTIONS] [ARGUMENTS]
```

## Global Options

| Option | Description |
|--------|-------------|
| `--verbose` | Enable verbose output |
| `--dry-run` | Show what would be done without executing |
| `--help` | Show help information |

## Environment Variables

| Variable | Values | Description |
|----------|--------|-------------|
| `VERBOSE` | `true/false` | Enable verbose logging |
| `DRY_RUN` | `true/false` | Enable dry-run mode |
| `GIT_SH1_LOG_LEVEL` | `DEBUG/INFO/WARN/ERROR` | Set logging level |

## Profile Management

### Create Profile
```bash
./utility/git_sh1.sh profile create {release}/{config} --manifest /path/to/manifest.xml
```

### List Profiles
```bash
./utility/git_sh1.sh profile list
```

### Show Profile Details
```bash
./utility/git_sh1.sh profile show {release}/{config}
```

## Repository Operations

### Check Repository Status
```bash
./utility/git_sh1.sh repo-check [all|repo_name] [--profile profile_name]
```

### List Available Repositories
```bash
./utility/git_sh1.sh show-repos
```

### Fetch Updates
```bash
./utility/git_sh1.sh fetch [all|repo_name] [--profile profile_name]
```

## Worktree Management

### Create Worktree
```bash
# With profile (recommended)
./utility/git_sh1.sh worktree add --profile {release}/{config} -repo {all|repo_name} -lb {local_branch} [-rb {remote_branch}]

# Without profile (legacy)
./utility/git_sh1.sh worktree add -repo {all|repo_name} -lb {local_branch} [-rb {remote_branch}]
```

### Update Worktree
```bash
./utility/git_sh1.sh worktree pull-rebase [--profile profile_name] -repo {all|repo_name} -lb {local_branch}
```

## Feature Branch Management

### Create Feature Branches
```bash
./utility/git_sh1.sh feature create {feature_name} {base_branch} {all|repo1,repo2,...}
```

### Check Feature Status
```bash
./utility/git_sh1.sh feature status {feature_name}
```

### Sync Feature Branches
```bash
./utility/git_sh1.sh feature sync {feature_name}
```

### Clean Up Feature Branches
```bash
./utility/git_sh1.sh feature cleanup {feature_name}
```

## Common Command Patterns

### Daily Development Setup
```bash
# Create profile and development environment
./utility/git_sh1.sh profile create unleashed_200.19/openwrt_common --manifest /path/to/manifest.xml
./utility/git_sh1.sh fetch all --profile unleashed_200.19/openwrt_common
./utility/git_sh1.sh worktree add --profile unleashed_200.19/openwrt_common -repo all -lb dev_$(date +%Y%m%d)
```

### Feature Development
```bash
# Create feature across multiple repositories
./utility/git_sh1.sh feature create new_feature origin/main controller,ap_scg_common
./utility/git_sh1.sh worktree add --profile profile_name -repo controller,ap_scg_common -lb feature_new_feature
```

### Release Preparation
```bash
# Set up release testing environment
./utility/git_sh1.sh profile create release_200.19/rc --manifest /path/to/rc_manifest.xml
./utility/git_sh1.sh worktree add --profile release_200.19/rc -repo all -lb release_test
```

### Hotfix Workflow
```bash
# Emergency hotfix setup
./utility/git_sh1.sh feature create hotfix_001 origin/release/stable controller,security_module
./utility/git_sh1.sh worktree add --profile hotfix_profile -repo controller,security_module -lb emergency_hotfix_001
```

## Parameter Reference

### Repository Targeting

| Value | Description |
|-------|-------------|
| `all` | Target all repositories in current configuration |
| `repo_name` | Target specific repository |
| `repo1,repo2,repo3` | Target multiple specific repositories |

### Branch Naming

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-lb` | Local branch name | `-lb feature_authentication` |
| `-rb` | Remote branch to track | `-rb origin/release/unleashed_200.19.7.11` |

### Profile Naming Convention

```
{release}/{configuration_type}
├── unleashed_200.19/openwrt_common
├── unleashed_200.19/buildroot_common
├── unleashed_200.19/security_hotfix
└── unleashed_200.20/openwrt_common
```

## File Locations

### Script Location
```
git-depot/utility/git_sh1.sh
```

### Profile Storage
```
git-depot/.git_sh1_profiles/{release}/{config}/
├── manifest.xml      # Source manifest file
├── repo_map.txt      # Generated repository mappings
└── metadata.json     # Profile metadata
```

### Worktree Locations
```
git-depot/{branch_name}/{repository_folder}/
```

### Log Files
```
git-depot/.git_sh1_logs/
```

## Troubleshooting Quick Commands

### Check Environment
```bash
# Verify script setup
ls -la utility/git_sh1.sh
chmod +x utility/git_sh1.sh

# Check current status
./utility/git_sh1.sh repo-check all

# List profiles
./utility/git_sh1.sh profile list
```

### Debug Mode
```bash
# Enable verbose output
VERBOSE=true ./utility/git_sh1.sh command arguments

# Dry run mode
DRY_RUN=true ./utility/git_sh1.sh command arguments
```

### Common Fixes
```bash
# Fix path validation issues (if using old script version)
grep -n "validate_worktree_path" utility/git_sh1.sh

# Clean up worktrees
git worktree prune

# Reset permissions
chmod -R 755 .git_sh1_profiles/
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Command line argument error |
| `3` | File or directory not found |
| `4` | Permission denied |
| `5` | Git operation failed |

## Best Practices

### ✅ Recommended
- Always use profiles for new projects
- Use descriptive branch names with dates: `feature_auth_20240101`
- Verify repository status before major operations
- Enable verbose mode for troubleshooting
- Use dry-run mode for complex operations

### ❌ Avoid
- Generic branch names: `test`, `branch1`
- Running commands without verifying profiles exist
- Creating worktrees in existing directories
- Ignoring error messages and warnings

## Emergency Commands

### Complete Reset
```bash
# WARNING: Removes all worktrees and profiles
git worktree prune
rm -rf .git_sh1_profiles/
rm -rf .git_sh1_logs/
```

### Backup Profiles
```bash
tar -czf profiles_backup_$(date +%Y%m%d).tar.gz .git_sh1_profiles/
```

### Repository Health Check
```bash
./utility/git_sh1.sh repo-check all --verbose 2>&1 | tee health_check.log
```

---

For detailed information, see the complete manual: `SCRIPT_MANUAL.md`  
For step-by-step workflows, see: `WORKFLOW_GUIDE.md`  
For troubleshooting, see: `TROUBLESHOOTING_GUIDE.md`