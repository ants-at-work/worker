#!/bin/bash
# Setup GPU acceleration for ants-worker
# Downloads and builds JeanLucPons/Kangaroo
#
# Usage: ./setup-gpu.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Ants Worker GPU Setup ===${NC}"

# Check CUDA
if ! command -v nvcc &> /dev/null; then
    echo -e "${RED}CUDA not found. Install CUDA toolkit first:${NC}"
    echo "  Ubuntu: sudo apt install nvidia-cuda-toolkit"
    echo "  Or: https://developer.nvidia.com/cuda-downloads"
    exit 1
fi

CUDA_VERSION=$(nvcc --version | grep release | sed 's/.*release //' | sed 's/,.*//')
echo -e "CUDA: ${GREEN}$CUDA_VERSION${NC}"

# Check GPU
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    echo -e "GPU: ${GREEN}$GPU_NAME${NC}"
else
    echo -e "${YELLOW}nvidia-smi not found, continuing anyway...${NC}"
fi

# Clone Kangaroo
INSTALL_DIR="$HOME/.local/share/ants-worker"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [ -d "Kangaroo" ]; then
    echo "Kangaroo already exists, updating..."
    cd Kangaroo && git pull
else
    echo "Cloning Kangaroo..."
    git clone https://github.com/JeanLucPons/Kangaroo.git
    cd Kangaroo
fi

# Build with GPU support
echo -e "${YELLOW}Building Kangaroo (this may take a few minutes)...${NC}"
make clean 2>/dev/null || true
make gpu=1 -j$(nproc)

# Verify
if [ -f "./kangaroo" ]; then
    echo -e "${GREEN}Build successful!${NC}"

    # Install to path
    mkdir -p "$HOME/.local/bin"
    cp ./kangaroo "$HOME/.local/bin/"

    echo ""
    echo -e "${GREEN}Kangaroo installed to ~/.local/bin/kangaroo${NC}"
    echo ""

    # Test
    echo "Testing GPU..."
    ./kangaroo -v

    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo "Make sure ~/.local/bin is in your PATH:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    echo ""
    echo "Then run:"
    echo "  ants-worker info      # Should show 'kangaroo' backend"
    echo "  ants-worker benchmark # Test GPU performance"
else
    echo -e "${RED}Build failed. Check errors above.${NC}"
    exit 1
fi
