#!/usr/bin/env bats
# Tests for core/scan.sh

setup() {
  SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
  PROJECT_ROOT="$SCRIPT_DIR/.."
  SCAN_SH="$PROJECT_ROOT/core/scan.sh"
  FIXTURES="$SCRIPT_DIR/fixtures"
}

@test "scan.sh exists and is executable" {
  [ -f "$SCAN_SH" ]
  [ -x "$SCAN_SH" ] || chmod +x "$SCAN_SH"
}

@test "scan.sh outputs header comments" {
  run bash "$SCAN_SH"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "# vdoc scan output" ]]
}

@test "scan.sh includes version in output" {
  run bash "$SCAN_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"vdoc_version"* ]]
}

# TODO: Add more tests as scanner is implemented
# @test "scan.sh detects typescript project" { }
# @test "scan.sh extracts docstrings" { }
# @test "scan.sh computes file hashes" { }
