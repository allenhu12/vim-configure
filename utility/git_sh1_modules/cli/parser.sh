#!/bin/bash

# cli/parser.sh - Advanced command line argument parsing for git_sh1_modules
# Depends on: core/config.sh (for colors and constants)

# Global parsing state
PARSED_COMMAND=""
PARSED_SUBCOMMAND=""
PARSED_OPTIONS=()
PARSED_ARGUMENTS=()
PARSED_FLAGS=()

# Reset parser state
reset_parser_state() {
    PARSED_COMMAND=""
    PARSED_SUBCOMMAND=""
    PARSED_OPTIONS=()
    PARSED_ARGUMENTS=()
    PARSED_FLAGS=()
}

# Parse command line arguments with enhanced validation
parse_arguments() {
    local args=("$@")
    local i=0
    
    reset_parser_state
    
    # Handle empty arguments
    if [[ ${#args[@]} -eq 0 ]]; then
        return 1
    fi
    
    # Parse main command
    PARSED_COMMAND="${args[0]}"
    i=1
    
    # Handle global options first
    case "$PARSED_COMMAND" in
        -h|--help)
            PARSED_COMMAND="help"
            if [[ $# -gt 1 ]]; then
                PARSED_ARGUMENTS=("${args[@]:1}")
            fi
            return 0
            ;;
        --version)
            PARSED_COMMAND="version"
            return 0
            ;;
        --install-completion)
            PARSED_COMMAND="install_completion"
            return 0
            ;;
        --clear-cache)
            PARSED_COMMAND="clear_cache"
            return 0
            ;;
    esac
    
    # Parse subcommand and options
    while [[ $i -lt ${#args[@]} ]]; do
        local arg="${args[$i]}"
        
        case "$arg" in
            --profile)
                if [[ $((i+1)) -lt ${#args[@]} ]]; then
                    PARSED_OPTIONS+=("--profile" "${args[$((i+1))]}")
                    i=$((i+2))
                else
                    echo -e "${RED}Error: --profile requires a value${NC}" >&2
                    return 1
                fi
                ;;
            -repo)
                if [[ $((i+1)) -lt ${#args[@]} ]]; then
                    PARSED_OPTIONS+=("-repo" "${args[$((i+1))]}")
                    i=$((i+2))
                else
                    echo -e "${RED}Error: -repo requires a value${NC}" >&2
                    return 1
                fi
                ;;
            -lb)
                if [[ $((i+1)) -lt ${#args[@]} ]]; then
                    PARSED_OPTIONS+=("-lb" "${args[$((i+1))]}")
                    i=$((i+2))
                else
                    echo -e "${RED}Error: -lb requires a value${NC}" >&2
                    return 1
                fi
                ;;
            -rb)
                if [[ $((i+1)) -lt ${#args[@]} ]]; then
                    PARSED_OPTIONS+=("-rb" "${args[$((i+1))]}")
                    i=$((i+2))
                else
                    echo -e "${RED}Error: -rb requires a value${NC}" >&2
                    return 1
                fi
                ;;
            --dry-run)
                PARSED_FLAGS+=("--dry-run")
                i=$((i+1))
                ;;
            --verbose)
                PARSED_FLAGS+=("--verbose")
                i=$((i+1))
                ;;
            --*)
                echo -e "${RED}Error: Unknown option '$arg'${NC}" >&2
                return 1
                ;;
            -*)
                echo -e "${RED}Error: Unknown flag '$arg'${NC}" >&2
                return 1
                ;;
            *)
                # First non-option argument is subcommand
                if [[ -z "$PARSED_SUBCOMMAND" && $i -eq 1 ]]; then
                    PARSED_SUBCOMMAND="$arg"
                else
                    PARSED_ARGUMENTS+=("$arg")
                fi
                i=$((i+1))
                ;;
        esac
    done
    
    return 0
}

# Get parsed option value
get_parsed_option() {
    local option_name="$1"
    local i
    
    for ((i=0; i<${#PARSED_OPTIONS[@]}; i+=2)); do
        if [[ "${PARSED_OPTIONS[$i]}" == "$option_name" ]]; then
            echo "${PARSED_OPTIONS[$((i+1))]}"
            return 0
        fi
    done
    
    return 1
}

# Check if flag is present
has_parsed_flag() {
    local flag_name="$1"
    local flag
    
    for flag in "${PARSED_FLAGS[@]}"; do
        if [[ "$flag" == "$flag_name" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Validate command structure
validate_command_structure() {
    local command="$PARSED_COMMAND"
    local subcommand="$PARSED_SUBCOMMAND"
    
    case "$command" in
        worktree)
            case "$subcommand" in
                add)
                    # Require -lb and -rb options
                    if ! get_parsed_option "-lb" >/dev/null || ! get_parsed_option "-rb" >/dev/null; then
                        echo -e "${RED}Error: worktree add requires -lb and -rb options${NC}" >&2
                        return 1
                    fi
                    ;;
                pull-rebase)
                    # Require -repo and -lb options
                    if ! get_parsed_option "-repo" >/dev/null || ! get_parsed_option "-lb" >/dev/null; then
                        echo -e "${RED}Error: worktree pull-rebase requires -repo and -lb options${NC}" >&2
                        return 1
                    fi
                    ;;
                "")
                    echo -e "${RED}Error: worktree command requires a subcommand${NC}" >&2
                    return 1
                    ;;
            esac
            ;;
        feature|profile)
            if [[ -z "$subcommand" ]]; then
                echo -e "${RED}Error: $command requires a subcommand${NC}" >&2
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Show parsing results (for debugging)
show_parse_results() {
    echo "Command: $PARSED_COMMAND"
    echo "Subcommand: $PARSED_SUBCOMMAND"
    echo "Options: ${PARSED_OPTIONS[*]}"
    echo "Arguments: ${PARSED_ARGUMENTS[*]}"
    echo "Flags: ${PARSED_FLAGS[*]}"
}

# Advanced command parsing with validation
parse_and_validate() {
    if ! parse_arguments "$@"; then
        return 1
    fi
    
    if ! validate_command_structure; then
        return 1
    fi
    
    return 0
}