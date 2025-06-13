#!/bin/bash
# Installation script for git_sh1.sh bash completion
# 
# This script sets up tab completion for git_sh1.sh
# Run this script on your remote server after copying the completion files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETION_FILE="$SCRIPT_DIR/git_sh1_completion.bash"

# Installation locations (in order of preference)
INSTALL_LOCATIONS=(
    "$HOME/.local/share/bash-completion/completions/git_sh1"
    "$HOME/.bash_completion.d/git_sh1_completion.bash"
    "/etc/bash_completion.d/git_sh1"
    "$HOME/.bashrc.d/git_sh1_completion.bash"
)

# Zsh-specific locations
ZSH_INSTALL_LOCATIONS=(
    "$HOME/.local/share/zsh/site-functions/_git_sh1"
    "$HOME/.zsh/completions/_git_sh1"
    "$HOME/.oh-my-zsh/custom/plugins/git_sh1/_git_sh1"
)

# Detect current shell
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        # Fallback: check $SHELL variable
        case "$SHELL" in
            */zsh) echo "zsh" ;;
            */bash) echo "bash" ;;
            *) echo "unknown" ;;
        esac
    fi
}

# Function to display usage
show_usage() {
    cat << 'EOF'
Git SH1 Completion Installer

USAGE:
    ./install_completion.sh [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -u, --uninstall     Uninstall completion
    -f, --force         Force installation (overwrite existing)
    -l, --local         Install for current user only (default)
    -g, --global        Install system-wide (requires sudo)
    -m, --manual        Show manual installation instructions
    --test              Test completion without installing

EXAMPLES:
    ./install_completion.sh                    # Install for current user
    ./install_completion.sh --global           # Install system-wide
    ./install_completion.sh --uninstall        # Remove completion
    ./install_completion.sh --test             # Test completion

EOF
}

# Function to check if completion file exists
check_completion_file() {
    if [[ ! -f "$COMPLETION_FILE" ]]; then
        echo -e "${RED}Error: Completion file not found: $COMPLETION_FILE${NC}"
        echo -e "${YELLOW}Please ensure git_sh1_completion.bash is in the same directory as this script${NC}"
        exit 1
    fi
}

# Function to test completion
test_completion() {
    echo -e "${CYAN}Testing completion functionality...${NC}"
    
    # Source the completion file temporarily
    if source "$COMPLETION_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ Completion file loaded successfully${NC}"
        
        # Test if completion function exists
        if declare -F _git_sh1_completion >/dev/null; then
            echo -e "${GREEN}✓ Completion function registered${NC}"
        else
            echo -e "${RED}✗ Completion function not found${NC}"
            return 1
        fi
        
        # Test repository extraction
        local repos=$(_git_sh1_get_repositories 2>/dev/null)
        if [[ -n "$repos" ]]; then
            echo -e "${GREEN}✓ Repository names extracted: $(echo "$repos" | wc -w) repositories found${NC}"
            echo -e "${CYAN}  Sample repositories: $(echo "$repos" | head -n 5 | tr '\n' ' ')${NC}"
        else
            echo -e "${YELLOW}⚠ No repositories found (this is normal if git_sh1.sh is not in the expected location)${NC}"
        fi
        
        echo -e "${GREEN}✓ Completion test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to load completion file${NC}"
        return 1
    fi
}

# Function to find best installation location
find_install_location() {
    local global="$1"
    
    if [[ "$global" == "true" ]]; then
        # Global installation
        if [[ -d "/etc/bash_completion.d" ]]; then
            echo "/etc/bash_completion.d/git_sh1"
        elif [[ -d "/usr/share/bash-completion/completions" ]]; then
            echo "/usr/share/bash-completion/completions/git_sh1"
        else
            echo ""
        fi
    else
        # Local installation
        for location in "${INSTALL_LOCATIONS[@]}"; do
            local dir=$(dirname "$location")
            if [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null; then
                echo "$location"
                return 0
            fi
        done
        echo ""
    fi
}

# Function to install completion
install_completion() {
    local global="$1"
    local force="$2"
    local shell=$(detect_shell)
    
    echo -e "${CYAN}Installing git_sh1.sh completion for $shell...${NC}"
    
    local install_location=$(find_install_location "$global")
    if [[ -z "$install_location" ]]; then
        echo -e "${RED}Error: Could not find suitable installation location${NC}"
        if [[ "$global" == "true" ]]; then
            echo -e "${YELLOW}Try installing without --global, or run with sudo${NC}"
        else
            echo -e "${YELLOW}Try manual installation instead${NC}"
        fi
        return 1
    fi
    
    echo -e "${CYAN}Installation location: $install_location${NC}"
    
    # Check if already installed
    if [[ -f "$install_location" ]] && [[ "$force" != "true" ]]; then
        echo -e "${YELLOW}Completion already installed at: $install_location${NC}"
        echo -e "${YELLOW}Use --force to overwrite, or --uninstall to remove${NC}"
        return 1
    fi
    
    # Create directory if needed
    local install_dir=$(dirname "$install_location")
    if ! mkdir -p "$install_dir" 2>/dev/null; then
        if [[ "$global" == "true" ]]; then
            echo -e "${RED}Error: Permission denied. Try running with sudo${NC}"
        else
            echo -e "${RED}Error: Could not create directory: $install_dir${NC}"
        fi
        return 1
    fi
    
    # Copy completion file
    if cp "$COMPLETION_FILE" "$install_location"; then
        echo -e "${GREEN}✓ Completion installed to: $install_location${NC}"
        
        # Make executable
        chmod +x "$install_location" 2>/dev/null || true
        
        # Add to .bashrc if local installation and not already there
        if [[ "$global" != "true" ]] && [[ ! -d "/etc/bash_completion.d" ]]; then
            local bashrc="$HOME/.bashrc"
            local source_line="source \"$install_location\""
            
            if [[ -f "$bashrc" ]] && ! grep -q "$install_location" "$bashrc"; then
                echo "" >> "$bashrc"
                echo "# Git SH1 completion" >> "$bashrc"
                echo "$source_line" >> "$bashrc"
                echo -e "${GREEN}✓ Added source line to $bashrc${NC}"
            fi
        fi
        
        echo -e "${GREEN}✓ Installation completed successfully${NC}"
        
        # Provide shell-specific instructions
        case "$shell" in
            zsh)
                echo -e "${YELLOW}Note: For zsh, run 'source ~/.zshrc' or restart your shell${NC}"
                echo -e "${CYAN}Test with: ./git_sh1.sh [TAB]${NC}"
                ;;
            bash)
                echo -e "${YELLOW}Note: Run 'source ~/.bashrc' or restart your shell${NC}"
                echo -e "${CYAN}Test with: ./git_sh1.sh [TAB]${NC}"
                ;;
            *)
                echo -e "${YELLOW}Note: You may need to restart your shell or source the completion file${NC}"
                ;;
        esac
        return 0
    else
        echo -e "${RED}Error: Failed to copy completion file${NC}"
        return 1
    fi
}

