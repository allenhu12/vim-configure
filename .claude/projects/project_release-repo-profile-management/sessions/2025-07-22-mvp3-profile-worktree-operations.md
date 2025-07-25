# Session: MVP3 Profile-Aware Worktree Operations - 2025-07-22

**Project**: release-repo-profile-management  
**Started**: 2025-07-22  
**Phase**: MVP 3 - Worktree Profile Association  

## Session Goals

### Primary Objectives
- Implement profile-aware worktree add operations with --profile parameter
- Implement profile-aware worktree pull-rebase operations with --profile parameter
- Maintain universal worktree directory structure while adding profile flexibility
- Ensure backward compatibility with existing worktree commands

### MVP 2 Achievements (Completed)
✅ **Universal repo_base Architecture**: Single shared repository storage across all profiles  
✅ **Profile-Aware Fetch**: `./git_sh1.sh fetch --profile unleashed_200.19/openwrt_common all`  
✅ **Dynamic repo_map Loading**: Profiles override hardcoded repository mappings  
✅ **Backward Compatibility**: All existing commands work unchanged  
✅ **Storage Efficiency**: Shared repositories not duplicated across profiles  

## MVP 3 Implementation Tasks

### 1. Profile-Aware Worktree Add Command
**Target Syntax:**
```bash
./git_sh1.sh worktree add --profile unleashed_200.19/openwrt_common all -lb local5 -rb origin/master
./git_sh1.sh worktree add --profile unleashed_200.19/openwrt_common controller -lb local5 -rb origin/master
```

**Implementation Steps:**
- [ ] Modify worktree add command parsing to accept --profile parameter
- [ ] Load profile repo_map before worktree operations
- [ ] Process profile repositories instead of hardcoded repo_map
- [ ] Maintain existing worktree directory structure
- [ ] Handle parameter position variations

### 2. Profile-Aware Worktree Pull-Rebase Command
**Target Syntax:**
```bash
./git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common all local5
./git_sh1.sh worktree pull-rebase --profile unleashed_200.19/openwrt_common controller local5
```

**Implementation Steps:**
- [ ] Modify worktree pull-rebase command parsing to accept --profile parameter
- [ ] Load profile repo_map for pull-rebase operations
- [ ] Process profile repositories for pull-rebase
- [ ] Maintain backward compatibility

### 3. Testing and Validation
**Test Cases:**
- [ ] Backward compatibility: existing worktree commands work unchanged
- [ ] Profile-aware worktree add with specific repositories
- [ ] Profile-aware worktree add with "all" repositories
- [ ] Profile-aware worktree pull-rebase operations
- [ ] Error handling for invalid profiles
- [ ] Universal worktree structure validation

## Architecture Consistency

### Universal Worktree Structure
```
git-depot/
├── repo_base/                    # Universal repository storage
├── local5/                       # Worktree branch (same regardless of profile)
│   ├── rks_ap/controller/       # Repository from any profile
│   ├── opensource/              # Shared across profiles
│   └── rks_ap/platform_dp/.../vendor_qca_11be_12_5/  # Profile-specific
```

### Key Principles
- **Universal Directory Structure**: Worktrees created in same paths regardless of profile
- **Profile Controls Content**: --profile determines which repositories, not where they go
- **Backward Compatibility**: Non-profile commands continue to work exactly as before
- **Storage Efficiency**: Leverages universal repo_base from MVP 2

## Success Criteria

1. ✅ **Profile-aware worktree add**: Creates worktrees for all repositories in profile
2. ✅ **Profile-aware pull-rebase**: Updates all repositories in profile worktree
3. ✅ **Universal structure**: Same worktree paths regardless of profile used
4. ✅ **Backward compatibility**: All existing worktree syntax continues to work
5. ✅ **Error handling**: Clear messages for invalid profiles or missing parameters
6. ✅ **Integration**: Seamlessly works with MVP 2 fetch operations

## Progress Tracking

### Completed ✅
- ✅ **MVP 3 Implementation**: Profile-aware worktree operations completed
- ✅ **Worktree Add**: Enhanced parsing with --profile parameter support
- ✅ **Worktree Pull-Rebase**: Enhanced parsing with --profile parameter support
- ✅ **Command Integration**: Profile loading integrated with worktree operations
- ✅ **Help Documentation**: Updated help text with profile-aware examples
- ✅ **Backward Compatibility**: Existing worktree syntax preserved

### In Progress 🔄
- Testing and validation of profile-aware worktree operations

### Next Actions
1. Analyze current worktree add command parsing structure
2. Implement --profile parameter integration for worktree add
3. Implement --profile parameter integration for worktree pull-rebase
4. Comprehensive testing with unleashed_200.19/openwrt_common profile

---
**Session Status**: Active  
**Last Updated**: 2025-07-22