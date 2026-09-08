#!/bin/zsh
# Build and launch BarcodeReaderSwift on a connected iPhone.
#
# The device is detected at run time rather than hardcoded, so this works with
# whichever iPhone is plugged in. Pass a UDID to pick one explicitly:
#   ./run-dev.sh 00008120-00027D9A1ED2201E
#
# The iPhone must be connected via USB, unlocked, trusted ("Trust This
# Computer"), and have Developer Mode enabled:
#   Settings > Privacy & Security > Developer Mode
#
# Signing uses the team's wildcard development profile;
# -allowProvisioningUpdates lets Xcode register a new device as needed.

set -e

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$(dirname "$0")"

SCHEME="BarcodeReaderSwift"
BUNDLE_ID="com.sagua.BarcodeReaderSwift"
DERIVED="build/device"
APP="$DERIVED/Build/Products/Debug-iphoneos/$SCHEME.app"
DEVICE_UDID="${1:-}"

if [[ -z "$DEVICE_UDID" ]]; then
  DEVICE_JSON="$(mktemp -t devicectl)"
  xcrun devicectl list devices --json-output "$DEVICE_JSON" >/dev/null 2>&1 || true

  # Pick the first physically connected device.
  read -r DEVICE_UDID DEVICE_NAME <<<"$(python3 - "$DEVICE_JSON" <<'PY'
import json, sys
try:
    devices = json.load(open(sys.argv[1]))["result"]["devices"]
except Exception:
    sys.exit(0)
candidates = []
for d in devices:
    conn = d.get("connectionProperties", {})
    udid = d.get("hardwareProperties", {}).get("udid")
    if not udid or conn.get("tunnelState") == "unavailable":
        continue
    transport = conn.get("transportType")
    if transport not in ("wired", "localNetwork"):
        continue
    name = d.get("deviceProperties", {}).get("name", "iPhone")
    # A cabled device beats one merely reachable over Wi-Fi, which may be any
    # phone that happens to be on the network.
    candidates.append((0 if transport == "wired" else 1, udid, name))

candidates.sort()
if candidates:
    _, udid, name = candidates[0]
    print(udid, name)
PY
)"
  rm -f "$DEVICE_JSON"
fi

if [[ -z "$DEVICE_UDID" ]]; then
  echo "No connected iPhone found." >&2
  echo "Connect one via USB, unlock it, and trust this Mac. Current devices:" >&2
  xcrun devicectl list devices >&2
  exit 1
fi

echo "Device: ${DEVICE_NAME:-$DEVICE_UDID} ($DEVICE_UDID)"

echo "Building for device..."
xcodebuild -project BarcodeReaderSwift.xcodeproj -scheme "$SCHEME" \
  -sdk iphoneos -destination "id=$DEVICE_UDID" \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  -quiet build

echo "Installing..."
xcrun devicectl device install app --device "$DEVICE_UDID" "$APP"

echo "Launching..."
xcrun devicectl device process launch --device "$DEVICE_UDID" "$BUNDLE_ID"
