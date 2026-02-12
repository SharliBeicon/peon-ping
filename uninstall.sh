#!/bin/bash
# peon-ping uninstaller (OpenCode plugin)
set -euo pipefail

CONFIG_DIR="$HOME/.config/opencode"
PLUGIN_DIR="$CONFIG_DIR/plugins"
PEON_DIR="$CONFIG_DIR/peon-ping"
PLUGIN_FILE="$PLUGIN_DIR/peon-ping.mjs"

echo "=== peon-ping uninstaller ==="
echo ""

if [ -f "$PLUGIN_FILE" ]; then
  rm -f "$PLUGIN_FILE"
  echo "Removed plugin: $PLUGIN_FILE"
else
  echo "Plugin not found: $PLUGIN_FILE"
fi

if [ -d "$PEON_DIR" ]; then
  rm -rf "$PEON_DIR"
  echo "Removed data: $PEON_DIR"
else
  echo "Data directory not found: $PEON_DIR"
fi

echo ""
echo "Uninstall complete."
