#!/bin/zsh
# Build and launch BarcodeReaderSwift on the iOS Simulator.
#
# Note: the simulator has no camera, so scanning can't be exercised here --
# use run-dev.sh on a real device for that. This is for UI work.
#
# Pass a simulator name to override the default, e.g. `./run-sim.sh "iPhone 16 Pro"`.

set -e

# xcode-select on this Mac points at the Command Line Tools, not Xcode, so
# xcodebuild/simctl need to be told where the real developer dir is.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$(dirname "$0")"

SCHEME="BarcodeReaderSwift"
BUNDLE_ID="com.sagua.BarcodeReaderSwift"
DERIVED="build/sim"
SIM_NAME="${1:-}"

# Prefer an already-booted simulator; otherwise pick the newest available iPhone.
if [[ -n "$SIM_NAME" ]]; then
  SIM_UDID=$(xcrun simctl list devices available | grep -m1 "$SIM_NAME (" | sed -E 's/.*\(([-0-9A-F]{36})\).*/\1/')
else
  SIM_UDID=$(xcrun simctl list devices booted | grep -m1 -E '\(Booted\)' | sed -E 's/.*\(([-0-9A-F]{36})\).*/\1/')
  if [[ -z "$SIM_UDID" ]]; then
    SIM_UDID=$(xcrun simctl list devices available | grep -E '^ +iPhone' | tail -1 | sed -E 's/.*\(([-0-9A-F]{36})\).*/\1/')
  fi
fi

if [[ -z "$SIM_UDID" ]]; then
  echo "No iOS Simulator found. Install one via Xcode > Settings > Components." >&2
  exit 1
fi

echo "Simulator: $SIM_UDID"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
open -a Simulator

echo "Building..."
xcodebuild -project BarcodeReaderSwift.xcodeproj -scheme "$SCHEME" \
  -sdk iphonesimulator -destination "id=$SIM_UDID" \
  -derivedDataPath "$DERIVED" \
  -quiet build

APP="$DERIVED/Build/Products/Debug-iphonesimulator/$SCHEME.app"

echo "Installing..."
xcrun simctl install "$SIM_UDID" "$APP"

echo "Launching..."
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"
