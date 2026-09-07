import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: ScanStore
    @State private var isConfirmingClear = false

    var body: some View {
        List {
            ForEach(store.records) { record in
                ScanRow(record: record)
                    .contextMenu {
                        Button("Copy") { UIPasteboard.general.string = record.text }
                    }
            }
            .onDelete { store.delete(at: $0) }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear", role: .destructive) { isConfirmingClear = true }
                    .disabled(store.records.isEmpty)
            }
        }
        .confirmationDialog("Delete all scan history?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) { store.clear() }
            Button("Cancel", role: .cancel) { }
        }
        .overlay {
            if store.records.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "barcode",
                    description: Text("Scanned barcodes will appear here.")
                )
            }
        }
    }
}
