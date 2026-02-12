import fs from "fs"
import os from "os"
import path from "path"
import childProcess from "child_process"

const PEON_DIR =
  process.env.OPENCODE_PEON_DIR ||
  process.env.CLAUDE_PEON_DIR ||
  path.join(os.homedir(), ".config/opencode/peon-ping")
const CONFIG_PATH = path.join(PEON_DIR, "config.json")
const STATE_PATH = path.join(PEON_DIR, ".state.json")
const PACK_DIR = path.join(PEON_DIR, "packs", "peon")
const TEST_DIR = process.env.OPENCODE_PEON_TEST_DIR

const EVENT_TYPES = {
  SESSION_CREATED: "session.created",
  SESSION_IDLE: "session.idle",
  SESSION_ERROR: "session.error",
  PERMISSION_ASKED: "permission.asked",
  PERMISSION_REPLIED: "permission.replied",
  TUI_PROMPT_APPEND: "tui.prompt.append",
  TUI_COMMAND_EXECUTE: "tui.command.execute"
}

const CATEGORY_ORDER = [
  "greeting",
  "acknowledge",
  "complete",
  "error",
  "permission",
  "resource_limit",
  "annoyed"
]

function detectPlatform() {
  if (process.platform === "darwin") return "mac"
  if (process.platform === "linux") {
    try {
      const ver = fs.readFileSync("/proc/version", "utf8")
      if (ver.toLowerCase().includes("microsoft")) return "wsl"
    } catch {
      return "linux"
    }
    return "linux"
  }
  return "unknown"
}

function readJson(filePath, fallback) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"))
  } catch {
    return fallback
  }
}

function writeJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true })
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + "\n")
}

function logAction(type, payload) {
  if (!TEST_DIR) return false
  const line = JSON.stringify({ type, ...payload }) + "\n"
  fs.mkdirSync(TEST_DIR, { recursive: true })
  fs.appendFileSync(path.join(TEST_DIR, "actions.log"), line)
  return true
}

function execDetached(command, args) {
  const child = childProcess.spawn(command, args, {
    detached: true,
    stdio: "ignore"
  })
  child.unref()
}

function playSound(file, volume, category) {
  if (logAction("sound", { category, file, volume })) return
  const platform = detectPlatform()
  if (platform === "mac") {
    execDetached("afplay", ["-v", String(volume), file])
  } else if (platform === "wsl") {
    const wpath = childProcess
      .execFileSync("wslpath", ["-w", file], { encoding: "utf8" })
      .trim()
      .replace(/\\/g, "/")
    const cmd = [
      "-NoProfile",
      "-NonInteractive",
      "-Command",
      "Add-Type -AssemblyName PresentationCore;" +
        "$p = New-Object System.Windows.Media.MediaPlayer;" +
        `$p.Open([Uri]::new('file:///${wpath}'));` +
        `$p.Volume = ${volume};` +
        "Start-Sleep -Milliseconds 200;" +
        "$p.Play();" +
        "Start-Sleep -Seconds 3;" +
        "$p.Close();"
    ]
    execDetached("powershell.exe", cmd)
  }
}

function terminalIsFocused() {
  if (TEST_DIR) return false
  const platform = detectPlatform()
  if (platform !== "mac") return false
  try {
    const out = childProcess
      .execFileSync("osascript", [
        "-e",
        'tell application "System Events" to get name of first process whose frontmost is true'
      ], { encoding: "utf8" })
      .trim()
    return ["Terminal", "iTerm2", "Warp", "Alacritty", "kitty", "WezTerm", "Ghostty"].includes(
      out
    )
  } catch {
    return false
  }
}

function sendNotification(message, title, color) {
  if (logAction("notify", { color, message, title })) return
  const platform = detectPlatform()
  if (platform === "mac") {
    execDetached("osascript", [
      "-e",
      `display notification ${JSON.stringify(message)} with title ${JSON.stringify(title)}`
    ])
    return
  }
  if (platform !== "wsl") return

  let rgb = [180, 0, 0]
  if (color === "blue") rgb = [30, 80, 180]
  if (color === "yellow") rgb = [200, 160, 0]
  const [r, g, b] = rgb
  const cmd = [
    "-NoProfile",
    "-NonInteractive",
    "-Command",
    "Add-Type -AssemblyName System.Windows.Forms;" +
      "Add-Type -AssemblyName System.Drawing;" +
      "foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {" +
      "$form = New-Object System.Windows.Forms.Form;" +
      "$form.FormBorderStyle = 'None';" +
      `$form.BackColor = [System.Drawing.Color]::FromArgb(${r}, ${g}, ${b});` +
      "$form.Size = New-Object System.Drawing.Size(500, 80);" +
      "$form.TopMost = $true;" +
      "$form.ShowInTaskbar = $false;" +
      "$form.StartPosition = 'Manual';" +
      "$form.Location = New-Object System.Drawing.Point(" +
      "($screen.WorkingArea.X + ($screen.WorkingArea.Width - 500) / 2)," +
      "($screen.WorkingArea.Y + 40)" +
      ");" +
      "$label = New-Object System.Windows.Forms.Label;" +
      `$label.Text = ${JSON.stringify(message)};` +
      "$label.ForeColor = [System.Drawing.Color]::White;" +
      "$label.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold);" +
      "$label.TextAlign = 'MiddleCenter';" +
      "$label.Dock = 'Fill';" +
      "$form.Controls.Add($label);" +
      "$form.Show();" +
      "}" +
      "Start-Sleep -Seconds 4;" +
      "[System.Windows.Forms.Application]::Exit();"
  ]
  execDetached("powershell.exe", cmd)
}

