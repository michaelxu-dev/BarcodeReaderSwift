#!/bin/zsh
# Build a signed, App Store-ready .ipa for BarcodeReaderSwift.
#
# Signs under team 4DNNKGDUKE. Bump MARKETING_VERSION / CURRENT_PROJECT_VERSION
# in the project's build settings before running this for a new submission.
#
# NOTE: bundle ID com.sagua.BarcodeReaderSwift is distinct from the shipping
# app's COM.SAGUA.BarcodeReader, so it needs its own App Store provisioning
# profile. -allowProvisioningUpdates lets Xcode create one, but the App ID must
# exist in the developer portal first.
#
# Output: build/ipa/BarcodeReaderSwift.ipa
# Upload that file with Transporter to submit to App Store Connect.

set -e

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$(dirname "$0")"

SCHEME="BarcodeReaderSwift"
TEAM_ID="4DNNKGDUKE"
ARCHIVE="build/BarcodeReaderSwift.xcarchive"
EXPORT_DIR="build/ipa"
OPTIONS="build/ExportOptions.plist"

mkdir -p build

cat > "$OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
PLIST

echo "Archiving..."
xcodebuild -project BarcodeReaderSwift.xcodeproj -scheme "$SCHEME" \
  -sdk iphoneos -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -quiet archive

echo "Exporting .ipa..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$OPTIONS" \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates \
  -quiet

echo ""
echo "IPA at: $EXPORT_DIR/$SCHEME.ipa"
