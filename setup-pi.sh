#!/bin/bash
# Setup script for RetroPie (Raspberry Pi 3B+ / ARMv7 / Debian Buster)
# Run this ON the Pi after cloning the repo.

set -e

NODE_VERSION="18.20.8"
NODE_ARCH="armv7l"
NODE_DIR="/opt/node-v${NODE_VERSION}"

echo "=== discodog setup for RetroPie ==="

# Fix Buster EOL repos — the original mirrors are gone
SOURCES_FILE="/etc/apt/sources.list"
if grep -q "raspbian.raspberrypi.org" "$SOURCES_FILE" 2>/dev/null; then
  echo "Fixing apt sources for Buster (EOL)..."
  sudo sed -i 's|http://raspbian.raspberrypi.org/raspbian|http://legacy.raspbian.org/raspbian|g' "$SOURCES_FILE"
  sudo apt-get update
fi

# Install fswebcam if not present
if ! command -v fswebcam &> /dev/null; then
  echo "Installing fswebcam..."
  sudo apt-get update && sudo apt-get install -y fswebcam
else
  echo "fswebcam already installed."
fi

# Install Node.js 18 LTS via prebuilt binary (nodesource doesn't support Buster anymore)
CURRENT_NODE_MAJOR=$(node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/' || echo "0")
CURRENT_NODE_MAJOR=${CURRENT_NODE_MAJOR:-0}

if [ "$CURRENT_NODE_MAJOR" -lt 18 ]; then
  echo "Installing Node.js v${NODE_VERSION} (${NODE_ARCH})..."
  TARBALL="node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/${TARBALL}" -o "/tmp/${TARBALL}"
  sudo mkdir -p "$NODE_DIR"
  sudo tar -xJf "/tmp/${TARBALL}" -C "$NODE_DIR" --strip-components=1
  rm "/tmp/${TARBALL}"

  # Symlink into /usr/local/bin
  sudo ln -sf "${NODE_DIR}/bin/node" /usr/local/bin/node
  sudo ln -sf "${NODE_DIR}/bin/npm" /usr/local/bin/npm
  sudo ln -sf "${NODE_DIR}/bin/npx" /usr/local/bin/npx

  echo "Node.js $(node -v) installed."
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