# Setup shell configuration
setup_shell_config() {
    local install_location="$1"
    local shell="$2"
    local config_file
    local source_line
    
    case "$shell" in
        zsh)
            config_file="$HOME/.zshrc"
            # For zsh, we need both bashcompinit and source
            source_line="# Git SH1 completion for zsh
autoload -U +X bashcompinit && bashcompinit
source \"$install_location\""
            ;;
        bash)
            config_file="$HOME/.bashrc"
            source_line="# Git SH1 completion
source \"$install_location\""
            ;;
        *)
            echo -e "${YELLOW}Unknown shell: $shell. Manual setup required.${NC}"
            return 1
            ;;
    esac
    
    if [[ -f "$config_file" ]] && ! grep -q "$install_location" "$config_file"; then
        echo "" >> "$config_file"
        echo -e "$source_line" >> "$config_file"
        echo -e "${GREEN}✓ Added source line to $config_file${NC}"
    elif grep -q "$install_location" "$config_file"; then
        echo -e "${YELLOW}Completion already configured in $config_file${NC}"
    fi
}

# Function to uninstall completion
uninstall_completion() {
    local global="$1"
    local shell=$(detect_shell)
    
    echo -e "${CYAN}Uninstalling git_sh1.sh completion for $shell...${NC}"
    
    local removed=false
    
    # Try all possible installation locations
    local locations_to_check=(
        "$HOME/.local/share/bash-completion/completions/git_sh1"
        "$HOME/.bash_completion.d/git_sh1_completion.bash"
        "/etc/bash_completion.d/git_sh1"
        "/usr/share/bash-completion/completions/git_sh1"
        "$HOME/.bashrc.d/git_sh1_completion.bash"
    )
    
    for location in "${locations_to_check[@]}"; do
        if [[ -f "$location" ]]; then
            if rm "$location" 2>/dev/null; then
                echo -e "${GREEN}✓ Removed: $location${NC}"
                removed=true
            else
                echo -e "${RED}✗ Failed to remove: $location (permission denied)${NC}"
            fi
        fi
    done
    
    # Remove from shell configuration files
    local config_files=("$HOME/.bashrc" "$HOME/.zshrc")
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            local temp_file=$(mktemp)
            if grep -v "git_sh1_completion\|bashcompinit" "$config_file" > "$temp_file" && mv "$temp_file" "$config_file"; then
                echo -e "${GREEN}✓ Removed references from $config_file${NC}"
                removed=true
            fi
        fi
    done
    
    # Clear completion cache
    rm -rf "$HOME/.cache/git_sh1" 2>/dev/null && echo -e "${GREEN}✓ Cleared completion cache${NC}"
    
    if [[ "$removed" == "true" ]]; then
        echo -e "${GREEN}✓ Uninstallation completed${NC}"
        echo -e "${YELLOW}Note: You may need to restart your shell${NC}"
    else
        echo -e "${YELLOW}No completion installation found${NC}"
    fi
}

