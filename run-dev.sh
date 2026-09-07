#!/bin/zsh
# Build and launch BarcodeReaderSwift on Michael's iPhone 12 (real device).
#
# Deploys with `xcrun devicectl` rather than letting xcodebuild install, which
# keeps this working the same way as the .NET BarcodeReader's run-dev.sh.
#
# Requires the iPhone to be connected via USB cable and unlocked.

set -e

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$(dirname "$0")"

SCHEME="BarcodeReaderSwift"
DEVICE_UDID="00008101-001A19022EE9003A"
BUNDLE_ID="com.sagua.BarcodeReaderSwift"
DERIVED="build/device"
APP="$DERIVED/Build/Products/Debug-iphoneos/$SCHEME.app"

echo "Building for device..."
xcodebuild -project BarcodeReaderSwift.xcodeproj -scheme "$SCHEME" \
  -sdk iphoneos -destination "id=$DEVICE_UDID" \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  -quiet build

echo "Installing on iPhone 12..."
xcrun devicectl device install app --device "$DEVICE_UDID" "$APP"

echo "Launching..."
xcrun devicectl device process launch --device "$DEVICE_UDID" "$BUNDLE_ID"
