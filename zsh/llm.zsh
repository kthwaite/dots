# Suggest a commit title using llm.
suggest_commit() {
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
      af3f751 feat(zsh): Add function to suggest commit titles using llm-cli
      dc919dc feat(zsh): Add clone_subdir function for cloning specific subdirectories
      d258687 feat(zsh): Check for mise in vvv
      f966d16 feat(git): Add pull, branch-sort defaults

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
  af3f751 feat(zsh): Add function to suggest commit titles using llm-cli
  dc919dc feat(zsh): Add clone_subdir function for cloning specific subdirectories
  d258687 feat(zsh): Check for mise in vvv
  f966d16 feat(git): Add pull, branch-sort defaults
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
