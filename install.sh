#!/bin/bash
# Ants Worker - One-line installer
#
# Usage: curl -sSL https://ants.work/install.sh | bash
#
# Or with GPU: curl -sSL https://ants.work/install.sh | bash -s -- --gpu

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Installing Ants Worker...${NC}"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 not found. Please install Python 3.10+${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "Python: $PYTHON_VERSION"

# Install
if [[ "$1" == "--gpu" ]]; then
    echo -e "${YELLOW}Installing with GPU support...${NC}"
    pip3 install --user ants-worker[gpu]
else
    pip3 install --user ants-worker
fi

# Verify
if command -v ants-worker &> /dev/null; then
    echo -e "${GREEN}Installed successfully!${NC}"
    ants-worker --version
else
    # Add to PATH hint
    echo -e "${YELLOW}Installed. You may need to add ~/.local/bin to PATH:${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
fi

echo ""
echo -e "${GREEN}Quick start:${NC}"
echo "  ants-worker info        # Check system"
echo "  ants-worker benchmark   # Test performance"
echo "  ants-worker standalone  # Run without Agentverse"
echo "  ants-worker start       # Connect to Queen"
