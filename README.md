# BarcodeReaderSwift

A native Swift reimplementation of **SGBarcoder**, the iOS barcode scanner previously built with
Xamarin.iOS and later .NET for iOS (see the [BarcodeReader](https://github.com/michaelxu-dev/BarcodeReader)
repository).

## Features

- Scan 1D/2D barcodes with a full-screen camera view: reticle, torch toggle, cancel
- Result alert with copy-to-clipboard and scan-again
- Scan history with symbology and timestamp — swipe to delete, or clear all
- History persists as JSON in the app's Documents directory

## Supported symbologies

QR, Aztec, PDF417, Data Matrix, EAN-8, EAN-13, UPC-E, Code 39 (and mod 43), Code 93, Code 128,
Interleaved 2 of 5, ITF-14.

## Differences from the .NET version

- **No third-party decoder.** ZXing is replaced by `AVCaptureMetadataOutput`, which decodes
  barcodes natively.
- **No "default vs. custom overlay" split.** That distinction existed only to demo the two ZXing
  overlay modes; there is now a single scan UI.
- **Structured history.** Scans are stored as JSON records rather than appended lines in
  `Result.txt`, so history can be listed, deleted per-row, and shown with its symbology.

## Requirements

- Xcode 26+
- iOS 17.0+ deployment target

Scanning requires a physical device — the simulator has no camera.

## Building

```sh
xcodebuild -project BarcodeReaderSwift.xcodeproj -scheme BarcodeReaderSwift \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

If `xcode-select` points at the Command Line Tools rather than Xcode, prefix the command with
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## Structure

| File | Purpose |
| --- | --- |
| `BarcodeReaderSwiftApp.swift` | App entry point; owns the `ScanStore` |
| `ContentView.swift` | Home screen — scan button, recent scans, result alert |
| `HistoryView.swift` | Full history list with delete and clear |
| `ScannerView.swift` | SwiftUI wrapper over the scanner controller |
| `ScannerViewController.swift` | `AVCaptureSession` preview, overlay, decoding |
| `ScanStore.swift` | History model and JSON persistence |
| `ScanRecord.swift` | A single scan |
| `BarcodeSymbology.swift` | Supported types and their display names |