# Function to show manual installation instructions
show_manual_instructions() {
    cat << EOF
${CYAN}Manual Installation Instructions:${NC}

${YELLOW}1. Copy the completion file to your server:${NC}
   scp git_sh1_completion.bash user@server:/path/to/utility/

${YELLOW}2. Choose one of the following methods:${NC}

${GREEN}Method A: Source in .bashrc (recommended)${NC}
   echo "source /path/to/utility/git_sh1_completion.bash" >> ~/.bashrc
   source ~/.bashrc

${GREEN}Method B: Copy to bash completion directory${NC}
   # For user-specific completion:
   mkdir -p ~/.local/share/bash-completion/completions
   cp git_sh1_completion.bash ~/.local/share/bash-completion/completions/git_sh1
   
   # For system-wide completion (requires sudo):
   sudo cp git_sh1_completion.bash /etc/bash_completion.d/git_sh1

${GREEN}Method C: Source directly (temporary)${NC}
   source ./git_sh1_completion.bash

${YELLOW}3. Test the completion:${NC}
   ./git_sh1.sh [TAB]
   ./git_sh1.sh fetch [TAB]
   ./git_sh1.sh feature create [TAB]

${YELLOW}4. Enable debug mode (optional):${NC}
   export GIT_SH1_DEBUG=1
   ./git_sh1.sh [TAB]

${YELLOW}5. Clear completion cache if needed:${NC}
   ./git_sh1.sh --clear-cache

EOF
}

# Main function
main() {
    local global=false
    local force=false
    local uninstall=false
    local test_only=false
    local manual=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -g|--global)
                global=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -u|--uninstall)
                uninstall=true
                shift
                ;;
            -l|--local)
                global=false
                shift
                ;;
            -m|--manual)
                manual=true
                shift
                ;;
            --test)
                test_only=true
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo -e "${CYAN}Git SH1 Completion Installer${NC}"
    echo -e "${CYAN}=============================${NC}"
    
    # Show manual instructions
    if [[ "$manual" == "true" ]]; then
        show_manual_instructions
        exit 0
    fi
    
    # Check completion file exists
    check_completion_file
    
    # Test completion
    if [[ "$test_only" == "true" ]]; then
        test_completion
        exit $?
    fi
    
    # Uninstall
    if [[ "$uninstall" == "true" ]]; then
        uninstall_completion "$global"
        exit $?
    fi
    
    # Test before installation
    echo -e "${CYAN}Running pre-installation tests...${NC}"
    if ! test_completion; then
        echo -e "${RED}Pre-installation test failed. Installation aborted.${NC}"
        exit 1
    fi
    
    # Install
    if install_completion "$global" "$force"; then
        echo ""
        echo -e "${GREEN}🎉 Git SH1 completion installed successfully!${NC}"
        echo ""
        echo -e "${CYAN}Try it out:${NC}"
        echo -e "  ./git_sh1.sh [TAB]${NC}"
        echo -e "  ./git_sh1.sh fetch [TAB]${NC}"
        echo -e "  ./git_sh1.sh feature create [TAB]${NC}"
        echo ""
        echo -e "${YELLOW}Note: You may need to restart your shell or run:${NC}"
        echo -e "  source ~/.bashrc${NC}"
        echo ""
    else
        echo -e "${RED}Installation failed${NC}"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"