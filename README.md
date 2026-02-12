# peon-ping

![macOS](https://img.shields.io/badge/macOS-blue) ![WSL2](https://img.shields.io/badge/WSL2-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![OpenCode](https://img.shields.io/badge/OpenCode-hook-ffab01)

**Your Peon pings you when OpenCode needs attention.**

OpenCode doesn't notify you when it finishes or needs permission. You tab away, lose focus, and waste 15 minutes getting back into flow. peon-ping fixes this with Warcraft III Peon voice lines — so you never miss a beat, and your terminal sounds like Orgrimmar.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/tonyyont/peon-ping/main/install.sh | bash
```

One command. Takes 10 seconds. macOS and WSL2 (Windows). Re-run to update (sounds and config preserved).

## What you'll hear

| Event | Sound | Examples |
|---|---|---|
| Session starts | Greeting | *"Ready to work?"*, *"Yes?"*, *"What you want?"* |
| Task finishes | Acknowledgment | *"Work, work."*, *"I can do that."*, *"Okie dokie."* |
| Permission needed | Alert | *"Something need doing?"*, *"Hmm?"*, *"What you want?"* |
| Rapid prompts (3+ in 10s) | Easter egg | *"Me busy, leave me alone!"* |

Plus Terminal tab titles (`● project: done`) and desktop notifications when your terminal isn't focused.

## Quick controls

Need to mute sounds and notifications during a meeting or pairing session?

```bash
bash ~/.config/opencode/peon-ping/peon.sh --toggle
```

Other commands:

```bash
bash ~/.config/opencode/peon-ping/peon.sh --pause          # Mute sounds
bash ~/.config/opencode/peon-ping/peon.sh --resume         # Unmute sounds
bash ~/.config/opencode/peon-ping/peon.sh --status         # Check if paused or active
```

Pausing mutes sounds and desktop notifications instantly. Persists across sessions until you resume. Tab titles remain active when paused.

## Configuration

Edit `~/.config/opencode/peon-ping/config.json`:

```json
{
  "volume": 0.5,
  "categories": {
    "greeting": true,
    "acknowledge": true,
    "complete": true,
    "error": true,
    "permission": true,
    "annoyed": true
  }
}
```

- **volume**: 0.0–1.0 (quiet enough for the office)
- **categories**: Toggle individual sound types on/off
- **annoyed_threshold / annoyed_window_seconds**: How many prompts in N seconds triggers the easter egg

## Sound pack

This lite version includes only the `peon` pack.

| Pack | Character | Sounds | By |
|---|---|---|---|
| `peon` (default) | Orc Peon (Warcraft III) | "Ready to work?", "Work, work.", "Okie dokie." | [@tonyyont](https://github.com/tonyyont) |

Want to add your own pack? See [CONTRIBUTING.md](CONTRIBUTING.md).

## Uninstall

```bash
bash ~/.config/opencode/peon-ping/uninstall.sh
```

## Requirements

- macOS (uses `afplay` and AppleScript) or WSL2 (uses PowerShell `MediaPlayer` and WinForms)
- OpenCode with plugins support
- python3

## How it works

`opencode-plugin.mjs` is an OpenCode plugin that listens for session and permission events. On each event it maps to a sound category, picks a random voice line (avoiding repeats), plays it via `afplay` (macOS) or PowerShell `MediaPlayer` (WSL2), and updates your terminal tab title when possible.

Sound files are property of their respective publishers (Blizzard Entertainment, EA) and are included in the repo for convenience.

## Links

- [License (MIT)](LICENSE)
