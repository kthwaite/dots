# Suggest a commit title using llm.
suggest-commit() {
    # Default model
    local model="o1-mini"

    # Print help text if -h or --help is passed
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: suggest_commit [-m MODEL]

This function inspects the current directory and:
  • Verifies that you are inside a Git repository.
  • Checks that there are staged changes (i.e. a non-empty git diff --cached).
  • Ensures that the required executables 'jq' and 'llm' are available.
  • Uses 'llm' to summarise the staged changes and suggest a commit title that follows a specific commit style.

Commit Style:
  The commit message should be formatted as:
      <hash> <type>(<domain>): <description>
  where:
      - <type> is typically one of: feat, fix, chore, docs, refactor, etc.
      - <domain> is determined by the subdirectory where the changes occurred (e.g., zsh, nvim, mise, ruff, wezterm, zellij, etc.).
  For example:
      feat(zsh): Add function to suggest commit titles using llm-cli
      feat(zsh): Add clone_subdir function for cloning specific subdirectories
      feat(zsh): Check for mise in vvv
      feat(git): Add pull, branch-sort defaults

Options:
  -m MODEL    Use a custom model instead of the default ("o1-mini").
  -h, --help  Show this help message and exit.
EOF
        return 0
    fi

    # Process command-line arguments (currently only support -m MODEL)
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -m)
                if [[ -n "$2" ]]; then
                    model="$2"
                    shift 2
                else
                    echo "Error: -m requires an argument." >&2
                    return 1
                fi
                ;;
            *)
                echo "Error: Unknown argument: $1" >&2
                return 1
                ;;
        esac
    done

    # Check if inside a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Error: This is not a Git repository." >&2
        return 1
    fi

    # Check if there are any staged changes
    if git diff --cached --quiet; then
        echo "Error: No staged changes detected. Stage some changes first (e.g., using 'git add')." >&2
        return 1
    fi

    # Check that jq is installed
    if ! command -v jq > /dev/null 2>&1; then
        echo "Error: 'jq' is not installed. Please install it and try again." >&2
        return 1
    fi

    # Check that llm is installed
    if ! command -v llm > /dev/null 2>&1; then
        echo "Error: 'llm' is not installed. Please install it and try again." >&2
        return 1
    fi

    # Capture the staged diff
    local staged_diff
    staged_diff=$(git diff --cached)

    # Build the prompt text for the LLM with updated commit style instructions
    local prompt
    prompt="Summarise the following git diff. Based on your summary, suggest a short title for the git commit message that adheres to this commit style:
<hash> <type>(<domain>): <description>
where <type> is one of (feat, fix, chore, docs, refactor, etc.) and <domain> is determined by the subdirectory where the changes occurred (for example, zsh, nvim, mise, ruff, wezterm, zellij). For example:
  feat(zsh): Add function to suggest commit titles using llm-cli
  feat(zsh): Add clone_subdir function for cloning specific subdirectories
  feat(zsh): Check for mise in vvv
  feat(git): Add pull, branch-sort defaults
Your answer should be in valid JSON (without backticks), using the following schema: {\"summary\": string, \"title\": string}.
Diff to summarise: $staged_diff"

    # Run the llm command with the chosen model and parse the output with jq
    local llm_output
    if ! llm_output=$(llm -m "$model" "$prompt" 2>/dev/null); then
        echo "Error: Failed to execute llm." >&2
        return 1
    fi

    local title
    if ! title=$(echo "$llm_output" | jq -r '.title' 2>/dev/null); then
        echo "Error: Failed to parse llm output." >&2
        echo "llm output:" >&2
        echo "$llm_output" >&2
        return 1
    fi

    # Check that a title was indeed extracted
    if [[ -z "$title" || "$title" == "null" ]]; then
        echo "Error: No valid title found in llm output." >&2
        echo "llm output:" >&2
        echo "$llm_output" >&2
        return 1
    fi

    # Output the suggested commit title
    echo "$title"
}


files-to-tokens() {
  # Colors
  local color_reset="$(tput sgr0)"
  local color_red="$(tput setaf 1)"
  local color_green="$(tput setaf 2)"

  local window=""          # Will hold the window value if provided
  local args=()            # Accumulate other arguments to pass to files-to-prompt

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--window)
        window="$2"
        shift 2
        ;;
      *)
        # All other args accumulate
        args+=("$1")
        shift
        ;;
    esac
  done

  # Run files-to-prompt with the gathered arguments, and pipe to ttok
  local token_count
  token_count="$(files-to-prompt "${args[@]}" | ttok)"

  # If we didn't get a numeric value for some reason, just echo and return
  if ! [[ "$token_count" =~ ^[0-9]+$ ]]; then
    echo "Error: ttok did not output an integer." >&2
    echo "$token_count"
    return 1
  fi

  # If a window is specified, compare and colorize
  if [[ -n "$window" ]]; then
    # Avoid division by zero
    if [[ "$window" -eq 0 ]]; then
      echo "Error: --window cannot be zero." >&2
      return 1
    fi

    # Compute percentage
    local percentage
    percentage=$(awk -v tc="$token_count" -v w="$window" \
      'BEGIN { printf "%.2f", (tc / w) * 100 }')

    if (( token_count < window )); then
      # Green if within window
      echo -e "${color_green}${token_count}/${window} (${percentage}%)${color_reset}"
    else
      # Red if over/at window
      echo -e "${color_red}${token_count}/${window} (${percentage}%)${color_reset}"
    fi
  else
    # No window - just print the token count
    echo "$token_count"
  fi
}
