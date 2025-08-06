#!/bin/bash

# =====================================================
# BlockAssist • One-Click Deploy (CLI-only)
# Author: @Dropxtor • https://github.com/Dropxtor
# Target: Ubuntu/Debian VPS (20.04, 22.04, 24.04)
# Usage: curl -sL https://git.io/dropxtor-block | bash
# =====================================================

# === CONFIG ===
REPO_URL="https://github.com/gensyn-ai/blockassist.git"
APP_DIR="$HOME/blockassist"
VENV_DIR="$APP_DIR/venv"
PORT=8501

# === COLORS ===
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# === CHECK ROOT? NON, on veut user normal
if [ "$(id -u)" -eq 0 ]; then
    error "This script should NOT be run as root. Use a regular user with sudo if needed."
    exit 1
fi

# === START ===
log "🚀 BlockAssist Auto-Installer by @Dropxtor"
log "Preparing Ubuntu/Debian VPS for headless deployment..."

# 1. Update & Upgrade
log "Updating package list..."
sudo apt update || { error "Failed to update apt"; exit 1; }

# 2. Install core tools
log "Installing prerequisites: git, python3, pip, venv, tmux..."
sudo apt install -y git python3 python3-pip python3-venv tmux || { error "Failed to install core tools"; exit 1; }

# 3. Clone repo
if [ -d "$APP_DIR" ]; then
    warn "Existing installation found at $APP_DIR. Backing up & cleaning..."
    mv "$APP_DIR" "$APP_DIR.bak.$(date +%s)" 2>/dev/null || rm -rf "$APP_DIR"
fi

log "Cloning BlockAssist from $REPO_URL..."
git clone "$REPO_URL" "$APP_DIR" || { error "Git clone failed"; exit 1; }

# 4. Setup Python environment
log "Creating isolated Python environment..."
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# 5. Detect GPU for PyTorch
if command -v nvidia-smi &> /dev/null && nvidia-smi | grep -q "GPU"; then
    log "🎮 NVIDIA GPU detected → Installing PyTorch with CUDA"
    pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
else
    warn "💻 No GPU detected → Using CPU-only PyTorch"
    pip install torch torchvision torchaudio
fi

# 6. Install app dependencies
log "Installing BlockAssist requirements..."
pip install -r "$APP_DIR/requirements.txt" 2>/dev/null || { error "Failed to install requirements"; exit 1; }

# 7. Kill old tmux session & start new
log "Starting BlockAssist in background (tmux session: 'blockassist')..."
tmux kill-session -t blockassist 2>/dev/null || true
tmux new-session -d -s blockassist "cd $APP_DIR && source $VENV_DIR/bin/activate && streamlit run app.py --server.port=$PORT --server.address=0.0.0.0"

# 8. Show success
PUBLIC_IP=$(curl -s ifconfig.me)
LOCAL_IP=$(hostname -I | awk '{print $1}')

# === FINAL MESSAGE ===
echo
echo "✅ SUCCESS: BlockAssist is now running!"
echo "🌐 Access the UI: http://$PUBLIC_IP:$PORT"
echo "🏠 Or locally: http://$LOCAL_IP:$PORT"
echo
echo "🔧 To monitor logs: tmux attach-session -t blockassist"
echo "⏸️  Detach: Ctrl+B, then D"
echo "❌ Stop: tmux kill-session -t blockassist"
echo
echo "📦 Script by @Dropxtor • https://github.com/Dropxtor/blockassist-deploy"
echo "💡 This session will keep running even after you close SSH."
log "Deployment completed."
