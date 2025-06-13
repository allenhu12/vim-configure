# Git SH1 Tab Completion Guide

## Overview

This guide shows you how to set up and use intelligent tab completion for the `git_sh1.sh` script, similar to modern shells like Fish. After setup, you can press [TAB] to auto-complete commands, repository names, feature names, and more.

## Quick Start

### 1. Copy Files to Your Server

```bash
# Copy completion files to your remote server
scp git_sh1_completion.bash user@server:/path/to/utility/
scp install_completion.sh user@server:/path/to/utility/
scp git_sh1_completion_guide.md user@server:/path/to/utility/
```

### 2. Install Completion (Choose One Method)

**Method A: Automatic Installation (Recommended)**
```bash
# On your server
cd /path/to/utility/
./install_completion.sh
```

**Method B: Using the main script**
```bash
./git_sh1.sh --install-completion
```

**Method C: Manual Installation**
```bash
# Add to your .bashrc
echo "source /path/to/utility/git_sh1_completion.bash" >> ~/.bashrc
source ~/.bashrc
```

### 3. Test Completion

```bash
# Restart your shell or run:
source ~/.bashrc

# Test completion
./git_sh1.sh [TAB]        # Should show: verify fetch worktree show_repos feature -h --help
./git_sh1.sh fetch [TAB]  # Should show repository names from your script
```

## Completion Features

### 🚀 **Command Completion**
```bash
./git_sh1.sh [TAB]
# Shows: verify fetch worktree show_repos feature -h --help --install-completion --clear-cache
```

### 📁 **Repository Name Completion**
```bash
./git_sh1.sh fetch [TAB]
# Shows: all controller opensource rks_ap dl linux_3_14 linux_4_4 ...

./git_sh1.sh verify [TAB]  
# Shows: all controller opensource rks_ap dl linux_3_14 linux_4_4 ...
```

### 🌿 **Worktree Command Completion**
```bash
./git_sh1.sh worktree [TAB]
# Shows: add pull-rebase

./git_sh1.sh worktree add [TAB]
# Shows: all controller opensource rks_ap ...

./git_sh1.sh worktree add controller -lb mybranch -rb [TAB]
# Shows: origin/master origin/main origin/develop origin/release/...
```

### ⭐ **Feature Management Completion**
```bash
./git_sh1.sh feature [TAB]
# Shows: create list show comment switch switchback pick

./git_sh1.sh feature create [TAB]
# Shows: -w --force (and lets you type feature name)

./git_sh1.sh feature create -w [TAB]
# Shows: available worktree names (local5, master, develop, etc.)

./git_sh1.sh feature create -w local5 my_feature [TAB]
# Shows: available repository names (excludes 'all' for feature creation)

./git_sh1.sh feature show [TAB]
# Shows: existing feature names from .git_sh1_features/

./git_sh1.sh feature switch [TAB]
# Shows: existing feature names

./git_sh1.sh feature pick my_feature [TAB]
# Shows: target branch names (master, main, develop, release)
```

### 🔧 **Smart Context-Aware Completion**

The completion system is intelligent and context-aware:

- **Repository validation**: Only shows valid repositories from your `repo_map`
- **Feature awareness**: Only shows existing features for commands that need them
- **Worktree detection**: Automatically discovers existing worktree directories
- **Flag completion**: Shows appropriate flags for each command
- **Parameter position**: Knows what type of parameter is expected at each position

## Installation Methods

### Method 1: Automatic Installer (Recommended)

```bash
./install_completion.sh [OPTIONS]

OPTIONS:
  -h, --help          Show help message
  -u, --uninstall     Uninstall completion
  -f, --force         Force installation (overwrite existing)
  -l, --local         Install for current user only (default)
  -g, --global        Install system-wide (requires sudo)
  -m, --manual        Show manual installation instructions
  --test              Test completion without installing
```

**Examples:**
```bash
./install_completion.sh                    # Install for current user
./install_completion.sh --global           # Install system-wide
./install_completion.sh --test             # Test without installing
./install_completion.sh --uninstall        # Remove completion
```

### Method 2: Built-in Installation

```bash
# Simple installation using the main script
./git_sh1.sh --install-completion

# Clear completion cache if needed
./git_sh1.sh --clear-cache
```

### Method 3: Manual Installation

**Option A: Add to .bashrc**
```bash
echo "source /path/to/utility/git_sh1_completion.bash" >> ~/.bashrc
source ~/.bashrc
```

**Option B: Copy to completion directory**
```bash
# User-specific
mkdir -p ~/.local/share/bash-completion/completions
cp git_sh1_completion.bash ~/.local/share/bash-completion/completions/git_sh1

# System-wide (requires sudo)
sudo cp git_sh1_completion.bash /etc/bash_completion.d/git_sh1
```

## Advanced Usage

### Debug Mode

Enable debug output to troubleshoot completion issues:

```bash
export GIT_SH1_DEBUG=1
./git_sh1.sh [TAB]
# Shows debug information about completion process
```

### Cache Management

The completion system uses caching for performance:

```bash
# Cache locations
~/.cache/git_sh1/repositories.cache    # Repository names
~/.cache/git_sh1/features.cache        # Feature names
~/.cache/git_sh1/worktrees.cache       # Worktree names
~/.cache/git_sh1/branches.cache        # Branch names

# Clear cache manually
rm -rf ~/.cache/git_sh1/

# Or use built-in command
./git_sh1.sh --clear-cache
```

### Performance Tuning

**Cache Expiry**: Caches expire after 5 minutes by default. To change:
```bash
# Edit git_sh1_completion.bash
CACHE_EXPIRY=600  # 10 minutes
```

**Repository Limit**: To prevent slow completion with many repositories:
```bash
# Edit git_sh1_completion.bash
head -50  # Shows only first 50 repositories
```

