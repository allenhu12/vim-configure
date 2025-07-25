# git_sh1.sh Troubleshooting Guide

## Table of Contents

1. [Common Issues](#common-issues)
2. [Error Codes and Messages](#error-codes-and-messages)
3. [Profile-Related Issues](#profile-related-issues)
4. [Worktree Issues](#worktree-issues)
5. [Git Operation Failures](#git-operation-failures)
6. [Path and Permission Issues](#path-and-permission-issues)
7. [Debug and Diagnostic Tools](#debug-and-diagnostic-tools)
8. [Recovery Procedures](#recovery-procedures)

## Common Issues

### Issue 1: "Invalid worktree path" Error

**Problem**: Getting "Invalid worktree path for: [repo_name]" errors during worktree creation.

**Symptoms**:
```
Auto-detected upstream for controller: origin/release/unleashed_200.19.7.11
Invalid worktree path for: controller
```

**Root Cause**: Path validation function trying to access directories that don't exist yet.

**Solution**:
```bash
# Check if you're using the latest version of the script
grep -n "validate_worktree_path" utility/git_sh1.sh

# If the function doesn't exist, the script needs updating
# The script should use validate_worktree_path for worktree creation
```

**Workaround**:
```bash
# Create the worktree directory structure manually first
mkdir -p /path/to/git-depot/branch_name

# Then run the worktree command
./utility/git_sh1.sh worktree add --profile profile_name -repo repo_name -lb branch_name
```

### Issue 2: Profile Not Found

**Problem**: Profile doesn't exist or can't be located.

**Symptoms**:
```
ERROR: Profile 'unleashed_200.19/openwrt_common' not found
```

**Diagnosis**:
```bash
# List available profiles
./utility/git_sh1.sh profile list

# Check profile directory structure
ls -la .git_sh1_profiles/

# Verify profile path
ls -la .git_sh1_profiles/unleashed_200.19/openwrt_common/
```

**Solutions**:
1. **Create the profile**:
   ```bash
   ./utility/git_sh1.sh profile create unleashed_200.19/openwrt_common --manifest /path/to/manifest.xml
   ```

2. **Check profile name spelling**:
   ```bash
   ./utility/git_sh1.sh profile list | grep -i unleashed
   ```

### Issue 3: Repository Not Found

**Problem**: Repository doesn't exist in the current configuration.

**Symptoms**:
```
Repository controller not found in repo_map
ERROR: Repository not found: /path/to/repo/controller
```

**Diagnosis**:
```bash
# Check available repositories
./utility/git_sh1.sh show-repos

# Check repository status
./utility/git_sh1.sh repo-check all

# Verify profile repository mapping
./utility/git_sh1.sh profile show profile_name
```

**Solutions**:
1. **Use correct repository name**:
   ```bash
   # Check exact repository names
   ./utility/git_sh1.sh show-repos | grep controller
   ```

2. **Verify repository exists**:
   ```bash
   ls -la /path/to/git-depot/repos/
   ```

3. **Update profile if repository was added**:
   ```bash
   ./utility/git_sh1.sh profile create profile_name --manifest updated_manifest.xml
   ```

## Error Codes and Messages

### Path Validation Errors

**Error**: `Path outside allowed boundaries: /dangerous/path`
- **Cause**: Security validation preventing directory traversal
- **Solution**: Use relative paths within the git-depot structure

**Error**: `Invalid path: ../../../etc/passwd`
- **Cause**: Attempt to access unauthorized locations
- **Solution**: Use only valid repository and worktree paths

### Git Operation Errors

**Error**: `fatal: not a git repository`
- **Cause**: Directory is not a Git repository
- **Solution**: Verify repository setup and initialization

**Error**: `fatal: couldn't find remote ref`
- **Cause**: Remote branch doesn't exist
- **Solution**: Check branch names and remote configuration

### Manifest Parsing Errors

**Error**: `xmllint: command not found`
- **Cause**: XML parsing tools not installed
- **Solution**: Install libxml2-utils package

**Error**: `Failed to parse manifest.xml`
- **Cause**: Invalid XML format
- **Solution**: Validate XML syntax and structure

## Profile-Related Issues

### Corrupted Profile Data

**Problem**: Profile exists but contains invalid data.

**Diagnosis**:
```bash
# Check profile files
ls -la .git_sh1_profiles/profile_name/

# Validate manifest.xml
xmllint --noout .git_sh1_profiles/profile_name/manifest.xml

# Check repo_map.txt format
cat .git_sh1_profiles/profile_name/repo_map.txt
```

**Recovery**:
```bash
# Regenerate profile from manifest
./utility/git_sh1.sh profile create profile_name --manifest manifest.xml

# Or manually fix repo_map.txt format:
# Each line should be: repository_name:local_folder_name
```

### Profile Directory Permissions

**Problem**: Cannot read or write profile data.

**Symptoms**:
```
Permission denied: .git_sh1_profiles/profile_name/
```

**Solution**:
```bash
# Fix permissions
chmod -R 755 .git_sh1_profiles/
chown -R $USER:$USER .git_sh1_profiles/
```

### Missing Manifest File

**Problem**: Profile created without proper manifest.

**Diagnosis**:
```bash
# Check for manifest file
ls -la .git_sh1_profiles/profile_name/manifest.xml

# Verify manifest content
cat .git_sh1_profiles/profile_name/manifest.xml
```

**Recovery**:
```bash
# Recreate profile with correct manifest
rm -rf .git_sh1_profiles/profile_name/
./utility/git_sh1.sh profile create profile_name --manifest /correct/path/manifest.xml
```

## Worktree Issues

### Worktree Already Exists

**Problem**: Attempting to create worktree in existing location.

**Symptoms**:
```
fatal: '/path/to/worktree' already exists
```

**Solutions**:
1. **Use different branch name**:
   ```bash
   ./utility/git_sh1.sh worktree add -repo repo_name -lb different_branch_name
   ```

2. **Remove existing worktree**:
   ```bash
   git worktree remove /path/to/existing/worktree
   rm -rf /path/to/existing/worktree  # If needed
   ```

### Upstream Branch Not Found

**Problem**: Auto-detected upstream branch doesn't exist.

**Symptoms**:
```
Auto-detected upstream for repo: origin/nonexistent_branch
fatal: invalid reference: origin/nonexistent_branch
```

**Solutions**:
1. **Specify correct upstream manually**:
   ```bash
   ./utility/git_sh1.sh worktree add -repo repo_name -lb local_branch -rb origin/correct_branch
   ```

2. **Update remote references**:
   ```bash
   cd /path/to/repo && git fetch --all
   ```

3. **Check available remote branches**:
   ```bash
   cd /path/to/repo && git branch -r
   ```

### Worktree Cleanup Issues

**Problem**: Cannot remove worktree directories.

**Symptoms**:
```
fatal: '/path/to/worktree' is not a working tree
rm: cannot remove '/path/to/worktree': Directory not empty
```

**Solutions**:
```bash
# Force remove from Git
git worktree remove --force /path/to/worktree

# Manual cleanup
rm -rf /path/to/worktree

# Clean up Git references
git worktree prune
```

## Git Operation Failures

### Network and Authentication Issues

**Problem**: Cannot fetch from remote repositories.

**Symptoms**:
```
fatal: Could not read from remote repository
fatal: Authentication failed
```

**Diagnosis**:
```bash
# Test SSH connectivity
ssh -T git@github.com

# Check remote URLs
git remote -v

# Test manual fetch
git fetch origin
```

**Solutions**:
1. **Fix SSH keys**:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ssh -T git@remote-server
   ```

2. **Update remote URLs**:
   ```bash
   git remote set-url origin ssh://user@server:port/repo.git
   ```

### Branch Conflicts

**Problem**: Cannot create or switch branches due to conflicts.

**Symptoms**:
```
error: Your local changes to the following files would be overwritten
fatal: cannot create worktree
```

**Solutions**:
```bash
# Stash changes
git stash push -m "temporary stash for worktree creation"

# Clean working directory
git clean -fd

# Create worktree with clean state
./utility/git_sh1.sh worktree add -repo repo_name -lb branch_name
```

## Path and Permission Issues

### Directory Access Denied

**Problem**: Cannot access repository or worktree directories.

**Diagnosis**:
```bash
# Check directory permissions
ls -la /path/to/git-depot/
ls -la /path/to/repositories/

# Check current user permissions
whoami
groups
```

**Solutions**:
```bash
# Fix permissions
sudo chown -R $USER:$USER /path/to/git-depot/
chmod -R 755 /path/to/git-depot/

# Add user to appropriate groups
sudo usermod -a -G git $USER
```

### Disk Space Issues

**Problem**: Insufficient disk space for operations.

**Symptoms**:
```
fatal: write error: No space left on device
```

**Diagnosis**:
```bash
# Check disk usage
df -h /path/to/git-depot/
du -sh /path/to/git-depot/.git_sh1_profiles/
```

**Solutions**:
```bash
# Clean up old worktrees
git worktree prune

# Remove old profiles
rm -rf .git_sh1_profiles/old_unused_profiles/

# Clean Git objects
git gc --aggressive --prune=now
```

## Debug and Diagnostic Tools

### Enable Verbose Logging

```bash
# Enable verbose mode
VERBOSE=true ./utility/git_sh1.sh command arguments

# Enable debug logging
export GIT_SH1_LOG_LEVEL=DEBUG
./utility/git_sh1.sh command arguments
```

### Dry Run Mode

```bash
# Test commands without execution
DRY_RUN=true ./utility/git_sh1.sh command arguments
```

### Manual Diagnostics

```bash
# Check script variables
./utility/git_sh1.sh --debug-vars

# Validate environment
./utility/git_sh1.sh --check-env

# Test profile parsing
./utility/git_sh1.sh profile show profile_name --verbose
```

### Log File Analysis

```bash
# Find log files
find . -name "*.log" -type f

# Recent errors
grep -i error .git_sh1_logs/*.log | tail -10

# Specific operation logs
grep -i "worktree" .git_sh1_logs/*.log
```

## Recovery Procedures

### Complete Environment Reset

```bash
#!/bin/bash
# Complete reset procedure

echo "WARNING: This will reset all profiles and worktrees!"
read -p "Continue? (y/N): " confirm

if [[ "$confirm" != "y" ]]; then
    exit 0
fi

# Remove all worktrees
git worktree list | grep -v "(bare)" | awk '{print $1}' | xargs -I {} git worktree remove --force {}

# Clean up directories
rm -rf .git_sh1_profiles/
rm -rf .git_sh1_logs/

# Prune Git references
git worktree prune

echo "Environment reset complete. Please recreate profiles."
```

### Profile Backup and Restore

```bash
# Backup profiles
tar -czf profiles_backup_$(date +%Y%m%d).tar.gz .git_sh1_profiles/

# Restore profiles
tar -xzf profiles_backup_20240101.tar.gz

# Verify restored profiles
./utility/git_sh1.sh profile list
```

### Repository Consistency Check

```bash
#!/bin/bash
# Check repository consistency

echo "Checking repository consistency..."

# Check each repository
for repo_dir in */; do
    if [ -d "$repo_dir/.git" ]; then
        echo "Checking $repo_dir..."
        cd "$repo_dir"
        
        # Check Git status
        if ! git status > /dev/null 2>&1; then
            echo "ERROR: $repo_dir has Git issues"
        fi
        
        # Check remote connectivity
        if ! git ls-remote origin > /dev/null 2>&1; then
            echo "WARNING: $repo_dir cannot reach remote"
        fi
        
        cd ..
    fi
done

echo "Repository consistency check complete."
```

---

For additional support, enable verbose logging and check the generated log files in `.git_sh1_logs/` for detailed error information.