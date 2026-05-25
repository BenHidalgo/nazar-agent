#!/bin/bash
# 🧿 Nazar Agent — Full Installer
# Sets up the main agent at ~/.nazzar/ and creates 'nazar' command
set -e

NAZZAR_HOME="${NAZZAR_HOME:-$HOME/.nazzar}"
NAZAR_REPO="${NAZAR_REPO:-$HOME/Nazar/repo}"
BOLD='\033[1m'
NC='\033[0m'
BLUE='\033[0;34m'

echo ""
echo -e "${BOLD}🧿 Nazar Agent — Installer${NC}"
echo -e "${BLUE}==========================${NC}"
echo ""

# ── Prerequisites ──────────────────────────────────────────────────────
command -v python3 >/dev/null 2>&1 || { echo "Requires Python 3.11+"; exit 1; }

if ! command -v uv &> /dev/null; then
    echo "📦 Installing uv (Python package manager)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# ── Clone if needed ────────────────────────────────────────────────────
if [ ! -d "$NAZAR_REPO" ]; then
    echo "📥 Cloning Nazar Agent..."
    mkdir -p "$(dirname "$NAZAR_REPO")"
    git clone https://github.com/BenHidalgo/hermes-agent.git "$NAZAR_REPO"
fi

# ── Install the package ────────────────────────────────────────────────
echo "🔧 Installing Nazar Agent..."
cd "$NAZAR_REPO"
uv venv .venv --python 3.11 2>/dev/null || true
source .venv/bin/activate
uv pip install -e ".[all]" 2>/dev/null || uv pip install -e "."

# ── Create ~/.nazzar/ throne directory ─────────────────────────────────
echo "🏰 Building throne at ~/.nazzar/..."
mkdir -p "$NAZZAR_HOME"/{skills,scripts,sessions,cron/output,skins,logs}
mkdir -p "$NAZZAR_HOME"/gateway

# Default config
if [ ! -f "$NAZZAR_HOME/config.yaml" ]; then
    cp "$NAZAR_REPO/nazar_cli/default_config.yaml" "$NAZZAR_HOME/config.yaml" 2>/dev/null || true
fi

# SOUL.md — identity
if [ ! -f "$NAZZAR_HOME/SOUL.md" ]; then
    cp "$NAZAR_REPO/SOUL.md" "$NAZZAR_HOME/SOUL.md" 2>/dev/null || true
fi

# .env placeholder
if [ ! -f "$NAZZAR_HOME/.env" ]; then
    cat > "$NAZZAR_HOME/.env" << 'EOF'
# 🧿 Nazar Agent — API Keys
# Add your keys here, one per line: KEY_NAME=value
# DEEPSEEK_API_KEY=sk-...
# OPENROUTER_API_KEY=sk-...
# TELEGRAM_BOT_TOKEN=...
EOF
fi

# ── Create nazar command ──────────────────────────────────────────────
echo "🔗 Linking 'nazar' command..."
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/nazar" << 'SCRIPT'
#!/bin/bash
export NAZAR_HOME="${NAZZAR_HOME:-$HOME/.nazzar}"
export PATH="$HOME/.local/bin:$PATH"

NAZAR_REPO="${NAZAR_REPO:-$HOME/Nazar/repo}"
if [ -f "$NAZAR_REPO/.venv/bin/activate" ]; then
    source "$NAZAR_REPO/.venv/bin/activate"
fi

cd "$NAZAR_REPO" 2>/dev/null || cd "$(dirname "$0")/../Nazar/repo"
exec python3 -m nazar_cli.main "$@"
SCRIPT
chmod +x "$HOME/.local/bin/nazar"

# ── Workspace system ─────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/nazar-workspace" << 'SCRIPT'
#!/bin/bash
# 🧿 Nazar Workspace — create a rental workspace
# Usage: nazar-workspace create <name>
#        nazar-workspace list
#        nazar-workspace run <name>

NAZZAR_HOME="${NAZZAR_HOME:-$HOME/.nazzar}"
WORKSPACES_DIR="$NAZZAR_HOME/workspaces"

case "${1:-help}" in
    create)
        if [ -z "$2" ]; then echo "Usage: $0 create <name>"; exit 1; fi
        mkdir -p "$WORKSPACES_DIR/$2"
        cat > "$WORKSPACES_DIR/$2/SOUL.md" << EOF
# Workspace: $2
# Customize this SOUL.md for your workspace agent.
# The workspace inherits the main ~/.nazzar/ config and keys
# but gets its own identity, context files, and working directory.

You are a Nazar Agent deployed in the "$2" workspace.
EOF
        echo "✅ Workspace '$2' created at $WORKSPACES_DIR/$2/"
        echo "   Run: nazar-workspace run $2"
        ;;
    list)
        echo "=== Workspaces ==="
        ls -1 "$WORKSPACES_DIR" 2>/dev/null || echo "(none)"
        ;;
    run)
        if [ -z "$2" ]; then echo "Usage: $0 run <name>"; exit 1; fi
        if [ ! -d "$WORKSPACES_DIR/$2" ]; then
            echo "Workspace '$2' not found. Create it first: $0 create $2"
            exit 1
        fi
        cd "$WORKSPACES_DIR/$2"
        export NAZAR_HOME="$NAZZAR_HOME"
        exec nazar
        ;;
    *)
        echo "🧿 Nazar Workspace Manager"
        echo ""
        echo "Usage:"
        echo "  $0 create <name>   Create a new workspace"
        echo "  $0 list            List workspaces"
        echo "  $0 run <name>      Run agent in workspace"
        ;;
esac
SCRIPT
chmod +x "$HOME/.local/bin/nazar-workspace"

# ── Done ───────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}✅ Nazar Agent installed!${NC}"
echo ""
echo -e "${BLUE}Throne:${NC}     ~/.nazzar/"
echo -e "${BLUE}Command:${NC}    nazar"
echo -e "${BLUE}Workspace:${NC}  nazar-workspace create <name>"
echo ""
echo "Quick start:"
echo "  1. Set your API key:"
echo "     echo 'DEEPSEEK_API_KEY=sk-...' >> ~/.nazzar/.env"
echo "  2. Run: nazar"
echo "  3. Or create a workspace: nazar-workspace create my-project && nazar-workspace run my-project"
echo ""
echo -e "${BOLD}🧿 The Eye watches over you.${NC}"
