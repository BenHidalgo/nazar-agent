#!/bin/bash
# 🧿 Nazar Agent — quick install
set -e

echo "🧿 Nazar Agent — quick install"
echo "=============================="

# Check for uv
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Clone if not already present
NAZAR_DIR="${NAZAR_DIR:-$HOME/Nazar}"
if [ ! -d "$NAZAR_DIR/repo" ]; then
    mkdir -p "$NAZAR_DIR"
    echo "Cloning Nazar Agent..."
    git clone https://github.com/BenHidalgo/nazar-agent.git "$NAZAR_DIR/repo"
fi

cd "$NAZAR_DIR/repo"

# Create venv and install
echo "Installing dependencies..."
uv venv .venv --python 3.11 2>/dev/null || true
source .venv/bin/activate
uv pip install -e ".[all]" 2>/dev/null || uv pip install -e .

# Symlink
mkdir -p "$HOME/.local/bin"
ln -sf "$(pwd)/.venv/bin/nazar" "$HOME/.local/bin/nazar" 2>/dev/null || true

echo ""
echo "✅ Nazar Agent installed!"
echo ""
echo "Next steps:"
echo "  1. Add ~/.local/bin to your PATH"
echo "  2. Set your API key: export DEEPSEEK_API_KEY=\"sk-...\""
echo "  3. Run: nazar"
echo ""
echo "🧿 The Eye watches over you."
