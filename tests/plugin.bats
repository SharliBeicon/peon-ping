#!/usr/bin/env bats

load "./setup.bash"

setup() {
  setup_test_env
  export ACTIONS_LOG="$TEST_DIR/actions.log"
  rm -f "$ACTIONS_LOG"
}

teardown() {
  teardown_test_env
}

@test "session.created plays greeting sound" {
  run node "$(dirname "$BATS_TEST_FILENAME")/run-plugin.mjs" session.created "/tmp/myproject"
  [ "$status" -eq 0 ]
  grep -q '"type":"sound"' "$ACTIONS_LOG"
  grep -q '"category":"greeting"' "$ACTIONS_LOG"
}

@test "permission.asked sends notification" {
  run node "$(dirname "$BATS_TEST_FILENAME")/run-plugin.mjs" permission.asked "/tmp/myproject"
  [ "$status" -eq 0 ]
  grep -q '"type":"notify"' "$ACTIONS_LOG"
}

@test "paused suppresses sound and notification" {
  touch "$TEST_DIR/.paused"
  run node "$(dirname "$BATS_TEST_FILENAME")/run-plugin.mjs" session.idle "/tmp/myproject"
  [ "$status" -eq 0 ]
  [ ! -f "$ACTIONS_LOG" ] || ! grep -q '"type":"sound"' "$ACTIONS_LOG"
  [ ! -f "$ACTIONS_LOG" ] || ! grep -q '"type":"notify"' "$ACTIONS_LOG"
}

@test "annoyed triggers after rapid prompts" {
  for i in 1 2 3; do
    run node "$(dirname "$BATS_TEST_FILENAME")/run-plugin.mjs" tui.command.execute "/tmp/myproject" "s1"
  done
  grep -q '"category":"annoyed"' "$ACTIONS_LOG"
}

@test "unknown event does nothing" {
  run node "$(dirname "$BATS_TEST_FILENAME")/run-plugin.mjs" session.unknown "/tmp/myproject"
  [ "$status" -eq 0 ]
  [ ! -f "$ACTIONS_LOG" ]
}
