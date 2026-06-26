#!/bin/bash
#
# Bootstrap installer for the Staubli MED 2025 demo.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/tpoignonec/demo_staubli_med_2025/main/install.bash | bash
#
set -euo pipefail

REPO_URL="https://github.com/tpoignonec/demo_staubli_med_2025.git"
BRANCH="${DEMO_BRANCH:-main}"
CLONE_DIR="/tmp/demo_staubli_med_2025"

# Check for git
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git first." >&2
    exit 1
fi

# Fresh clone in /tmp
if [ -d "$CLONE_DIR" ]; then
    echo "Removing previous clone at $CLONE_DIR..."
    rm -rf "$CLONE_DIR"
fi

echo "Cloning $REPO_URL (branch: $BRANCH) into $CLONE_DIR..."
git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$CLONE_DIR"

# Run the application installer
echo "Running app installer..."
bash "$CLONE_DIR/app/install.sh"

echo "Done."
