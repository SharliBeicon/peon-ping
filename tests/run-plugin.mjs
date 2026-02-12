import path from "path"
import { fileURLToPath } from "url"
import { PeonPingPlugin } from "../opencode-plugin.mjs"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const eventType = process.argv[2]
const cwd = process.argv[3] || process.cwd()
const sessionId = process.argv[4] || "s1"

if (!eventType) {
  console.error("Missing event type")
  process.exit(1)
}

const ctx = {
  directory: cwd,
  worktree: cwd
}

const hooks = await PeonPingPlugin(ctx)
if (!hooks?.event) {
  console.error("Plugin missing event hook")
  process.exit(1)
}

await hooks.event({ event: { type: eventType, session: { id: sessionId } } })

// Allow detached processes to spin up in non-test runs
if (!process.env.OPENCODE_PEON_TEST_DIR) {
  await new Promise((r) => setTimeout(r, 50))
}