## Troubleshooting

### Common Issues

#### 1. "Completion not working"
**Cause**: Completion not properly loaded
**Solution**: 
```bash
# Check if completion is loaded
complete -p | grep git_sh1

# If not found, reload completion
source /path/to/git_sh1_completion.bash

# Or check .bashrc
grep git_sh1_completion ~/.bashrc
```

#### 2. "No repository names showing"
**Cause**: Script not found or repo_map not readable
**Solution**:
```bash
# Test manually
source /path/to/git_sh1_completion.bash
_git_sh1_get_repositories

# Check script location
_git_sh1_find_script

# Clear cache and retry
./git_sh1.sh --clear-cache
```

#### 3. "Permission denied during installation"
**Cause**: Insufficient permissions for system-wide installation
**Solution**:
```bash
# Try user-specific installation
./install_completion.sh --local

# Or use sudo for system-wide
sudo ./install_completion.sh --global
```

#### 4. "Feature names not completing"
**Cause**: Features directory not found
**Solution**:
```bash
# Check if features directory exists
ls -la .git_sh1_features/

# Create a test feature to populate cache
./git_sh1.sh feature create test_feature controller

# Clear cache
./git_sh1.sh --clear-cache
```

### Debug Steps

1. **Test completion loading**:
```bash
source ./git_sh1_completion.bash
echo "Completion loaded successfully"
```

2. **Test repository extraction**:
```bash
_git_sh1_get_repositories
```

3. **Test script detection**:
```bash
_git_sh1_find_script
```

4. **Enable debug mode**:
```bash
export GIT_SH1_DEBUG=1
./git_sh1.sh [TAB]
```

5. **Check cache files**:
```bash
ls -la ~/.cache/git_sh1/
cat ~/.cache/git_sh1/repositories.cache
```

## Examples of Tab Completion in Action

### Basic Command Completion
```bash
$ ./git_sh1.sh [TAB]
verify  fetch  worktree  show_repos  feature  -h  --help  --install-completion  --clear-cache

$ ./git_sh1.sh f[TAB]
fetch  feature

$ ./git_sh1.sh fe[TAB]
feature
```

### Repository Management
```bash
$ ./git_sh1.sh fetch [TAB]
all  controller  opensource  rks_ap  dl  linux_3_14  linux_4_4  linux_5_4

$ ./git_sh1.sh fetch c[TAB]
controller

$ ./git_sh1.sh verify o[TAB]
opensource
```

### Feature Workflow
```bash
$ ./git_sh1.sh feature [TAB]
create  list  show  comment  switch  switchback  pick

$ ./git_sh1.sh feature create [TAB]
-w  --force  

$ ./git_sh1.sh feature create -w [TAB]
local5  master  develop  unleashed_200.18.7.101_r370

$ ./git_sh1.sh feature create -w local5 my_feature [TAB]
controller  opensource  rks_ap  dl  linux_3_14

$ ./git_sh1.sh feature show [TAB]
dropbear_replacement  ssl_update  security_patches

$ ./git_sh1.sh feature pick my_feature [TAB]
master  main  develop  release
```

### Worktree Management
```bash
$ ./git_sh1.sh worktree [TAB]
add  pull-rebase

$ ./git_sh1.sh worktree add [TAB]
all  controller  opensource  rks_ap

$ ./git_sh1.sh worktree add controller -lb [TAB]
# (lets you type branch name)

$ ./git_sh1.sh worktree add controller -lb mybranch -rb [TAB]
origin/master  origin/main  origin/develop  origin/release/unleashed_200.17
```

## Performance Notes

- **First completion** may be slower (0.5-1s) as it builds cache
- **Subsequent completions** are fast (<100ms) using cached data
- **Cache refresh** happens automatically every 5 minutes
- **Large repositories** (50+) may experience slight delays

## Compatibility

### Supported Shells
- ✅ **Bash 4.0+** (Primary support)
- ✅ **Bash 3.2+** (Basic support, some features may be limited)
- ⚠️ **Zsh** (Partial support with `bashcompinit`)
- ❌ **Fish** (Not supported, different completion system)

### Supported Operating Systems
- ✅ **Linux** (All distributions)
- ✅ **macOS** (With bash-completion package: `brew install bash-completion`)
- ✅ **WSL/Windows** (Windows Subsystem for Linux)
- ❌ **Windows PowerShell** (Not supported)

### Required Tools
- `bash` (4.0+ recommended)
- `grep`, `sed`, `cut` (standard utilities)
- `find` (for directory scanning)
- `stat` (for cache timestamp checking)

## Uninstalling Completion

### Automatic Uninstall
```bash
./install_completion.sh --uninstall
```

### Manual Uninstall
```bash
# Remove from .bashrc
grep -v git_sh1_completion ~/.bashrc > ~/.bashrc.tmp
mv ~/.bashrc.tmp ~/.bashrc

# Remove completion files
rm -f ~/.local/share/bash-completion/completions/git_sh1
rm -f ~/.bash_completion.d/git_sh1_completion.bash
sudo rm -f /etc/bash_completion.d/git_sh1

# Clear cache
rm -rf ~/.cache/git_sh1/

# Restart shell
exec bash
```

---

## Summary

The Git SH1 completion system provides:

✅ **Intelligent tab completion** for all commands and parameters
✅ **Context-aware suggestions** based on current command and position  
✅ **Dynamic content discovery** from your actual script configuration
✅ **Performance optimization** with smart caching
✅ **Easy installation** with multiple installation methods
✅ **Comprehensive troubleshooting** with debug mode and cache management

This dramatically improves the user experience of the `git_sh1.sh` script, making it as easy to use as modern CLI tools with fish-shell-like completion capabilities.