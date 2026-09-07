import SwiftUI

/// SwiftUI wrapper around `ScannerViewController`.
struct ScannerView: UIViewControllerRepresentable {
    var onScan: (String, String) -> Void
    var onCancel: () -> Void
    var onError: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: ScannerViewController, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: ScannerViewControllerDelegate {
        var parent: ScannerView

        init(_ parent: ScannerView) { self.parent = parent }

        func scanner(_ controller: ScannerViewController, didScan text: String, symbology: String) {
            parent.onScan(text, symbology)
        }

        func scannerDidCancel(_ controller: ScannerViewController) {
            parent.onCancel()
        }

        func scanner(_ controller: ScannerViewController, didFailWith message: String) {
            parent.onError(message)
        }
    }
}
