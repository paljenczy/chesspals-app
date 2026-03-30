#!/usr/bin/env bash
# ChessPals setup script
# Run this once after cloning to set up the Flutter project.
#
# Prerequisites:
#   - Flutter SDK >=3.22.0 (install: brew install --cask flutter)
#   - Xcode (Mac App Store) + cocoapods (sudo gem install cocoapods)
#   - flutter doctor --all (should be all green)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== ChessPals Setup ==="
echo ""

# 1. Check Flutter
if ! command -v flutter &> /dev/null; then
  echo "ERROR: Flutter not found."
  echo "Install with: brew install --cask flutter"
  echo "Then re-run this script."
  exit 1
fi

FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
echo "Flutter: $FLUTTER_VERSION"
echo ""

# 2. Generate platform directories (ios/, android/, macos/) if missing
if [ ! -d "ios" ]; then
  echo "Generating platform directories..."
  flutter create \
    --project-name chesspals \
    --org com.chesspals \
    --platforms ios,android \
    --no-overwrite \
    .
  echo "Platform directories created."
fi

# 3. Install Dart packages
echo ""
echo "Installing dependencies..."
flutter pub get

# 4. Run code generation (Riverpod, Freezed)
echo ""
echo "Running code generation..."
dart run build_runner build --delete-conflicting-outputs

# 5. Verify
echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  flutter run -d <device>          # Run on a connected device"
echo "  flutter run -d 'iPhone 16'       # Run on iOS Simulator"
echo "  open -a Simulator                # Open iOS Simulator first"
echo ""
echo "Development flag (uses lichess.dev instead of production):"
echo "  flutter run --dart-define=LICHESS_HOST=lichess.dev"
