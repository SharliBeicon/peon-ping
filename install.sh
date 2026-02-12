#!/bin/bash
# peon-ping installer (OpenCode plugin)
set -euo pipefail

CONFIG_DIR="$HOME/.config/opencode"
PLUGIN_DIR="$CONFIG_DIR/plugins"
PEON_DIR="$CONFIG_DIR/peon-ping"
REPO_BASE="https://raw.githubusercontent.com/tonyyont/peon-ping/main"

detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi ;;
    *) echo "unknown" ;;
  esac
}
PLATFORM=$(detect_platform)

UPDATING=false
if [ -f "$PEON_DIR/config.json" ]; then
  UPDATING=true
fi

if [ "$UPDATING" = true ]; then
  echo "=== peon-ping updater ==="
  echo ""
  echo "Existing install found. Updating..."
else
  echo "=== peon-ping installer ==="
  echo ""
fi

if [ "$PLATFORM" != "mac" ] && [ "$PLATFORM" != "wsl" ]; then
  echo "Error: peon-ping requires macOS or WSL (Windows Subsystem for Linux)"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required"
  exit 1
fi

if [ "$PLATFORM" = "mac" ]; then
  if ! command -v afplay &>/dev/null; then
    echo "Error: afplay is required (should be built into macOS)"
    exit 1
  fi
elif [ "$PLATFORM" = "wsl" ]; then
  if ! command -v powershell.exe &>/dev/null; then
    echo "Error: powershell.exe is required (should be available in WSL)"
    exit 1
  fi
  if ! command -v wslpath &>/dev/null; then
    echo "Error: wslpath is required (should be built into WSL)"
    exit 1
  fi
fi

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ]; then
  CANDIDATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  if [ -f "$CANDIDATE/opencode-plugin.mjs" ]; then
    SCRIPT_DIR="$CANDIDATE"
  fi
fi

mkdir -p "$PLUGIN_DIR" "$PEON_DIR" "$PEON_DIR/packs/peon/sounds"

if [ -n "$SCRIPT_DIR" ]; then
  cp "$SCRIPT_DIR/opencode-plugin.mjs" "$PLUGIN_DIR/peon-ping.mjs"
  if [ -f "$SCRIPT_DIR/opencode-plugin.js" ]; then
    cp "$SCRIPT_DIR/opencode-plugin.js" "$PLUGIN_DIR/peon-ping.js"
  fi
  cp -r "$SCRIPT_DIR/packs/peon" "$PEON_DIR/packs/"
  cp "$SCRIPT_DIR/peon.sh" "$PEON_DIR/peon.sh"
  cp "$SCRIPT_DIR/VERSION" "$PEON_DIR/VERSION"
  cp "$SCRIPT_DIR/uninstall.sh" "$PEON_DIR/uninstall.sh"
  if [ "$UPDATING" = false ]; then
    cp "$SCRIPT_DIR/config.json" "$PEON_DIR/config.json"
  fi
else
  echo "Downloading from GitHub..."
  curl -fsSL "$REPO_BASE/opencode-plugin.mjs" -o "$PLUGIN_DIR/peon-ping.mjs"
  curl -fsSL "$REPO_BASE/opencode-plugin.js" -o "$PLUGIN_DIR/peon-ping.js"
  curl -fsSL "$REPO_BASE/peon.sh" -o "$PEON_DIR/peon.sh"
  curl -fsSL "$REPO_BASE/VERSION" -o "$PEON_DIR/VERSION"
  curl -fsSL "$REPO_BASE/uninstall.sh" -o "$PEON_DIR/uninstall.sh"
  curl -fsSL "$REPO_BASE/packs/peon/manifest.json" -o "$PEON_DIR/packs/peon/manifest.json"
  python3 -c "
import json
import os
manifest = json.load(open('$PEON_DIR/packs/peon/manifest.json'))
seen = set()
for cat in manifest.get('categories', {}).values():
    for s in cat.get('sounds', []):
        f = s['file']
        if f not in seen:
            seen.add(f)
            print(f)
" | while read -r sfile; do
    curl -fsSL "$REPO_BASE/packs/peon/sounds/$sfile" -o "$PEON_DIR/packs/peon/sounds/$sfile" </dev/null
  done
  if [ "$UPDATING" = false ]; then
    curl -fsSL "$REPO_BASE/config.json" -o "$PEON_DIR/config.json"
  fi
fi

chmod +x "$PEON_DIR/peon.sh"

if [ "$UPDATING" = false ]; then
  echo '{}' > "$PEON_DIR/.state.json"
fi

echo ""
echo "Testing sound..."
PACK_DIR="$PEON_DIR/packs/peon"
TEST_SOUND=$({ ls "$PACK_DIR/sounds/"*.wav "$PACK_DIR/sounds/"*.mp3 "$PACK_DIR/sounds/"*.ogg 2>/dev/null || true; } | head -1)
if [ -n "$TEST_SOUND" ]; then
  if [ "$PLATFORM" = "mac" ]; then
    afplay -v 0.3 "$TEST_SOUND"
  elif [ "$PLATFORM" = "wsl" ]; then
    wpath=$(wslpath -w "$TEST_SOUND")
    wpath="${wpath//\\//}"
    powershell.exe -NoProfile -NonInteractive -Command "
      Add-Type -AssemblyName PresentationCore
      \$p = New-Object System.Windows.Media.MediaPlayer
      \$p.Open([Uri]::new('file:///$wpath'))
      \$p.Volume = 0.3
      Start-Sleep -Milliseconds 200
      \$p.Play()
      Start-Sleep -Seconds 3
      \$p.Close()
    " 2>/dev/null
  fi
  echo "Sound working!"
else
  echo "Warning: No sound files found. Sounds may not play."
fi

echo ""
if [ "$UPDATING" = true ]; then
  echo "=== Update complete! ==="
else
  echo "=== Installation complete! ==="
  echo ""
  echo "Plugin: $PLUGIN_DIR/peon-ping.mjs"
  echo "Config: $PEON_DIR/config.json"
  echo "  - Adjust volume, toggle categories"
  echo ""
  echo "Uninstall: bash $PEON_DIR/uninstall.sh"
fi
echo ""
echo "Quick controls:"
echo "  $PEON_DIR/peon.sh --toggle  — toggle sounds"
echo "  $PEON_DIR/peon.sh --status  — check paused status"
echo ""
echo "Ready to work!"
