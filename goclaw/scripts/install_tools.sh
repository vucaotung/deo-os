#!/bin/sh
# Install all required tools in GoClaw container
# Run: docker exec -u root goclaw-goclaw-1 sh /app/workspace/scripts/install_tools.sh

set -e
echo "=== Installing rclone ==="
apk add --no-cache rclone

echo "=== Installing Python office packages ==="
pip install python-docx openpyxl python-pptx reportlab pypdf pdfplumber Pillow lxml \
  --break-system-packages -q

echo "=== Installing pandoc ==="
apk add --no-cache pandoc-cli

echo "=== Testing rclone → Google Drive ==="
rclone lsd gdrive: --config /app/workspace/rclone.conf | head -5 || echo "WARNING: Drive not accessible, check token"

echo "=== Creating Drive root folder ==="
rclone mkdir "gdrive:/Dẹo Enterprise OS" --config /app/workspace/rclone.conf || true

echo ""
echo "=== Verify ==="
rclone version | head -1
python3 -c "import docx, openpyxl, pptx; print('Python packages OK')"
echo "=== Done ==="
