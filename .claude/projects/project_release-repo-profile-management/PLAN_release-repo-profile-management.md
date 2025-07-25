# Development Plan: Release Repository Profile Management

## Project Overview
Implement a profile-based repository management system for git_sh1.sh script through 5 incremental MVP phases, each delivering stable and valuable functionality.

## Phase 1: Basic Profile Infrastructure (MVP 1)
**Duration**: 2-3 days  
**Goal**: Establish fundamental profile system without modifying existing commands

### Deliverables
- Profile directory structure creation logic
- Standalone profile creation command 
- Manifest parsing and repo_map generation
- Basic profile listing and viewing capabilities

### Implementation Tasks
1. **Create Profile Infrastructure Functions**
   - Add `init_profiles_dir()` function (similar to existing `init_features_dir()`)
   - Implement profile directory creation with proper permissions
   - Add profile path resolution functions

2. **Implement Manifest Parsing**
   - Create `parse_manifest_xml()` function using xmllint or sed/grep
   - Extract project name and path attributes from XML
   - Generate repo_map.txt in existing script format
   - Create metadata.json with profile information

3. **Add Profile Management Commands**
   - Implement `profile create <release>/<name>` command
   - Add `profile list` command with release grouping
   - Create `profile show <release>/<name>` command
   - Add basic error handling and validation

### Success Criteria
- Create profiles from manifest files with accurate repo_map generation
- List available profiles grouped by release
- Display profile details and repository mappings
- Handle invalid manifests with clear error messages

### Testing
- Test with provided manifest files (openwrt_common, openwrt_r370, buildroot)
- Verify generated repo_map matches expected format
- Test error handling with malformed XML files

## Phase 2: Profile-Aware Repository Operations (MVP 2)
**Duration**: 1-2 days  
**Goal**: Integrate profiles with repository fetching operations

### Deliverables
- Profile loading mechanism for existing commands
- `--profile` parameter support for fetch operations
- Dynamic repo_map loading based on profile selection
- Backward compatibility maintenance

### Implementation Tasks
1. **Create Profile Loading System**
   - Add `load_profile_repo_map()` function
   - Implement profile validation and error handling
   - Create profile caching for performance

2. **Enhance Fetch Command**
   - Modify `fetch_repos()` to accept profile parameter
   - Add `--profile` option to command parsing
   - Maintain existing functionality when no profile specified
   - Add profile validation before fetch operations

3. **Update Command Infrastructure**
   - Extend argument parsing to handle profile parameters
   - Add profile resolution logic
   - Implement fallback to default repo_map

### Success Criteria
- Fetch repositories using different profiles successfully
- Existing fetch functionality works unchanged without profile
- Clear error messages for non-existent profiles
- Performance impact minimal for profile loading

### Testing
- Test fetch operations with different profiles
- Verify backward compatibility with existing scripts
- Test error scenarios (missing profiles, invalid names)

## Phase 3: Worktree Profile Association (MVP 3) ✅ COMPLETED
**Duration**: 2-3 days ✅ Completed in 1 day  
**Goal**: Create intelligent association between worktrees and profiles ✅ ACHIEVED

### Deliverables ✅ COMPLETED
- ✅ Profile-aware worktree commands with `--profile` parameter
- ✅ Intelligent upstream detection from manifest.xml
- ✅ Enhanced `-repo` parameter syntax for clarity
- ✅ Per-repository upstream resolution for "all" operations
- ✅ Full backward compatibility maintained

### Implementation Tasks
1. **Implement Worktree Profile Storage**
   - Modify `add_worktree_for_repo()` to record profile information
   - Create `.git_sh1_worktree_info` file in worktrees
   - Store profile name and creation metadata

2. **Add Profile Detection System**
   - Create `detect_worktree_profile()` function
   - Implement automatic profile loading from worktree context
   - Add profile inheritance from parent directories

3. **Enhance Worktree Commands**
   - Add `--profile` parameter to worktree operations
   - Modify worktree creation to be profile-aware
   - Update worktree listing to show associated profiles

### Success Criteria
- Worktrees remember their associated profile automatically
- Profile detection works seamlessly in worktree operations
- Users can override auto-detected profiles explicitly
- Worktree status shows current profile information

### Testing
- Create worktrees with different profiles
- Test automatic profile detection in operations
- Verify profile override functionality
- Test mixed profile/non-profile worktree scenarios

