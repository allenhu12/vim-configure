# git_sh1.sh Comprehensive Manual

## Table of Contents

1. [Overview](#overview)
2. [Installation & Setup](#installation--setup)
3. [Core Concepts](#core-concepts)
4. [Quick Reference](#quick-reference)
5. [Profile Management](#profile-management)
6. [Repository Operations](#repository-operations)
7. [Worktree Management](#worktree-management)
8. [Feature Branch Management](#feature-branch-management)
9. [Command Reference](#command-reference)
10. [Configuration Options](#configuration-options)
11. [Workflows](#workflows)
12. [Troubleshooting](#troubleshooting)
13. [Best Practices](#best-practices)
14. [Advanced Usage](#advanced-usage)

---

## Overview

The `git_sh1.sh` script is a comprehensive Git repository management tool designed for multi-repository development workflows. It provides profile-based configuration management, automated worktree operations, and feature branch management across multiple repositories.

### Key Features

- **Profile-Based Configuration**: Manage different repository sets using XML manifest files
- **Progress Tracking**: Visual progress indicators `[1/15] (6%)` for all batch operations
- **Worktree Management**: Create and manage Git worktrees across multiple repositories with intelligent ordering
- **Feature Branch Operations**: Coordinate feature development across repository boundaries
- **Repository Synchronization**: Fetch, pull, and rebase operations across repository sets
- **Automated Upstream Detection**: Intelligent branch detection from manifest files
- **Tab Completion**: Fish-shell-like intelligent tab completion for all commands
- **Enhanced Output**: Clear spacing and progress feedback for better user experience
- **Backward Compatibility**: Works with existing hardcoded repository configurations

### Latest Improvements (2025)

✅ **Fixed Directory Hierarchy Issues**: Resolved worktree creation conflicts  
✅ **Added Progress Indicators**: All batch operations show `[X/N] (%)` progress  
✅ **Enhanced Output Formatting**: Clear spacing between operations  
✅ **Improved Error Handling**: Better error messages with suggested solutions  
✅ **Smart Repository Ordering**: Processes repositories in correct dependency order  
✅ **Tab Completion System**: Intelligent autocompletion for all commands and parameters  

---

## Installation & Setup

### Prerequisites

- Git (version 2.5 or higher)
- Bash shell (version 4.0 or higher)
- xmllint (for XML manifest parsing)
- Standard Unix utilities (sed, grep, awk)

### Directory Structure

The script expects the following directory structure:

```
git-depot/
├── repo_base/
│   ├── controller/
│   ├── opensource/
│   ├── rks_ap/
│   └── ...
├── utility/
│   ├── git_sh1.sh
│   ├── git_sh1_completion.bash
│   └── install_completion.sh
└── .git_sh1_profiles/
    └── {release}/
        └── {config_type}/
            ├── manifest.xml
            ├── repo_map.txt
            └── repo_map_upstream.txt
```

### Initial Setup

1. **Place the script in the utility directory**:
   ```bash
   chmod +x utility/git_sh1.sh
   ```

2. **Install tab completion (optional but recommended)**:
   ```bash
   ./utility/install_completion.sh
   # or
   ./utility/git_sh1.sh --install-completion
   ```

3. **Run from any directory within the git-depot structure**

---

## Core Concepts

### Profiles

Profiles define repository sets and configurations for specific releases or build types. Each profile contains:

- **manifest.xml**: Source of truth defining repositories and their configurations
- **repo_map.txt**: Generated mapping of repository names to local directories (sorted by depth)
- **repo_map_upstream.txt**: Generated mapping of repositories to their upstream branches
- **metadata.json**: Profile metadata and configuration details

### Repository Base (`repo_base`)

The base directory where individual repositories are located. Automatically detected from the git-depot structure.

### Worktree Base (`worktree_base_path`)

The base directory for worktree creations, typically the git-depot root directory.

### Repository Processing Order

The script processes repositories in **shallowest-to-deepest** order to prevent directory conflicts:
1. Root level: `opensource`, `dl`, `rksiot` (depth 0)
2. Level 1: `rks_ap` (depth 1)  
3. Level 2: `rks_ap/controller`, `rks_ap/ap_scg_common` (depth 2)
4. Level 3: `rks_ap/controller/common`, `rks_ap/controller/rcli` (depth 3)
5. And so on...

---

## Quick Reference

### Command Syntax

```bash
./utility/git_sh1.sh [GLOBAL_OPTIONS] COMMAND [COMMAND_OPTIONS] [ARGUMENTS]
```

### Global Options

| Option | Description |
|--------|-------------|
| `--verbose` | Enable verbose output |
| `--dry-run` | Show what would be done without executing |
| `--help` | Show help information |
| `--install-completion` | Install tab completion |
| `--clear-cache` | Clear completion cache |

### Environment Variables

| Variable | Values | Description |
|----------|--------|-------------|
| `VERBOSE` | `true/false` | Enable verbose logging |
| `DRY_RUN` | `true/false` | Enable dry-run mode |
| `GIT_SH1_LOG_LEVEL` | `DEBUG/INFO/WARN/ERROR` | Set logging level |

---

## Profile Management

### Creating Profiles

Create profiles from XML manifest files:

```bash
./git_sh1.sh profile create {release}/{config_type}
```

**Prerequisites**: The manifest.xml file must be manually placed in the profile directory first.

**Example Workflow**:
```bash
# Step 1: Create profile directory and copy manifest
mkdir -p .git_sh1_profiles/unleashed_200.19/openwrt_common
cp /path/to/manifest.xml .git_sh1_profiles/unleashed_200.19/openwrt_common/

# Step 2: Generate profile from manifest
./git_sh1.sh profile create unleashed_200.19/openwrt_common
```

**Output**:
```
Profile 'unleashed_200.19/openwrt_common' created successfully
Generated repo_map with 15 repositories
Generated upstream mappings for 45 repositories
Profile directory: /path/to/.git_sh1_profiles/unleashed_200.19/openwrt_common
Repository count: 15
```

### Listing Profiles

View all available profiles:

```bash
./git_sh1.sh profile list
```

**Example Output**:
```
Available profiles:
Release: unleashed_200.19
  - openwrt_common (15 repositories)
  - buildroot_common (12 repositories)
  - r370_controller (8 repositories)

Release: unleashed_200.20
  - openwrt_common (16 repositories)
```

### Viewing Profile Details

Display profile information and repository mappings:

```bash
./git_sh1.sh profile show {release}/{config_type}
```

**Example**:
```bash
./git_sh1.sh profile show unleashed_200.19/openwrt_common
```

**Example Output**:
```
Profile: unleashed_200.19/openwrt_common
Created: 2025-07-22 14:25:33
Repositories: 15

Repository Mappings:
  ap_scg_common -> rks_ap/ap_scg_common
  ap_scg_rcli -> rks_ap/controller/rcli
  controller -> rks_ap/controller
  rks_ap -> rks_ap
  ...

Upstream Mappings:
  ap_scg_common: release/unleashed_200.19.7.11
  controller: release/unleashed_200.19.7.11_r370_t
  rks_ap: release/unleashed_200.19.7.11
  ...
```

---

## Repository Operations

### Repository Verification

Check the status of repositories:

```bash
./git_sh1.sh verify [all|repo_name] [--profile profile_name]
```

**Examples**:
```bash
./git_sh1.sh verify all
./git_sh1.sh verify controller
./git_sh1.sh verify all --profile unleashed_200.19/openwrt_common
```

### Repository Listing

Show all available repositories:

```bash
./git_sh1.sh show_repos
```

**Example Output**:
```
Available repositories:
ap_scg_common
ap_scg_rcli
controller
dl
opensource
rks_ap
...
```

### Fetching Updates

Fetch updates from remote repositories with progress tracking:

```bash
./git_sh1.sh fetch [all|repo_name] [--profile profile_name]
```

**Examples**:
```bash
# Fetch all repositories using default configuration
./git_sh1.sh fetch all

# Fetch all repositories using a specific profile (with progress indicators)
./git_sh1.sh fetch all --profile unleashed_200.19/openwrt_common

# Fetch specific repository
./git_sh1.sh fetch controller --profile unleashed_200.19/openwrt_common
```

**Example Output with Progress**:
```
Using profile: unleashed_200.19/openwrt_common
Fetching all repositories...
[1/15] (6%) Fetching dl...
Processing repository: dl
Successfully fetched updates for: dl
Completed processing repository: dl

[2/15] (13%) Fetching opensource...
Processing repository: opensource
Successfully fetched updates for: opensource
Completed processing repository: opensource
...
```

---

## Worktree Management

### Creating Worktrees

Create Git worktrees for development branches with enhanced progress tracking:

```bash
./git_sh1.sh worktree add [options] -repo {all|repo_name} -lb {local_branch} [-rb {remote_branch}]
```

#### Options:
- `--profile {profile_name}`: Use specific profile for repository set (enables auto-upstream detection)
- `-repo {all|repo_name}`: Target repositories (all or specific)
- `-lb {local_branch}`: Local branch name for worktree
- `-rb {remote_branch}`: Remote branch to track (optional if using --profile)

#### Examples:

**Create worktrees for all repositories with profile** (recommended):
```bash
./git_sh1.sh worktree add --profile unleashed_200.19/openwrt_common -repo all -lb my_feature_branch
```

**Example Output with Progress**:
```
Using profile: unleashed_200.19/openwrt_common
Creating worktrees for all repositories...
[1/15] (6%) Creating worktree for dl...
Auto-detected upstream for dl: origin/release/unleashed_200.19.7.11
Processing repository: dl
Successfully added worktree for dl at /path/to/worktree/my_feature_branch/dl
Completed processing repository: dl

[2/15] (13%) Creating worktree for opensource...
Auto-detected upstream for opensource: origin/release/unleashed_200.19.7.11
Processing repository: opensource
Successfully added worktree for opensource at /path/to/worktree/my_feature_branch/opensource
Completed processing repository: opensource
...
```

**Create worktree for specific repository**:
```bash
./git_sh1.sh worktree add -repo controller -lb my_feature_branch -rb origin/release/unleashed_200.19.7.11
```

**Auto-detect upstream from profile**:
```bash
./git_sh1.sh worktree add --profile unleashed_200.19/openwrt_common -repo controller -lb feature_xyz
```

### Worktree Pull-Rebase

Update worktrees with latest changes:

```bash
./git_sh1.sh worktree pull-rebase [options] -repo {all|repo_name} -lb {local_branch}
```

#### Options:
- `--profile {profile_name}`: Use specific profile for repository set
- `-repo {all|repo_name}`: Target repositories (all or specific)
- `-lb {local_branch}`: Local branch name for worktree

#### Examples:

**Pull-rebase all repositories in a worktree with profile**:
```bash
./git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common -repo all -lb my_feature_branch
```

**Example Output with Progress**:
```
Pull-rebasing all repositories...
[1/15] (6%) Pull-rebasing dl...
Pulling and rebasing dl in my_feature_branch (current branch: my_feature_branch)
Successfully updated and rebased dl
Completed processing repository: dl

[2/15] (13%) Pull-rebasing opensource...
Pulling and rebasing opensource in my_feature_branch (current branch: my_feature_branch)
Successfully updated and rebased opensource
Completed processing repository: opensource
...
```

**Pull-rebase specific repository**:
```bash
./git_sh1.sh worktree pull-rebase -repo controller -lb my_feature_branch
```

**Legacy syntax (backward compatibility)**:
```bash
./git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common all my_feature_branch
./git_sh1.sh worktree pull-rebase controller my_feature_branch
```

---

## Feature Branch Management

### Creating Feature Branches

Create coordinated feature branches across repositories:

```bash
./git_sh1.sh feature create [-w <worktree>] [--force] <feature_name> <repo1> [repo2] ...
```

**Options**:
- `-w <worktree>`: Specify which worktree to create the feature in
- `--force`: Overwrite existing feature

**Example**:
```bash
./git_sh1.sh feature create -w local5 new_auth_system controller ap_scg_common rks_ap
```

### Listing Features

List all available features:

```bash
./git_sh1.sh feature list
```

### Feature Details

Show detailed information about a feature:

```bash
./git_sh1.sh feature show [-w <worktree>] <feature_name>
```

**Example**:
```bash
./git_sh1.sh feature show new_auth_system
```

### Adding Repository to Feature

Add a repository to an existing feature:

```bash
./git_sh1.sh feature add [-w <worktree>] <feature_name> <repo_name>
```

### Feature Comments

Add comments to a feature:

```bash
./git_sh1.sh feature comment <feature_name> <comment_text>
```

### Feature Switching

Switch to a feature branch across repositories:

```bash
./git_sh1.sh feature switch [-w <worktree>] <feature_name>
```

### Feature Switchback

Switch back from a feature to the original branch:

```bash
./git_sh1.sh feature switchback <feature_name>
```

### Feature Pick (Cherry-pick)

Cherry-pick feature changes to a target branch:

```bash
./git_sh1.sh feature pick [-w <worktree>] [--dry-run] <feature_name> <target_branch>
```

**Options**:
- `-w <worktree>`: Override worktree for the operation
- `--dry-run`: Show what would be done without executing

---

## Command Reference

### Complete Command List

| Command | Subcommand | Description | Example |
|---------|------------|-------------|---------|
| `verify` | - | Check repository status | `./git_sh1.sh verify all` |
| `fetch` | - | Fetch repository updates | `./git_sh1.sh fetch all --profile profile` |
| `show_repos` | - | List all repositories | `./git_sh1.sh show_repos` |
| **Profile Commands** | | | |
| `profile` | `create` | Create new profile from manifest | `./git_sh1.sh profile create release/config` |
| `profile` | `list` | List all available profiles | `./git_sh1.sh profile list` |
| `profile` | `show` | Show profile details | `./git_sh1.sh profile show release/config` |
| **Worktree Commands** | | | |
| `worktree` | `add` | Create new worktree | `./git_sh1.sh worktree add --profile profile -repo all -lb branch` |
| `worktree` | `pull-rebase` | Update worktree | `./git_sh1.sh worktree pull-rebase -repo all -lb branch` |
| **Feature Commands** | | | |
| `feature` | `create` | Create feature branches | `./git_sh1.sh feature create name repo1 repo2` |
| `feature` | `list` | List all features | `./git_sh1.sh feature list` |
| `feature` | `show` | Show feature details | `./git_sh1.sh feature show name` |
| `feature` | `add` | Add repository to feature | `./git_sh1.sh feature add name repo` |
| `feature` | `comment` | Add comment to feature | `./git_sh1.sh feature comment name "text"` |
| `feature` | `switch` | Switch to feature branch | `./git_sh1.sh feature switch name` |
| `feature` | `switchback` | Switch back from feature | `./git_sh1.sh feature switchback name` |
| `feature` | `pick` | Cherry-pick feature to branch | `./git_sh1.sh feature pick name target_branch` |

### Parameter Reference

#### Repository Targeting

| Value | Description |
|-------|-------------|
| `all` | Target all repositories in current configuration |
| `repo_name` | Target specific repository |
| `repo1,repo2,repo3` | Target multiple specific repositories (feature commands) |

#### Branch Naming

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-lb` | Local branch name | `-lb feature_authentication` |
| `-rb` | Remote branch to track | `-rb origin/release/unleashed_200.19.7.11` |

#### Profile Naming Convention

```
{release}/{configuration_type}
├── unleashed_200.19/openwrt_common
├── unleashed_200.19/buildroot_common
├── unleashed_200.19/security_hotfix
└── unleashed_200.20/openwrt_common
```

---

## Configuration Options

### Environment Variables

- `VERBOSE`: Enable verbose logging (true/false)
- `DRY_RUN`: Enable dry-run mode (true/false)
- `GIT_SH1_LOG_LEVEL`: Set logging level (DEBUG, INFO, WARN, ERROR)

### Script Variables

The script automatically detects the following paths:
- `git_depot_dir`: Root git-depot directory
- `repo_base`: Repository base directory (auto-detected)
- `worktree_base_path`: Worktree base directory
- `profiles_dir`: Profile storage directory (`.git_sh1_profiles/`)

### File Locations

#### Script Location
```
git-depot/utility/git_sh1.sh
```

#### Profile Storage
```
git-depot/.git_sh1_profiles/{release}/{config}/
├── manifest.xml          # Source manifest file
├── repo_map.txt          # Generated repository mappings (sorted by depth)
├── repo_map_upstream.txt # Generated upstream branch mappings
└── metadata.json         # Profile metadata
```

#### Worktree Locations
```
git-depot/{branch_name}/{repository_folder}/
```

#### Completion Cache
```
~/.cache/git_sh1/
├── repositories.cache
├── features.cache
├── worktrees.cache
└── branches.cache
```

---

## Workflows

### Workflow 1: Daily Development Setup

```bash
#!/bin/bash
# Daily development setup script

PROFILE="unleashed_200.19/openwrt_common"
BRANCH="daily_dev_$(date +%Y%m%d)"

echo "Setting up daily development environment..."

# Fetch latest updates with progress tracking
./utility/git_sh1.sh fetch all --profile "$PROFILE"

# Create fresh worktrees with progress indicators
./utility/git_sh1.sh worktree add \
  --profile "$PROFILE" \
  -repo all \
  -lb "$BRANCH"

echo "Development environment ready in branch: $BRANCH"
```

### Workflow 2: Feature Development Across Multiple Repositories

```bash
#!/bin/bash
# Multi-repository feature development

FEATURE_NAME="user_management_v2"
AFFECTED_REPOS="controller,ap_scg_common,rks_ap"
PROFILE="unleashed_200.19/openwrt_common"

echo "Starting feature development: $FEATURE_NAME"

# Create feature branches
./utility/git_sh1.sh feature create "$FEATURE_NAME" "$AFFECTED_REPOS"

# Create development worktrees with progress tracking
./utility/git_sh1.sh worktree add \
  --profile "$PROFILE" \
  -repo "$AFFECTED_REPOS" \
  -lb "feature_${FEATURE_NAME}"

echo "Feature development environment ready!"
```

### Workflow 3: Release Preparation with Progress Tracking

```bash
#!/bin/bash
# Release preparation workflow

RELEASE_PROFILE="unleashed_200.19/release_candidate"
TEST_BRANCH="release_validation_$(date +%Y%m%d_%H%M)"

echo "Creating release validation environment..."

# Verify profile exists
if ! ./utility/git_sh1.sh profile show "$RELEASE_PROFILE" > /dev/null 2>&1; then
  echo "ERROR: Profile $RELEASE_PROFILE not found"
  exit 1
fi

# Create test worktrees with progress indicators
./utility/git_sh1.sh worktree add \
  --profile "$RELEASE_PROFILE" \
  -repo all \
  -lb "$TEST_BRANCH"

# Verify all repositories are ready
./utility/git_sh1.sh verify all --profile "$RELEASE_PROFILE"

echo "Release validation environment ready: $TEST_BRANCH"
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Invalid worktree path" Error

**Problem**: Getting path validation errors during worktree creation.

**Symptoms**:
```
Auto-detected upstream for controller: origin/release/unleashed_200.19.7.11
Invalid worktree path for: controller
```

**Solution**: This was fixed in the latest version. The script now uses `validate_worktree_path()` instead of `validate_path()` for worktree operations.

#### Issue 2: Directory Hierarchy Conflicts

**Problem**: Child repositories (like `controller`) being overwritten by parent repositories (like `rks_ap`).

**Symptoms**:
```
Successfully added worktree for controller at /path/controller
...
Processing repository: rks_ap
Successfully added worktree for rks_ap at /path/rks_ap
# But /path/rks_ap/controller no longer exists
```

**Solution**: Fixed in latest version with depth-based repository sorting. Parent repositories are now processed before children.

#### Issue 3: Duplicate Branch Names in Output

**Problem**: Branch names appearing duplicated in auto-detection.

**Symptoms**:
```
Auto-detected upstream for dl: origin/release/unleashed_200.19.7.11
release/unleashed_200.19.7.11
release/unleashed_200.19.7.11
```

**Solution**: Fixed by clearing the upstream file before regeneration and using `head -1` to handle duplicates.

#### Issue 4: Tab Completion Not Working

**Problem**: Tab completion not functioning.

**Solutions**:
```bash
# Install completion
./utility/git_sh1.sh --install-completion

# Or manually
./utility/install_completion.sh

# Test completion
./utility/git_sh1.sh [TAB]
```

#### Issue 5: Profile Not Found

**Problem**: Profile doesn't exist or can't be located.

**Diagnosis**:
```bash
# List available profiles
./utility/git_sh1.sh profile list

# Check profile directory
ls -la .git_sh1_profiles/

# Create missing profile
./utility/git_sh1.sh profile create release/config
```

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
# Enable verbose mode
VERBOSE=true ./utility/git_sh1.sh command arguments

# Enable debug logging with completion
export GIT_SH1_DEBUG=1
./utility/git_sh1.sh [TAB]  # Shows completion debug info

# Dry run mode
DRY_RUN=true ./utility/git_sh1.sh command arguments
```

### Recovery Procedures

#### Complete Environment Reset

```bash
#!/bin/bash
echo "WARNING: This will reset all profiles and worktrees!"
read -p "Continue? (y/N): " confirm

if [[ "$confirm" == "y" ]]; then
    # Remove all worktrees
    git worktree prune
    
    # Clean up directories
    rm -rf .git_sh1_profiles/
    rm -rf ~/.cache/git_sh1/
    
    echo "Environment reset complete"
fi
```

#### Profile Backup and Restore

```bash
# Backup profiles
tar -czf profiles_backup_$(date +%Y%m%d).tar.gz .git_sh1_profiles/

# Restore profiles
tar -xzf profiles_backup_20250101.tar.gz

# Verify restored profiles
./utility/git_sh1.sh profile list
```

---

## Best Practices

### Repository Management

1. **Always use profiles for new projects**:
   ```bash
   # Recommended: Profile-based approach
   ./git_sh1.sh worktree add --profile release/config -repo all -lb branch
   ```

2. **Use descriptive branch names with dates**:
   ```bash
   # Good examples
   -lb feature_user_auth_$(date +%Y%m%d)
   -lb hotfix_security_cve_2024_001
   -lb release_test_$(date +%Y%m%d)
   ```

3. **Enable progress tracking for large operations**:
   ```bash
   # All batch operations now show progress automatically
   ./git_sh1.sh fetch all --profile profile_name
   ./git_sh1.sh worktree add --profile profile_name -repo all -lb branch
   ```

### Development Workflow

1. **Use tab completion for efficiency**:
   ```bash
   ./git_sh1.sh [TAB]                    # Show all commands
   ./git_sh1.sh fetch [TAB]              # Show repository names
   ./git_sh1.sh worktree add [TAB]       # Show options and repos
   ```

2. **Verify before major operations**:
   ```bash
   ./git_sh1.sh verify all --profile profile_name
   DRY_RUN=true ./git_sh1.sh worktree add --profile profile -repo all -lb branch
   ```

3. **Use verbose mode for troubleshooting**:
   ```bash
   VERBOSE=true ./git_sh1.sh command arguments
   ```

### Error Prevention

✅ **Recommended Practices**:
- Always verify profiles exist before using them
- Use dry-run mode for complex operations
- Enable verbose logging when debugging
- Create descriptive branch names
- Regular profile backups

❌ **Avoid**:
- Generic branch names (`test`, `branch1`)
- Running commands without verifying configuration
- Creating worktrees in existing directories
- Ignoring warning messages

---

## Advanced Usage

### Custom Repository Mappings

Repository mappings in `repo_map.txt` are automatically sorted by path depth to prevent conflicts. Manual editing is possible but not recommended.

### Integration with CI/CD

```bash
# CI/CD pipeline example
./git_sh1.sh profile create ci/integration
./git_sh1.sh fetch all --profile ci/integration
./git_sh1.sh worktree add --profile ci/integration -repo all -lb ci_$(BUILD_NUMBER)

# Exit codes for automation
echo $?  # 0 = success, non-zero = failure
```

### Performance Optimization

For large repository sets:
- Use specific repository targeting instead of "all" when possible
- Monitor progress indicators to track performance
- Use profiles to reduce processing overhead
- Cache completion data is automatically managed

### Tab Completion Features

The script includes comprehensive tab completion:

```bash
./git_sh1.sh [TAB]                    # Commands: verify, fetch, worktree, profile, feature
./git_sh1.sh fetch [TAB]              # Repository names from config
./git_sh1.sh worktree add -repo [TAB] # Available repositories
./git_sh1.sh profile [TAB]            # Subcommands: create, list, show
./git_sh1.sh feature [TAB]            # Subcommands: create, list, show, switch, etc.
```

---

## Security Considerations

- All file paths are validated to prevent directory traversal
- Input sanitization prevents injection attacks
- Repository operations respect Git's security model
- Profile directories use safe permissions (755)
- Temporary files are properly cleaned up

---

## Version Compatibility

This script is compatible with:
- Git versions 2.5+
- Bash versions 4.0+
- xmllint (libxml2-utils package)
- Standard POSIX utilities

**Latest Version Features (2025)**:
- ✅ Fixed directory hierarchy conflicts
- ✅ Added comprehensive progress tracking
- ✅ Enhanced output formatting with spacing
- ✅ Intelligent tab completion system
- ✅ Improved error handling and recovery
- ✅ Smart repository ordering by depth

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Command line argument error |
| `3` | File or directory not found |
| `4` | Permission denied |
| `5` | Git operation failed |

---

## Summary

The git_sh1.sh script provides comprehensive repository management with:

✅ **Profile-based configuration management**  
✅ **Progress tracking for all batch operations**  
✅ **Intelligent repository ordering and conflict resolution**  
✅ **Enhanced user experience with spacing and clear output**  
✅ **Fish-shell-like tab completion**  
✅ **Robust error handling and recovery procedures**  
✅ **100% backward compatibility with existing workflows**  

This makes it a production-ready tool for managing complex multi-repository development environments with modern UX enhancements.

---

*For additional support, enable verbose logging (`VERBOSE=true`) and check the generated log files for detailed operation information.*