function sanitizeProjectName(name) {
  return name.replace(/[^a-zA-Z0-9 ._-]/g, "")
}

function getProjectName(ctx) {
  const base = ctx.worktree || ctx.directory || "opencode"
  const name = path.basename(base || "opencode") || "opencode"
  return sanitizeProjectName(name)
}

function pickSound(state, category) {
  try {
    const manifest = readJson(path.join(PACK_DIR, "manifest.json"), {})
    const sounds = manifest.categories?.[category]?.sounds || []
    if (!sounds.length) return null
    const lastPlayed = state.last_played || {}
    const lastFile = lastPlayed[category]
    const candidates = sounds.length <= 1 ? sounds : sounds.filter((s) => s.file !== lastFile)
    const pick = candidates[Math.floor(Math.random() * candidates.length)]
    lastPlayed[category] = pick.file
    state.last_played = lastPlayed
    return pick.file
  } catch {
    return null
  }
}

export const PeonPingPlugin = async (ctx) => {
  const project = getProjectName(ctx)
  return {
    event: async ({ event }) => {
      const config = readJson(CONFIG_PATH, {})
      if (String(config.enabled ?? true).toLowerCase() === "false") return

      const paused = fs.existsSync(path.join(PEON_DIR, ".paused"))
      const state = readJson(STATE_PATH, {})
      let stateDirty = false

      const categories = config.categories || {}
      const categoryEnabled = {}
      for (const c of CATEGORY_ORDER) {
        categoryEnabled[c] = String(categories[c] ?? true).toLowerCase() === "true"
      }

      const annoyedThreshold = Number(config.annoyed_threshold ?? 3)
      const annoyedWindow = Number(config.annoyed_window_seconds ?? 10)
      const volume = Number(config.volume ?? 0.5)

      const type = event?.type || ""
      const sessionId = event?.session?.id || event?.sessionId || "default"

      let category = ""
      let status = ""
      let marker = ""
      let notify = false
      let notifyColor = "red"
      let message = ""

      if (type === EVENT_TYPES.SESSION_CREATED) {
        category = "greeting"
        status = "ready"
      } else if (type === EVENT_TYPES.SESSION_IDLE) {
        category = "complete"
        status = "done"
        marker = "* "
        notify = true
        notifyColor = "blue"
        message = `${project} - Task complete`
      } else if (type === EVENT_TYPES.PERMISSION_ASKED) {
        category = "permission"
        status = "needs approval"
        marker = "* "
        notify = true
        notifyColor = "red"
        message = `${project} - Permission needed`
      } else if (type === EVENT_TYPES.SESSION_ERROR) {
        category = "error"
        status = "error"
        marker = "* "
        notify = true
        notifyColor = "red"
        message = `${project} - Session error`
      } else if (type === EVENT_TYPES.TUI_COMMAND_EXECUTE || type === EVENT_TYPES.TUI_PROMPT_APPEND) {
        status = "working"
        if (categoryEnabled.annoyed) {
          const allTs = Array.isArray(state.prompt_timestamps)
            ? {}
            : state.prompt_timestamps || {}
          const now = Date.now() / 1000
          const ts = (allTs[sessionId] || []).filter((t) => now - t < annoyedWindow)
          ts.push(now)
          allTs[sessionId] = ts
          state.prompt_timestamps = allTs
          stateDirty = true
          if (ts.length >= annoyedThreshold) category = "annoyed"
        }
      } else if (type === EVENT_TYPES.PERMISSION_REPLIED) {
        status = "working"
      } else {
        return
      }

      if (category && !categoryEnabled[category]) category = ""

      let soundFile = ""
      if (category && !paused) {
        const file = pickSound(state, category)
        if (file) {
          soundFile = path.join(PACK_DIR, "sounds", file)
          stateDirty = true
        }
      }

      if (stateDirty) writeJson(STATE_PATH, state)

      if (status) {
        const title = `${marker}${project}: ${status}`
        if (logAction("title", { title })) {
          // no-op
        } else if (process.stdout.isTTY) {
          process.stdout.write(`\u001b]0;${title}\u0007`)
        }
      }

      if (soundFile && fs.existsSync(soundFile)) {
        playSound(soundFile, volume, category)
      }

      if (notify && !paused) {
        if (!terminalIsFocused()) {
          const title = `${marker}${project}: ${status}`
          sendNotification(message, title, notifyColor)
        }
      }
    }
  }
}

export default PeonPingPlugin
