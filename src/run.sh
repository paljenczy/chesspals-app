#!/usr/bin/env bash
# run.sh — launch ChessPals on the emulator with local secrets from .env
# Usage: ./run.sh [extra flutter run flags]
# E.g.:  ./run.sh --release

set -euo pipefail

ENV_FILE="$(dirname "$0")/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env not found. Copy .env.example and fill in your token:"
  echo "  cp .env.example .env"
  exit 1
fi

# Parse KEY=VALUE lines, skip comments and blank lines
DART_DEFINES=""
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  DART_DEFINES="$DART_DEFINES --dart-define=$line"
done < "$ENV_FILE"

# Pick device: prefer running emulator, fall back to first available
DEVICE="${FLUTTER_DEVICE:-emulator-5554}"

echo "Launching on $DEVICE with defines from .env..."
# shellcheck disable=SC2086
flutter run -d "$DEVICE" $DART_DEFINES "$@"
