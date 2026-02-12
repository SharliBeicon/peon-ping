# Common test setup for OpenCode plugin tests

setup_test_env() {
  TEST_DIR="$(mktemp -d)"
  export OPENCODE_PEON_DIR="$TEST_DIR"
  export OPENCODE_PEON_TEST_DIR="$TEST_DIR"

  # Copy pack and config
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  mkdir -p "$TEST_DIR/packs"
  cp -r "$REPO_DIR/packs/peon" "$TEST_DIR/packs/"
  cp "$REPO_DIR/config.json" "$TEST_DIR/config.json"
  echo '{}' > "$TEST_DIR/.state.json"
}

teardown_test_env() {
  rm -rf "$TEST_DIR"
}
