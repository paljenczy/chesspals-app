#!/usr/bin/env bash
# run.sh — launch ChessPals with hot-reload for fast development
#
# Usage:
#   ./run.sh              # Chrome (fastest feedback loop)
#   ./run.sh --android    # Android emulator
#   ./run.sh --ios        # iOS Simulator
#   ./run.sh --device ID  # Specific device ID
#   ./run.sh --no-watch   # Skip build_runner watch
#   ./run.sh --release    # (or any other flutter run flags)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

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

# Defaults
DEVICE="${FLUTTER_DEVICE:-chrome}"
START_WATCH=true
USE_WASM=false
EXTRA_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --android)
      DEVICE="emulator-5554"
      shift
      ;;
    --ios)
      DEVICE="iPhone 16"
      shift
      ;;
    --device)
      DEVICE="$2"
      shift 2
      ;;
    --no-watch)
      START_WATCH=false
      shift
      ;;
    --no-wasm)
      USE_WASM=false
      shift
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# Auto-enable --wasm for Chrome (dartchess uses 64-bit ints that JS can't represent)
if [[ "$DEVICE" == "chrome" ]]; then
  USE_WASM=true
fi

# Start build_runner watch in background (for Freezed/Riverpod codegen)
WATCH_PID=""
if $START_WATCH; then
  echo "Starting build_runner watch in background..."
  cd "$SCRIPT_DIR"
  dart run build_runner watch --delete-conflicting-outputs 2>&1 | sed 's/^/[codegen] /' &
  WATCH_PID=$!

  cleanup() {
    if [[ -n "$WATCH_PID" ]] && kill -0 "$WATCH_PID" 2>/dev/null; then
      kill "$WATCH_PID" 2>/dev/null || true
    fi
  }
  trap cleanup EXIT
fi

echo ""
echo "=== ChessPals Dev ==="
echo "Device:  $DEVICE"
if $USE_WASM; then
  echo "Wasm:    enabled (required for dartchess 64-bit bitboards)"
fi
echo "Defines: loaded from .env"
if [[ -n "$WATCH_PID" ]]; then
  echo "Codegen: build_runner watch (PID $WATCH_PID)"
fi
echo ""
echo "Hot-reload keys (once running):"
echo "  r  — Hot reload  (sub-second, keeps state)"
echo "  R  — Hot restart (full restart, ~2-3s)"
echo "  q  — Quit"
echo ""

cd "$SCRIPT_DIR"
WASM_FLAG=""
if $USE_WASM; then
  WASM_FLAG="--wasm"
fi
# shellcheck disable=SC2086
flutter run -d "$DEVICE" $WASM_FLAG $DART_DEFINES "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