## Phase 4: Feature Management Integration (MVP 4)
**Duration**: 2-3 days  
**Goal**: Extend profile awareness to feature management system

### Deliverables
- Profile-aware feature creation and management
- Repository validation for profile-specific operations
- Enhanced feature metadata with profile information
- Cross-profile feature capabilities

### Implementation Tasks
1. **Enhance Feature Commands**
   - Modify `feature_create()` to accept profile parameters
   - Add repository validation against profile repo_map
   - Update feature metadata to include profile information

2. **Implement Profile Validation**
   - Create repository existence checking for profiles
   - Add clear error messages for invalid repository requests
   - Implement profile-aware repository selection

3. **Update Feature Metadata**
   - Extend feature storage to include profile information
   - Modify feature listing to show profile associations
   - Add profile filtering for feature operations

### Success Criteria
- Create features spanning correct repositories for each profile
- Clear error messages for non-existent repositories in profiles
- Feature listings show profile associations
- Cross-profile feature operations work correctly

### Testing
- Create features with different profiles
- Test repository validation in feature operations
- Verify feature metadata includes profile information
- Test edge cases with mixed profile features

## Phase 5: Advanced Profile Management (MVP 5)
**Duration**: 3-4 days  
**Goal**: Add sophisticated profile management capabilities

### Deliverables
- Profile inheritance system for reducing duplication
- Migration tools for transitioning between releases
- Profile comparison utilities
- Advanced profile management features

### Implementation Tasks
1. **Implement Profile Inheritance**
   - Create inheritance configuration system (.profile_inheritance.json)
   - Add parent-child profile relationships
   - Implement modification overlay system (add, remove, update operations)
   - Add inheritance validation and cycle detection

2. **Create Migration Tools**
   - Implement `profile migrate` command
   - Add intelligent migration suggestions
   - Create profile difference analysis
   - Add migration validation and rollback

3. **Add Comparison Features**
   - Implement `profile diff` command
   - Create repository change detection
   - Add visual difference reporting
   - Include metadata comparison

4. **Advanced Management Features**
   - Add profile dependency tracking
   - Implement profile validation tools
   - Create profile backup and restore
   - Add profile cleanup utilities

### Success Criteria
- Profile inheritance reduces configuration duplication
- Migration tools help transition between releases efficiently
- Profile comparison shows meaningful differences
- Advanced features enhance development workflow

### Testing
- Test inheritance across multiple profile levels
- Verify migration accuracy and rollback capability
- Test comparison with complex profile differences
- Validate advanced features with real-world scenarios

## Implementation Guidelines

### Code Organization
- Add new functions after existing feature management section
- Follow existing naming conventions and code style
- Group related functions logically with clear comments
- Maintain consistent error handling patterns

### Testing Strategy
- Test each phase independently before proceeding
- Maintain existing functionality throughout development
- Create test manifests for edge cases
- Validate backward compatibility continuously

### Documentation Updates
- Update help text incrementally with each phase
- Document new commands and parameters
- Provide examples for common use cases
- Update completion scripts for new commands

### Error Handling Principles
- Provide clear, actionable error messages
- Fail gracefully with helpful suggestions
- Validate inputs early and thoroughly
- Maintain system state consistency

## Risk Mitigation

### Technical Risks
- **Profile corruption**: Implement atomic operations and validation
- **Performance impact**: Use caching and lazy loading
- **Integration issues**: Extensive testing with existing functionality

### Process Risks
- **User adoption**: Gradual rollout with training and documentation
- **Compatibility**: Maintain fallback mechanisms throughout
- **Complexity**: Keep each phase simple and focused

## Success Metrics

### Quantitative Metrics
- Profile creation time < 500ms for typical manifests
- Zero regression in existing command performance
- 100% backward compatibility maintained
- Error rate < 1% for valid profile operations

### Qualitative Metrics
- User feedback on workflow improvement
- Reduced configuration errors in development
- Faster context switching between releases
- Improved team collaboration efficiency

## Post-Implementation

### Maintenance Plan
- Regular validation of profile data integrity
- Performance monitoring and optimization
- User feedback collection and feature enhancement
- Documentation updates and training materials

### Future Enhancements
- Web interface for profile management
- Integration with CI/CD systems
- Advanced analytics and reporting
- Cloud-based profile sharing