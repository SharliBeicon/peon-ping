#!/bin/bash
# peon-ping CLI helpers for OpenCode
set -euo pipefail

PEON_DIR="${OPENCODE_PEON_DIR:-${CLAUDE_PEON_DIR:-$HOME/.config/opencode/peon-ping}}"
PAUSED_FILE="$PEON_DIR/.paused"

case "${1:-}" in
  --pause)
    touch "$PAUSED_FILE"
    echo "peon-ping: sounds paused"
    ;;
  --resume)
    rm -f "$PAUSED_FILE"
    echo "peon-ping: sounds resumed"
    ;;
  --toggle)
    if [ -f "$PAUSED_FILE" ]; then
      rm -f "$PAUSED_FILE"
      echo "peon-ping: sounds resumed"
    else
      touch "$PAUSED_FILE"
      echo "peon-ping: sounds paused"
    fi
    ;;
  --status)
    [ -f "$PAUSED_FILE" ] && echo "peon-ping: paused" || echo "peon-ping: active"
    ;;
  --help|-h|"")
    cat <<'HELPEOF'
Usage: peon <command>

Commands:
  --pause        Mute sounds
  --resume       Unmute sounds
  --toggle       Toggle mute on/off
  --status       Check if paused or active
  --help         Show this help
HELPEOF
    ;;
  --*)
    echo "Unknown option: $1" >&2
    echo "Run 'peon --help' for usage." >&2
    exit 1
    ;;
esac
