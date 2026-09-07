import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ScanStore

    @State private var isScanning = false
    @State private var lastScan: ScanRecord?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isScanning = true
                    } label: {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Recent") {
                    if store.records.isEmpty {
                        ContentUnavailableView(
                            "No scans yet",
                            systemImage: "barcode",
                            description: Text("Scanned barcodes will appear here.")
                        )
                    } else {
                        ForEach(store.records.prefix(5)) { record in
                            ScanRow(record: record)
                        }
                        NavigationLink("View all \(store.records.count) scans") {
                            HistoryView()
                        }
                    }
                }
            }
            .navigationTitle("SGBarcoder")
            .fullScreenCover(isPresented: $isScanning) {
                ScannerView(
                    onScan: { text, symbology in
                        let record = ScanRecord(text: text, symbology: symbology)
                        store.add(record)
                        isScanning = false
                        lastScan = record
                    },
                    onCancel: { isScanning = false },
                    onError: { message in
                        isScanning = false
                        errorMessage = message
                    }
                )
                .ignoresSafeArea()
            }
            .alert("Barcode Result", isPresented: .constant(lastScan != nil), presenting: lastScan) { record in
                Button("Copy") {
                    UIPasteboard.general.string = record.text
                    lastScan = nil
                }
                Button("Scan Again") {
                    lastScan = nil
                    isScanning = true
                }
                Button("Done", role: .cancel) { lastScan = nil }
            } message: { record in
                Text("\(record.symbology)\n\(record.text)")
            }
            .alert("Cannot Scan", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }
}

struct ScanRow: View {
    let record: ScanRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.text)
                .font(.body)
                .lineLimit(2)
            Text("\(record.symbology) · \(record.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView().environmentObject(ScanStore())
}
