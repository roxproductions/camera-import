#!/bin/bash
# Camera Import — copy only new files from a USB camera (gphoto2), verify sizes.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
CONF="$HOME/.camera-import-last-folder"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
notify() { osascript -e "display notification \"$1\" with title \"Camera Import\"" 2>/dev/null; }
alert() { osascript -e "display alert \"Camera Import\" message \"$1\"" >/dev/null 2>&1; }
free_cam() { killall -9 ptpcamerad PTPCamera 2>/dev/null; }

# 1. gphoto2 available?
if ! command -v gphoto2 >/dev/null; then
  if command -v brew >/dev/null; then say "Installing gphoto2 (first run only)..."; brew install gphoto2 || exit 1
  else alert "gphoto2 is missing and Homebrew isn't installed. Install Homebrew from brew.sh first."; exit 1; fi
fi

# 2. Choose destination (defaults to last used)
LAST=$(cat "$CONF" 2>/dev/null); [ -d "$LAST" ] || LAST="$HOME/Pictures"
DEST="$1"
if [ -z "$DEST" ]; then
  DEST=$(osascript -e "POSIX path of (choose folder with prompt \"Import new camera files into:\" default location POSIX file \"$LAST\")" 2>/dev/null) || { echo "Cancelled."; exit 0; }
fi
DEST="${DEST%/}"; echo "$DEST" > "$CONF"
cd "$DEST" || exit 1
say "Destination: $DEST"

# 3. Free the camera from macOS and detect it
osascript -e 'quit app "Image Capture"' 2>/dev/null; sleep 1; free_cam
MODEL=$(gphoto2 --auto-detect | tail -n +3 | grep usb | sed 's/ *usb:.*//')
if [ -z "$MODEL" ]; then alert "No camera found. Turn the camera on, check the cable and try again."; exit 1; fi
say "Camera: $MODEL"

# 4. Check USB link speed
VENDOR=$(echo "$MODEL" | awk '{print $1}')
SPEED=$(ioreg -p IOUSB -w0 -l | grep -i -A15 "\"USB Vendor Name\" = \"$VENDOR" | grep '"Device Speed"' | head -1 | awk '{print $NF}')
[ -z "$SPEED" ] && SPEED=$(ioreg -p IOUSB -w0 -l | grep -i -B5 -A10 "$VENDOR" | grep '"Device Speed"' | head -1 | awk '{print $NF}')
case "$SPEED" in
  3|4) echo "USB link: USB 3 (fast)";;
  2) echo "USB link: USB 2.0 (slow, ~20 MB/s). A USB 3 / 5 Gbps cable plugged straight into the Mac is faster.";;
  *) echo "USB link: unknown";;
esac

# 5. List camera files, find what's missing or incomplete
free_cam
LIST=$(mktemp); gphoto2 --list-files 2>/dev/null | grep '^#' > "$LIST"
TOTAL=$(wc -l < "$LIST" | tr -d ' ')
NEED_KB=0; NEW=0; mkdir -p .incomplete 2>/dev/null
while read -r idx name rd kb rest; do
  if [ -f "$name" ]; then
    s=$(stat -f %z "$name"); d=$((s - kb*1024)); d=${d#-}
    if [ "$d" -ge 2048 ]; then mv "$name" ".incomplete/$name"; echo "Incomplete earlier copy moved aside: $name"; NEED_KB=$((NEED_KB+kb)); NEW=$((NEW+1)); fi
  else NEED_KB=$((NEED_KB+kb)); NEW=$((NEW+1)); fi
done < "$LIST"
rmdir .incomplete 2>/dev/null
say "$TOTAL files on camera, $NEW new ($((NEED_KB/1048576)) GB)."
if [ "$NEW" -eq 0 ]; then notify "Nothing new — all $TOTAL files are already in $(basename "$DEST")."; echo "Nothing to do."; exit 0; fi

# 6. Disk space check (needs new data + 1 GB margin)
AVAIL_KB=$(df -k "$DEST" | tail -1 | awk '{print $4}')
if [ "$AVAIL_KB" -lt $((NEED_KB + 1048576)) ]; then
  alert "Not enough disk space: need $((NEED_KB/1048576 + 1)) GB, only $((AVAIL_KB/1048576)) GB free. Free up space or pick another folder."; exit 1; fi

# 7. Download new files only
say "Downloading..."; free_cam
gphoto2 --get-all-files --skip-existing --filename "$DEST/%f.%C" 2>&1 | grep -vE '^(Skip existing|There is no file)'
rm -f tmpfile* 2>/dev/null

# 8. Verify every camera file against its size
OK=0; BAD=""
while read -r idx name rd kb rest; do
  s=$(stat -f %z "$name" 2>/dev/null || echo -1); d=$((s - kb*1024)); d=${d#-}
  if [ "$s" -gt 0 ] && [ "$d" -lt 2048 ]; then OK=$((OK+1)); else BAD="$BAD $name"; fi
done < "$LIST"
rm -f "$LIST"
if [ -z "$BAD" ]; then
  say "Done: all $TOTAL camera files are in the folder and verified ($NEW new)."
  notify "Done — $NEW new files imported and verified."
else
  say "Problem: these files didn't copy correctly:$BAD"
  say "Run Camera Import again to retry them."
  alert "$OK of $TOTAL files verified. Some didn't copy — run Camera Import again to retry."
fi
