#!/bin/bash

# =====================================================
# BlockAssist • CPU-only Deploy (No GPU) • @Dropxtor
# For Ubuntu VPS with 16GB RAM
# Usage: curl -sL install.dropxtor.dev | bash
# =====================================================

REPO_URL="https://github.com/gensyn-ai/blockassist.git"
APP_DIR="$HOME/blockassist"
VENV_DIR="$APP_DIR/venv"
PORT=8501

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# === Vérif utilisateur (pas root) ===
if [ "$(id -u)" -eq 0 ]; then
    error "Do not run as root. Use: su - dropxtor"
    exit 1
fi

log "🚀 BlockAssist CPU Deploy by @Dropxtor"
log "Target: Ubuntu VPS (16GB RAM, no GPU)"

# === Mise à jour ===
sudo apt update

# === Install deps ===
sudo apt install -y git python3 python3-pip python3-venv tmux

# === Clone repo ===
if [ -d "$APP_DIR" ]; then
    mv "$APP_DIR" "$APP_DIR.bak.$(date +%s)" 2>/dev/null || rm -rf "$APP_DIR"
fi

log "Cloning BlockAssist..."
git clone "$REPO_URL" "$APP_DIR"

# === Virtual env ===
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# === INSTALL PYTORCH CPU-ONLY ===
warn "Installing PyTorch (CPU version)..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# === Install app deps ===
log "Installing requirements..."
pip install -r "$APP_DIR/requirements.txt"
if [ ! -f "$APP_DIR/requirements.txt" ]; then
    echo "⚠️  requirements.txt not found. Creating default..."
    cat > "$APP_DIR/requirements.txt" << 'EOF'
streamlit
numpy
pillow
torch
torchaudio
torchvision
einops
tqdm
plotly
matplotlib
pandas
scikit-learn
transformers
accelerate
fsspec
typing-extensions
jinja2
networkx
setuptools
EOF
fi
# === Start in tmux ===
tmux kill-session -t blockassist 2>/dev/null || true
tmux new-session -d -s blockassist "cd $APP_DIR && source $VENV_DIR/bin/activate && streamlit run app.py --server.port=$PORT --server.address=0.0.0.0"

# === Show IP ===
PUBLIC_IP=$(curl -s ifconfig.me)
LOCAL_IP=$(hostname -I | awk '{print $1}')

echo
echo "✅ BlockAssist is running (CPU mode)"
echo "🌐 Access UI: http://$PUBLIC_IP:$PORT"
echo "🏠 Local: http://$LOCAL_IP:$PORT"
echo "💡 Logs: tmux attach-session -t blockassist"
echo "⏸️  Detach: Ctrl+B, D"
echo "🔧 By @Dropxtor • https://github.com/Dropxtor/blockassist-deploy"
