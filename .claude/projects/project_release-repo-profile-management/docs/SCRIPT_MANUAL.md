# git_sh1.sh Script Manual

## Table of Contents

1. [Overview](#overview)
2. [Installation & Setup](#installation--setup)
3. [Core Concepts](#core-concepts)
4. [Profile Management](#profile-management)
5. [Repository Operations](#repository-operations)
6. [Worktree Management](#worktree-management)
7. [Feature Branch Management](#feature-branch-management)
8. [Command Reference](#command-reference)
9. [Configuration Options](#configuration-options)
10. [Error Handling](#error-handling)

## Overview

The `git_sh1.sh` script is a comprehensive Git repository management tool designed for multi-repository development workflows. It provides profile-based configuration management, automated worktree operations, and feature branch management across multiple repositories.

### Key Features

- **Profile-Based Configuration**: Manage different repository sets using XML manifest files
- **Worktree Management**: Create and manage Git worktrees across multiple repositories
- **Feature Branch Operations**: Coordinate feature development across repository boundaries
- **Repository Synchronization**: Fetch, pull, and rebase operations across repository sets
- **Automated Upstream Detection**: Intelligent branch detection from manifest files
- **Backward Compatibility**: Works with existing hardcoded repository configurations

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
├── repo1/
├── repo2/
├── utility/
│   └── git_sh1.sh
└── .git_sh1_profiles/
    └── {release}/
        └── {config_type}/
            ├── manifest.xml
            ├── repo_map.txt
            └── metadata.json
```

### Initial Setup

1. Place the script in the `utility/` directory within your git-depot structure
2. Make the script executable: `chmod +x utility/git_sh1.sh`
3. Run from any directory within the git-depot structure

## Core Concepts

### Profiles

Profiles define repository sets and configurations for specific releases or build types. Each profile contains:

- **manifest.xml**: Source of truth defining repositories and their configurations
- **repo_map.txt**: Generated mapping of repository names to local directories
- **metadata.json**: Profile metadata and configuration details

### Repository Base (`repo_base`)

The base directory where individual repositories are located. Automatically detected from the git-depot structure.

### Worktree Base (`worktree_base_path`)

The base directory for worktree creations, typically the git-depot root directory.

## Profile Management

### Creating Profiles

Create profiles from XML manifest files:

```bash
./git_sh1.sh profile create {release}/{config_type} --manifest /path/to/manifest.xml
```

Example:
```bash
./git_sh1.sh profile create unleashed_200.19/openwrt_common --manifest /path/to/openwrt_common.xml
```

### Listing Profiles

View all available profiles:

```bash
./git_sh1.sh profile list
```

Example output:
```
Available Profiles:
├── unleashed_200.19/
│   ├── openwrt_common
│   ├── openwrt_r370
│   └── buildroot_common
└── unleashed_200.20/
    └── openwrt_common
```

### Viewing Profile Details

Display profile information and repository mappings:

```bash
./git_sh1.sh profile show {release}/{config_type}
```

Example:
```bash
./git_sh1.sh profile show unleashed_200.19/openwrt_common
```

## Repository Operations

### Repository Status Check

Check the status of repositories in the current configuration:

```bash
./git_sh1.sh repo-check [all|repo_name]
```

Examples:
```bash
./git_sh1.sh repo-check all
./git_sh1.sh repo-check controller
```

### Repository Listing

Show all available repositories:

```bash
./git_sh1.sh show-repos
```

### Fetching Updates

Fetch updates from remote repositories:

```bash
./git_sh1.sh fetch [all|repo_name] [--profile profile_name]
```

Examples:
```bash
# Fetch all repositories using default configuration
./git_sh1.sh fetch all

# Fetch all repositories using a specific profile
./git_sh1.sh fetch all --profile unleashed_200.19/openwrt_common

# Fetch specific repository
./git_sh1.sh fetch controller --profile unleashed_200.19/openwrt_common
```

## Worktree Management

### Creating Worktrees

Create Git worktrees for development branches:

```bash
./git_sh1.sh worktree add [options] -repo {all|repo_name} -lb {local_branch} [-rb {remote_branch}]
```

#### Options:
- `--profile {profile_name}`: Use specific profile for repository set
- `-repo {all|repo_name}`: Target repositories (all or specific)
- `-lb {local_branch}`: Local branch name for worktree
- `-rb {remote_branch}`: Remote branch to track (optional, auto-detected from profile)

#### Examples:

**Create worktrees for all repositories with profile:**
```bash
./git_sh1.sh worktree add --profile unleashed_200.19/openwrt_common -repo all -lb my_feature_branch
```

**Create worktree for specific repository:**
```bash
./git_sh1.sh worktree add -repo controller -lb my_feature_branch -rb origin/release/unleashed_200.19.7.11
```

**Auto-detect upstream from profile:**
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

**Pull-rebase all repositories in a worktree with profile:**
```bash
./git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common -repo all -lb my_feature_branch
```

**Pull-rebase specific repository:**
```bash
./git_sh1.sh worktree pull-rebase -repo controller -lb my_feature_branch
```

**Legacy syntax (backward compatibility):**
```bash
./git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common all my_feature_branch
./git_sh1.sh worktree pull-rebase controller my_feature_branch
```

## Feature Branch Management

### Creating Feature Branches

Create coordinated feature branches across repositories:

```bash
./git_sh1.sh feature create {feature_name} {base_branch} [all|repo1,repo2,...]
```

Example:
```bash
./git_sh1.sh feature create new_auth_system release/unleashed_200.19.7.11 all
```

### Feature Status

Check status of feature branches:

```bash
./git_sh1.sh feature status {feature_name}
```

### Feature Synchronization

Synchronize feature branches with their base branches:

```bash
./git_sh1.sh feature sync {feature_name}
```

### Feature Cleanup

Remove feature branches from repositories:

```bash
./git_sh1.sh feature cleanup {feature_name}
```

## Command Reference

### Global Options

- `--verbose`: Enable verbose output
- `--dry-run`: Show what would be done without executing
- `--help`: Show help information

### Profile Commands

| Command | Description | Example |
|---------|-------------|---------|
| `profile create` | Create new profile from manifest | `./git_sh1.sh profile create release/config --manifest manifest.xml` |
| `profile list` | List all available profiles | `./git_sh1.sh profile list` |
| `profile show` | Show profile details | `./git_sh1.sh profile show release/config` |

### Repository Commands

| Command | Description | Example |
|---------|-------------|---------|
| `repo-check` | Check repository status | `./git_sh1.sh repo-check all` |
| `show-repos` | List all repositories | `./git_sh1.sh show-repos` |
| `fetch` | Fetch repository updates | `./git_sh1.sh fetch all --profile release/config` |

### Worktree Commands

| Command | Description | Example |
|---------|-------------|---------|
| `worktree add` | Create new worktree | `./git_sh1.sh worktree add --profile release/config -repo all -lb branch` |
| `worktree pull-rebase` | Update worktree | `./git_sh1.sh worktree pull-rebase -repo all -lb branch` |

### Feature Commands

| Command | Description | Example |
|---------|-------------|---------|
| `feature create` | Create feature branches | `./git_sh1.sh feature create name base_branch all` |
| `feature status` | Check feature status | `./git_sh1.sh feature status name` |
| `feature sync` | Sync feature branches | `./git_sh1.sh feature sync name` |
| `feature cleanup` | Remove feature branches | `./git_sh1.sh feature cleanup name` |

## Configuration Options

### Environment Variables

- `VERBOSE`: Enable verbose logging (true/false)
- `DRY_RUN`: Enable dry-run mode (true/false)
- `GIT_SH1_LOG_LEVEL`: Set logging level (DEBUG, INFO, WARN, ERROR)

### Script Variables

The script automatically detects the following paths:
- `git_depot_dir`: Root git-depot directory
- `repo_base`: Repository base directory
- `worktree_base_path`: Worktree base directory
- `profiles_dir`: Profile storage directory

## Error Handling

### Common Error Scenarios

1. **Invalid Profile**: Profile does not exist or is malformed
2. **Missing Repository**: Repository not found in current configuration
3. **Path Validation**: Invalid or unsafe file paths
4. **Git Operations**: Git command failures (network, permissions, conflicts)
5. **Manifest Parsing**: XML parsing errors or missing elements

### Error Resolution

The script provides detailed error messages with suggested resolutions:

```bash
ERROR: Profile 'invalid/profile' not found
Suggestion: Run './git_sh1.sh profile list' to see available profiles
```

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
VERBOSE=true ./git_sh1.sh command arguments
```

### Log Files

The script generates log files in the `.git_sh1_logs/` directory with timestamps and operation details.

## Advanced Usage

### Custom Repository Mappings

For advanced users, repository mappings can be customized by editing the `repo_map.txt` file in profile directories.

### Integration with CI/CD

The script supports automation through:
- Exit codes for success/failure detection
- JSON output formats for machine parsing
- Dry-run mode for validation

### Performance Optimization

For large repository sets:
- Use specific repository targeting instead of "all"
- Leverage parallel operations where supported
- Monitor log files for performance bottlenecks

## Security Considerations

- All file paths are validated to prevent directory traversal
- Input sanitization prevents injection attacks
- Repository operations respect Git's security model
- Profile directories use safe permissions

## Version Compatibility

This script is compatible with:
- Git versions 2.5+
- Bash versions 4.0+
- xmllint (libxml2-utils package)
- Standard POSIX utilities

---

For additional help or troubleshooting, refer to the companion documentation files or contact the development team.