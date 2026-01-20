#!/usr/bin/env bash
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "swiftlint not found. install with: brew install swiftlint" >&2
  exit 1
fi

swiftlint --config .swiftlint.yml
