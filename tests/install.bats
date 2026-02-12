#!/usr/bin/env bats

# Tests for install.sh (local clone mode only — no network)

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"

  # Create a fake local clone with all required files
  CLONE_DIR="$(mktemp -d)"
  cp "$(dirname "$BATS_TEST_FILENAME")/../install.sh" "$CLONE_DIR/"
  cp "$(dirname "$BATS_TEST_FILENAME")/../opencode-plugin.mjs" "$CLONE_DIR/"
  cp "$(dirname "$BATS_TEST_FILENAME")/../peon.sh" "$CLONE_DIR/"
  cp "$(dirname "$BATS_TEST_FILENAME")/../config.json" "$CLONE_DIR/"
  cp "$(dirname "$BATS_TEST_FILENAME")/../VERSION" "$CLONE_DIR/"
  cp "$(dirname "$BATS_TEST_FILENAME")/../uninstall.sh" "$CLONE_DIR/"
  cp -r "$(dirname "$BATS_TEST_FILENAME")/../packs" "$CLONE_DIR/"

  CONFIG_DIR="$TEST_HOME/.config/opencode"
  PLUGIN_DIR="$CONFIG_DIR/plugins"
  INSTALL_DIR="$CONFIG_DIR/peon-ping"
}

teardown() {
  rm -rf "$TEST_HOME" "$CLONE_DIR"
}

@test "fresh install creates all expected files" {
  bash "$CLONE_DIR/install.sh"
  [ -f "$PLUGIN_DIR/peon-ping.mjs" ]
  [ -f "$INSTALL_DIR/peon.sh" ]
  [ -f "$INSTALL_DIR/config.json" ]
  [ -f "$INSTALL_DIR/VERSION" ]
  [ -f "$INSTALL_DIR/.state.json" ]
  [ -f "$INSTALL_DIR/packs/peon/manifest.json" ]
}

@test "fresh install copies sound files" {
  bash "$CLONE_DIR/install.sh"
  peon_count=$(ls "$INSTALL_DIR/packs/peon/sounds/"*.wav 2>/dev/null | wc -l | tr -d ' ')
  [ "$peon_count" -gt 0 ]
}

@test "fresh install creates VERSION file" {
  bash "$CLONE_DIR/install.sh"
  [ -f "$INSTALL_DIR/VERSION" ]
  version=$(cat "$INSTALL_DIR/VERSION" | tr -d '[:space:]')
  expected=$(cat "$CLONE_DIR/VERSION" | tr -d '[:space:]')
  [ "$version" = "$expected" ]
}

@test "update preserves existing config" {
  # First install
  bash "$CLONE_DIR/install.sh"

  # Modify config
  echo '{"volume": 0.9}' > "$INSTALL_DIR/config.json"

  # Re-run (update)
  bash "$CLONE_DIR/install.sh"

  # Config should be preserved (not overwritten)
  volume=$(/usr/bin/python3 -c "import json; print(json.load(open('$INSTALL_DIR/config.json')).get('volume'))")
  [ "$volume" = "0.9" ]
}

@test "peon.sh is executable after install" {
  bash "$CLONE_DIR/install.sh"
  [ -x "$INSTALL_DIR/peon.sh" ]
}
