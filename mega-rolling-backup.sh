#!/bin/bash
# backup files from mega

# ================== CONFIGURATION ==================
REMOTE_PATH="/test" # Remote path on MEGA
BASE_LOCAL_GET_DIR="/mnt/d/mega/UOJ/current" # Folder for get image
BASE_LOCAL_DIR="/mnt/d/mega/UOJ/snapshots" # Base folder for all snapshots
MAX_SNAPSHOTS=10 # Keep only the last N snapshots (rotation)
# ==================================================

# ================== CREDENTIALS ==================
MEGA_EMAIL=''
MEGA_PASS=''
# =================================================

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
NEW_SNAPSHOT="$BASE_LOCAL_DIR/${TIMESTAMP}"

# Attempt login only if not already authenticated
if ! mega-whoami > /dev/null 2>&1; then
	echo "(!) MEGA Not logged in. Authenticating..."
	mega-login "$MEGA_EMAIL" "$MEGA_PASS"
	
	if [ $? -ne 0 ]; then
        	echo "Authentication failed!"
        	exit 1
    	fi
fi


echo "=== Starting MEGA pull at $(date) ==="
echo "Current: $BASE_LOCAL_GET_DIR"
echo "Snapshot: $NEW_SNAPSHOT"


mega-get -m "$REMOTE_PATH" "$BASE_LOCAL_GET_DIR"

mkdir -p "$NEW_SNAPSHOT"
cp -r "$BASE_LOCAL_GET_DIR/." "$NEW_SNAPSHOT/"

if [ $? -eq 0 ]; then
	echo "Snapshot completed successfully: $NEW_SNAPSHOT"
else
	echo "Error during mega-get!"
	exit 1
fi

# === Rotation: Keep only the last MAX_SNAPSHOTS ===
cd "$BASE_LOCAL_DIR" || exit 1

# Finds directories, sorts by time, drops the newest MAX_SNAPSHOTS, safely deletes the rest
find . -maxdepth 1 -type d ! -name '.' -printf '%T@ %p\n' | \
    sort -rn | \
    cut -d' ' -f2- | \
    tail -n +$((MAX_SNAPSHOTS + 1)) | \
    xargs -d '\n' -I {} rm -rf "{}"


echo "Kept last $MAX_SNAPSHOTS snapshots."
echo "=== Done at $(date) ==="
