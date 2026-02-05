#!/usr/bin/env bats
# Tests for language presets

setup() {
  SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
  PROJECT_ROOT="$SCRIPT_DIR/.."
  PRESETS_DIR="$PROJECT_ROOT/core/presets"
}

@test "typescript.conf has required variables" {
  source "$PRESETS_DIR/typescript.conf"
  [ -n "$PRESET_NAME" ]
  [ -n "$EXCLUDE_DIRS" ]
  [ -n "$DOC_SIGNALS" ]
  [ "$PRESET_NAME" = "typescript" ]
}

@test "python.conf has required variables" {
  source "$PRESETS_DIR/python.conf"
  [ -n "$PRESET_NAME" ]
  [ -n "$EXCLUDE_DIRS" ]
  [ -n "$DOC_SIGNALS" ]
  [ "$PRESET_NAME" = "python" ]
}

@test "default.conf has required variables" {
  source "$PRESETS_DIR/default.conf"
  [ -n "$PRESET_NAME" ]
  [ -n "$EXCLUDE_DIRS" ]
  [ -n "$DOC_SIGNALS" ]
  [ "$PRESET_NAME" = "default" ]
}

@test "typescript.conf excludes node_modules" {
  source "$PRESETS_DIR/typescript.conf"
  [[ "$EXCLUDE_DIRS" == *"node_modules"* ]]
}

@test "python.conf excludes __pycache__" {
  source "$PRESETS_DIR/python.conf"
  [[ "$EXCLUDE_DIRS" == *"__pycache__"* ]]
}
