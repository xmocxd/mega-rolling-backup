#!/bin/bash
# backup files from mega
# MEGAcmd version: 2.1.1.1: code 2010101

# NOTE - RUN mega-mount and look for INSHARE to get shared folders

# ================== CONFIGURATION ==================
REMOTE_PATH="//from/" # Remote path on MEGA
BASE_LOCAL_GET_DIR="/mnt/d/mega/UOJ/current" # Folder for get image
BASE_LOCAL_DIR="/mnt/d/mega/UOJ/snapshots" # Base folder for all snapshots
MAX_SNAPSHOTS=5 # Keep only the last N snapshots (rotation)
CRON_DAYS=3 # do a snapshot once every n days (n cron job runs)
COUNTER_FILE="/mnt/d/mega/UOJ/.run_counter" # tracker file for day count
# ==================================================

# ================== CREDENTIALS ==================
MEGA_EMAIL=''
MEGA_PASS=''
# =================================================

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
NEW_SNAPSHOT="$BASE_LOCAL_DIR/${TIMESTAMP}"

# Ensure directories exist
mkdir -p "$BASE_LOCAL_GET_DIR"
mkdir -p "$BASE_LOCAL_DIR"

if [ ! -f "$COUNTER_FILE" ]; then echo "1" > "$COUNTER_FILE"; fi
RUN_COUNT=$(cat "$COUNTER_FILE")

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
echo ""
echo "Current: $BASE_LOCAL_GET_DIR"

if [ "$RUN_COUNT" -ge "$CRON_DAYS" ]; then
	echo "Snapshot: $NEW_SNAPSHOT"
else
    echo "Snapshot: SKIPPED (Day $RUN_COUNT/$CRON_DAYS)"
fi

echo ""

mega-get -m "$REMOTE_PATH" "$BASE_LOCAL_GET_DIR"

if [ $? -eq 0 ]; then
	echo "Download completed successfully."
else
	echo "Error during mega-get!"
	exit 1
fi

if [ "$RUN_COUNT" -ge "$CRON_DAYS" ]; then
	echo "Taking snapshot / rotating..."

    mkdir -p "$NEW_SNAPSHOT"
    cp -a "$BASE_LOCAL_GET_DIR/." "$NEW_SNAPSHOT/"

	# === Rotation: Keep only the last MAX_SNAPSHOTS ===
	cd "$BASE_LOCAL_DIR" || exit 1

	# 1. ls -1r : List folders one per line, Reversed (newest/highest date at top)
	# 2. tail -n +$((MAX_SNAPSHOTS + 1)) : Skip the first N newest folders, catch the rest
	# 3. xargs : Delete the leftovers
	ls -1r | grep '^[0-9]' | tail -n +$((MAX_SNAPSHOTS + 1)) | xargs -I {} rm -rf "{}"
	echo "Kept last $MAX_SNAPSHOTS snapshots."

    echo "1" > "$COUNTER_FILE" # Reset
else
    echo "$((RUN_COUNT + 1))" > "$COUNTER_FILE" # Increment
fi

echo "=== Done at $(date) ==="
