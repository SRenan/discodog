#!/bin/bash
# Setup script for RetroPie (Raspberry Pi 3B+ / ARMv7 / Debian-based)
# Run this ON the Pi after cloning the repo.

set -e

echo "=== discodog setup for RetroPie ==="

# Install fswebcam if not present
if ! command -v fswebcam &> /dev/null; then
  echo "Installing fswebcam..."
  sudo apt-get update && sudo apt-get install -y fswebcam
else
  echo "fswebcam already installed."
fi

# Install Node.js 18 LTS (ARMv7 compatible) if not present or too old
REQUIRED_NODE_MAJOR=18
CURRENT_NODE_MAJOR=$(node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/' || echo "0")

if [ "$CURRENT_NODE_MAJOR" -lt "$REQUIRED_NODE_MAJOR" ]; then
  echo "Installing Node.js ${REQUIRED_NODE_MAJOR}.x..."
  curl -fsSL https://deb.nodesource.com/setup_${REQUIRED_NODE_MAJOR}.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node.js $(node -v) is sufficient."
fi

# Install production dependencies only
echo "Installing npm dependencies..."
npm install --omit=dev

# Check for token file
if [ ! -f token.txt ]; then
  echo ""
  echo "WARNING: token.txt not found."
  echo "Create it with your Discord bot token:"
  echo "  echo 'YOUR_BOT_TOKEN' > token.txt"
fi

# Check if camera is detected
if ls /dev/video* &> /dev/null; then
  echo "USB camera detected: $(ls /dev/video*)"
else
  echo "WARNING: No USB camera detected at /dev/video*"
fi

echo ""
echo "=== Setup complete ==="
echo "To run manually:  node dist/bot.js"
echo "To install as a service:  sudo cp discodog.service /etc/systemd/system/ && sudo systemctl enable --now discodog"
