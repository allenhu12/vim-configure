# git_sh1.sh Workflow Guide

## Table of Contents

1. [Workflow Overview](#workflow-overview)
2. [Getting Started](#getting-started)
3. [Common Workflows](#common-workflows)
4. [Advanced Workflows](#advanced-workflows)
5. [Best Practices](#best-practices)
6. [Real-World Examples](#real-world-examples)

## Workflow Overview

This guide provides step-by-step workflows for using the git_sh1.sh script in various development scenarios. The script supports both traditional repository management and modern profile-based configurations.

## Getting Started

### 1. Initial Setup and Verification

```bash
# Navigate to your git-depot directory
cd /path/to/git-depot

# Verify script location and permissions
ls -la utility/git_sh1.sh
chmod +x utility/git_sh1.sh

# Check current repository status
./utility/git_sh1.sh repo-check all

# List available repositories
./utility/git_sh1.sh show-repos
```

### 2. Create Your First Profile

```bash
# Create a profile from an existing manifest file
./utility/git_sh1.sh profile create unleashed_200.19/openwrt_common --manifest /path/to/manifest.xml

# Verify profile creation
./utility/git_sh1.sh profile list

# View profile details
./utility/git_sh1.sh profile show unleashed_200.19/openwrt_common
```

## Common Workflows

### Workflow 1: Setting Up a New Development Environment

**Scenario**: You need to set up a development environment for a new release.

```bash
# Step 1: Create profile from manifest
./utility/git_sh1.sh profile create unleashed_200.19/openwrt_common \
  --manifest /releases/unleashed_200.19/manifests/openwrt_common.xml

# Step 2: Verify all repositories are available
./utility/git_sh1.sh repo-check all --profile unleashed_200.19/openwrt_common

# Step 3: Fetch latest updates for all repositories
./utility/git_sh1.sh fetch all --profile unleashed_200.19/openwrt_common

# Step 4: Create development worktrees
./utility/git_sh1.sh worktree add \
  --profile unleashed_200.19/openwrt_common \
  -repo all \
  -lb dev_branch_$(date +%Y%m%d)
```

### Workflow 2: Feature Development Across Multiple Repositories

**Scenario**: Implementing a feature that spans multiple repositories.

```bash
# Step 1: Create feature branches in relevant repositories
./utility/git_sh1.sh feature create new_auth_system \
  origin/release/unleashed_200.19.7.11 \
  controller,ap_scg_common,rks_ap

# Step 2: Create worktrees for feature development
./utility/git_sh1.sh worktree add \
  --profile unleashed_200.19/openwrt_common \
  -repo controller,ap_scg_common,rks_ap \
  -lb feature_new_auth_system

# Step 3: Work on your changes in the worktrees
# (Development work happens here)

# Step 4: Regularly sync with upstream
./utility/git_sh1.sh worktree pull-rebase \
  --profile unleashed_200.19/openwrt_common \
  -repo all \
  -lb feature_new_auth_system

# Step 5: Check feature status
./utility/git_sh1.sh feature status new_auth_system
```

### Workflow 3: Release Preparation and Testing

**Scenario**: Preparing for a release by testing specific repository combinations.

```bash
# Step 1: Create release-specific profile
./utility/git_sh1.sh profile create unleashed_200.19/release_candidate \
  --manifest /releases/unleashed_200.19/rc/manifest.xml

# Step 2: Create clean testing environment
./utility/git_sh1.sh worktree add \
  --profile unleashed_200.19/release_candidate \
  -repo all \
  -lb release_test_$(date +%Y%m%d)

# Step 3: Verify all repositories are on correct branches
./utility/git_sh1.sh repo-check all --profile unleashed_200.19/release_candidate

# Step 4: Run integration tests
# (Testing commands here)

# Step 5: Clean up after testing
./utility/git_sh1.sh feature cleanup release_test_$(date +%Y%m%d)
```

### Workflow 4: Hotfix Development

**Scenario**: Creating a hotfix that needs to be applied to specific repositories.

```bash
# Step 1: Create hotfix profile (if needed)
./utility/git_sh1.sh profile create unleashed_200.19/hotfix \
  --manifest /releases/unleashed_200.19/hotfix/manifest.xml

# Step 2: Create hotfix branches
./utility/git_sh1.sh feature create security_hotfix_001 \
  origin/release/unleashed_200.19.7.11 \
  controller,ap_scg_common

# Step 3: Create worktrees for hotfix development
./utility/git_sh1.sh worktree add \
  --profile unleashed_200.19/hotfix \
  -repo controller,ap_scg_common \
  -lb hotfix_security_001

# Step 4: Implement and test hotfix
# (Development and testing work)

# Step 5: Sync changes if needed
./utility/git_sh1.sh feature sync security_hotfix_001
```

## Advanced Workflows

### Workflow 5: Cross-Profile Development

**Scenario**: Working with multiple profiles simultaneously for compatibility testing.

```bash
# Step 1: List all available profiles
./utility/git_sh1.sh profile list

# Step 2: Create worktrees for each profile
./utility/git_sh1.sh worktree add \
  --profile unleashed_200.19/openwrt_common \
  -repo all \
  -lb compat_test_openwrt

./utility/git_sh1.sh worktree add \
  --profile unleashed_200.19/buildroot_common \
  -repo all \
  -lb compat_test_buildroot

# Step 3: Compare repository sets
./utility/git_sh1.sh profile show unleashed_200.19/openwrt_common
./utility/git_sh1.sh profile show unleashed_200.19/buildroot_common

# Step 4: Test changes across both environments
# (Testing and validation work)
```

### Workflow 6: Large-Scale Repository Synchronization

**Scenario**: Synchronizing a large number of repositories with upstream changes.

```bash
# Step 1: Check current status of all repositories
./utility/git_sh1.sh repo-check all --profile unleashed_200.19/openwrt_common

# Step 2: Fetch updates in batches (for better control)
repos=("controller" "ap_scg_common" "rks_ap" "linux_5_4_12_5")
for repo in "${repos[@]}"; do
  echo "Fetching $repo..."
  ./utility/git_sh1.sh fetch "$repo" --profile unleashed_200.19/openwrt_common
  sleep 2  # Avoid overwhelming the Git server
done

# Step 3: Update existing worktrees
./utility/git_sh1.sh worktree pull-rebase \
  --profile unleashed_200.19/openwrt_common \
  -repo all \
  -lb main_development

# Step 4: Verify synchronization
./utility/git_sh1.sh repo-check all --profile unleashed_200.19/openwrt_common
```

### Workflow 7: Profile Migration and Cleanup

**Scenario**: Migrating from old profiles to new ones and cleaning up obsolete data.

```bash
# Step 1: List current profiles
./utility/git_sh1.sh profile list

# Step 2: Create new profile structure
./utility/git_sh1.sh profile create unleashed_200.20/openwrt_common \
  --manifest /releases/unleashed_200.20/manifests/openwrt_common.xml

# Step 3: Migrate active worktrees (manual process)
# Identify active worktrees
ls -la /path/to/git-depot/

# Step 4: Test new profile
./utility/git_sh1.sh repo-check all --profile unleashed_200.20/openwrt_common

# Step 5: Clean up old profiles (manual verification first)
# rm -rf .git_sh1_profiles/unleashed_200.19/  # Only after confirming migration
```

## Best Practices

### Repository Management

1. **Always use profiles for new projects**:
   ```bash
   # Good: Profile-based approach
   ./utility/git_sh1.sh worktree add --profile release/config -repo all -lb branch
   
   # Avoid: Legacy hardcoded approach (when profiles are available)
   ./utility/git_sh1.sh worktree add -repo all -lb branch
   ```

2. **Verify repository status before major operations**:
   ```bash
   ./utility/git_sh1.sh repo-check all --profile your_profile
   ```

3. **Use descriptive branch names**:
   ```bash
   # Good: Descriptive names
   -lb feature_user_authentication_$(date +%Y%m%d)
   -lb hotfix_security_cve_2024_001
   
   # Avoid: Generic names
   -lb test
   -lb branch1
   ```

### Feature Development

1. **Create feature branches before starting work**:
   ```bash
   ./utility/git_sh1.sh feature create feature_name base_branch repo_list
   ```

2. **Regularly sync with upstream**:
   ```bash
   ./utility/git_sh1.sh feature sync feature_name
   ./utility/git_sh1.sh worktree pull-rebase --profile profile_name -repo all -lb branch_name
   ```

3. **Clean up completed features**:
   ```bash
   ./utility/git_sh1.sh feature cleanup completed_feature_name
   ```

### Error Prevention

1. **Use dry-run mode for complex operations**:
   ```bash
   DRY_RUN=true ./utility/git_sh1.sh worktree add --profile profile -repo all -lb branch
   ```

2. **Enable verbose mode for troubleshooting**:
   ```bash
   VERBOSE=true ./utility/git_sh1.sh command arguments
   ```

3. **Validate profiles before use**:
   ```bash
   ./utility/git_sh1.sh profile show profile_name
   ```

## Real-World Examples

### Example 1: Daily Development Workflow

```bash
#!/bin/bash
# Daily development setup script

PROFILE="unleashed_200.19/openwrt_common"
BRANCH="daily_dev_$(date +%Y%m%d)"

# Start of day setup
echo "Setting up daily development environment..."

# Fetch latest updates
./utility/git_sh1.sh fetch all --profile "$PROFILE"

# Create fresh worktrees
./utility/git_sh1.sh worktree add \
  --profile "$PROFILE" \
  -repo all \
  -lb "$BRANCH"

echo "Development environment ready in branch: $BRANCH"
echo "Worktrees created in: /path/to/git-depot/$BRANCH/"
```

### Example 2: Release Validation Script

```bash
#!/bin/bash
# Release validation workflow

RELEASE_PROFILE="unleashed_200.19/release_candidate"
TEST_BRANCH="release_validation_$(date +%Y%m%d_%H%M)"

# Create clean test environment
echo "Creating release validation environment..."

# Verify profile exists
if ! ./utility/git_sh1.sh profile show "$RELEASE_PROFILE" > /dev/null 2>&1; then
  echo "ERROR: Profile $RELEASE_PROFILE not found"
  exit 1
fi

# Create test worktrees
./utility/git_sh1.sh worktree add \
  --profile "$RELEASE_PROFILE" \
  -repo all \
  -lb "$TEST_BRANCH"

# Verify all repositories are ready
./utility/git_sh1.sh repo-check all --profile "$RELEASE_PROFILE"

echo "Release validation environment ready: $TEST_BRANCH"
```

### Example 3: Multi-Repository Feature Implementation

```bash
#!/bin/bash
# Feature development across multiple repositories

FEATURE_NAME="user_management_v2"
BASE_BRANCH="origin/release/unleashed_200.19.7.11"
AFFECTED_REPOS="controller,ap_scg_common,rks_ap"
PROFILE="unleashed_200.19/openwrt_common"

echo "Starting feature development: $FEATURE_NAME"

# Step 1: Create feature branches
./utility/git_sh1.sh feature create "$FEATURE_NAME" "$BASE_BRANCH" "$AFFECTED_REPOS"

# Step 2: Create development worktrees
./utility/git_sh1.sh worktree add \
  --profile "$PROFILE" \
  -repo "$AFFECTED_REPOS" \
  -lb "feature_${FEATURE_NAME}"

# Step 3: Set up development environment
echo "Feature development environment ready!"
echo "Affected repositories: $AFFECTED_REPOS"
echo "Development branch: feature_${FEATURE_NAME}"
echo ""
echo "Next steps:"
echo "1. Implement changes in the worktree directories"
echo "2. Run: ./utility/git_sh1.sh feature status $FEATURE_NAME"
echo "3. Sync regularly: ./utility/git_sh1.sh feature sync $FEATURE_NAME"
```

### Example 4: Emergency Hotfix Workflow

```bash
#!/bin/bash
# Emergency hotfix deployment workflow

HOTFIX_ID="$1"
SECURITY_REPOS="controller,ap_scg_common"
HOTFIX_PROFILE="unleashed_200.19/security_hotfix"

if [ -z "$HOTFIX_ID" ]; then
  echo "Usage: $0 <hotfix_id>"
  echo "Example: $0 CVE-2024-001"
  exit 1
fi

echo "Creating emergency hotfix environment for: $HOTFIX_ID"

# Create hotfix branches
./utility/git_sh1.sh feature create "hotfix_$HOTFIX_ID" \
  "origin/release/unleashed_200.19.7.11" \
  "$SECURITY_REPOS"

# Create immediate development environment
./utility/git_sh1.sh worktree add \
  --profile "$HOTFIX_PROFILE" \
  -repo "$SECURITY_REPOS" \
  -lb "emergency_hotfix_$HOTFIX_ID"

echo "Emergency hotfix environment ready!"
echo "Hotfix ID: $HOTFIX_ID"
echo "Affected repositories: $SECURITY_REPOS"
echo "Development branch: emergency_hotfix_$HOTFIX_ID"
```

---

This workflow guide provides practical examples for using the git_sh1.sh script in real development scenarios. Adapt these workflows to match your specific development processes and requirements.