import AVFoundation

/// The 1D/2D symbologies the scanner looks for, and their display names.
enum BarcodeSymbology {
    static let supported: [AVMetadataObject.ObjectType] = [
        .qr, .aztec, .pdf417, .dataMatrix,
        .ean8, .ean13, .upce,
        .code39, .code39Mod43, .code93, .code128,
        .interleaved2of5, .itf14
    ]

    static func displayName(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr: return "QR"
        case .aztec: return "Aztec"
        case .pdf417: return "PDF417"
        case .dataMatrix: return "Data Matrix"
        case .ean8: return "EAN-8"
        case .ean13: return "EAN-13"
        case .upce: return "UPC-E"
        case .code39: return "Code 39"
        case .code39Mod43: return "Code 39 mod 43"
        case .code93: return "Code 93"
        case .code128: return "Code 128"
        case .interleaved2of5: return "Interleaved 2 of 5"
        case .itf14: return "ITF-14"
        default: return type.rawValue
        }
    }
}
