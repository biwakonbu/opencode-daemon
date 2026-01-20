#!/usr/bin/env bash
set -euo pipefail

if ! swift format --version >/dev/null 2>&1; then
  echo "swift format not available. install with Xcode or a Swift toolchain." >&2
  exit 1
fi

swift format format --in-place --recursive --configuration .swift-format Sources Tests
