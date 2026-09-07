import Foundation

/// A single decoded barcode, as scanned.
struct ScanRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    /// Human-readable symbology, e.g. "QR", "EAN-13".
    let symbology: String
    let date: Date

    init(id: UUID = UUID(), text: String, symbology: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.symbology = symbology
        self.date = date
    }
}
