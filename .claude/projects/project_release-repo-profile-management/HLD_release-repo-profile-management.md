# High Level Design: Release Repository Profile Management

## Overview

This project enhances the existing git_sh1.sh script with a profile-based repository management system that supports multiple software releases and repository configurations. The system transforms the script from using hardcoded repository mappings to a flexible, configuration-driven approach.

## Core Architecture

### Profile Storage Layer
- **Location**: `.git_sh1_profiles/` at git-depot root level
- **Structure**: Hierarchical organization by release and configuration type
- **Format**: `{release}/{config_type}/` (e.g., `unleashed_200.19/openwrt_common/`)

### Profile Data Model
Each profile contains three key files:
1. **manifest.xml** - Source of truth (user-provided, unchanged)
2. **repo_map.txt** - Generated repository mappings (script format)
3. **metadata.json** - Profile metadata and context

### Integration Points
- **Command Enhancement**: Existing commands gain optional `--profile` parameter
- **Worktree Association**: Worktrees remember their associated profile
- **Feature Management**: Features work with profile-specific repository sets
- **Backward Compatibility**: Falls back to default/hardcoded repo_map when no profile specified

## Key Components

### Profile Loading Mechanism
- Dynamic repo_map loading based on profile selection
- Automatic profile detection from worktree context
- Command-line profile specification support
- Default profile fallback for compatibility

### Manifest Processing Engine
- XML parsing to extract project information
- Automatic repo_map.txt generation
- Metadata extraction and analysis
- Validation and error handling

### Worktree Profile Association
- Profile information stored within worktrees
- Automatic profile detection for operations
- Override capability with explicit profile specification
- Cross-profile feature branch management

## Technical Design Decisions

### Error Handling Strategy
- Graceful handling of missing profiles
- Clear error messages with resolution guidance
- Validation of manifest files and profile data
- Fallback mechanisms for robustness

### Performance Considerations
- Caching of parsed profile data within execution
- Minimal file I/O through smart loading
- Efficient profile detection mechanisms
- Lazy loading of profile information

### Data Flow Architecture
1. **Profile Creation**: manifest.xml → XML parsing → repo_map.txt + metadata.json
2. **Command Execution**: Profile selection → repo_map loading → existing command logic
3. **Worktree Operations**: Profile association storage → automatic detection → context-aware operations

## System Benefits

### Flexibility
- Support for multiple release configurations
- Easy addition of new AP types and variants
- Dynamic repository set management
- Cross-configuration development workflows

### Maintainability
- Single source of truth per configuration (manifest.xml)
- Automated generation reduces manual errors
- Clear separation of concerns
- Extensible architecture for future enhancements

### Developer Experience
- Intelligent profile detection
- Consistent command interface
- Clear error messages and guidance
- Seamless integration with existing workflows

## Integration Strategy

The design maintains the existing git_sh1.sh architecture while adding a configuration layer. Core script logic remains unchanged, with the profile system providing dynamic repository mappings to existing functions. This approach ensures stability while enabling powerful new capabilities.