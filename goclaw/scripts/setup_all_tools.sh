#!/bin/sh
# GoClaw Complete Tools Setup — run after container recreate
# Usage: docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_all_tools.sh
# Then:  docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_credentials.sh

set -e

echo "[1/3] Installing Python office packages..."
pip install \
  python-docx==1.2.0 \
  openpyxl==3.1.5 \
  python-pptx==1.0.2 \
  reportlab==4.4.10 \
  pypdf==6.10.2 \
  pdfplumber==0.11.9 \
  Pillow lxml \
  --break-system-packages -q

echo "[2/3] Installing system tools..."
apk add --no-cache rclone pandoc-cli

echo "[3/3] Installing Claude CLI..."
npm install -g @anthropic-ai/claude-code

echo ""
echo "=== Verify ==="
rclone version | head -1
pandoc --version | head -1
claude --version
python3 -c "import docx, openpyxl, pptx; print('Python packages OK')"
echo "=== Done ==="
