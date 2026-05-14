#!/bin/sh
# gdrive-upload.sh FINAL — Upload, share, return clean link
# Usage: sh /app/workspace/gdrive-upload.sh <local_path> <drive_subfolder>

LOCAL_PATH="$1"
DRIVE_FOLDER="$2"
CONFIG="/app/workspace/rclone.conf"
FULL_LOCAL="/app/workspace/${LOCAL_PATH}"
DRIVE_ROOT="Enterprise_OS"

if [ -z "$LOCAL_PATH" ] || [ -z "$DRIVE_FOLDER" ]; then
  echo "ERROR: Usage: gdrive-upload.sh <local_path> <drive_subfolder>"
  exit 1
fi
if [ ! -f "$FULL_LOCAL" ]; then
  echo "ERROR: File not found: $FULL_LOCAL"
  exit 1
fi

FILENAME=$(basename "$FULL_LOCAL")
DRIVE_PATH="${DRIVE_ROOT}/${DRIVE_FOLDER}"
REMOTE_FILE="gdrive:${DRIVE_PATH}/${FILENAME}"

# Step 1: Upload
echo "Uploading $FILENAME..."
rclone copy "$FULL_LOCAL" "gdrive:${DRIVE_PATH}/" --config "$CONFIG"
if [ $? -ne 0 ]; then echo "ERROR: Upload failed"; exit 1; fi

# Step 2: Set "anyone with link can view" + get URL from rclone link
LINK=$(rclone link "$REMOTE_FILE" --config "$CONFIG" 2>/dev/null)

# Step 3: Fix URL format (convert open?id= to /file/d/ID/view)
if echo "$LINK" | grep -q "open?id="; then
  FILE_ID=$(echo "$LINK" | sed 's/.*open?id=//')
  LINK="https://drive.google.com/file/d/${FILE_ID}/view?usp=sharing"
fi

echo ""
echo "SUCCESS"
echo "file=$FILENAME"
echo "link=$LINK"
