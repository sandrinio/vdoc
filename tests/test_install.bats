#!/usr/bin/env bats
# Tests for install.sh

setup() {
  SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
  PROJECT_ROOT="$SCRIPT_DIR/.."
  INSTALL_SH="$PROJECT_ROOT/install.sh"
  FIXTURES="$SCRIPT_DIR/fixtures"
}

@test "install.sh exists and is executable" {
  [ -f "$INSTALL_SH" ]
  [ -x "$INSTALL_SH" ] || chmod +x "$INSTALL_SH"
}

@test "install.sh shows usage without arguments" {
  run bash "$INSTALL_SH"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "install.sh detects typescript project" {
  cd "$FIXTURES/typescript-project"
  run bash "$INSTALL_SH" claude
  [[ "$output" == *"Detected: typescript"* ]]
}

@test "install.sh detects python project" {
  cd "$FIXTURES/python-project"
  run bash "$INSTALL_SH" claude
  [[ "$output" == *"Detected: python"* ]]
}
