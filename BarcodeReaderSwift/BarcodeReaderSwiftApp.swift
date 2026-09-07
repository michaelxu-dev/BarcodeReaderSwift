import SwiftUI

@main
struct BarcodeReaderSwiftApp: App {
    @StateObject private var store = ScanStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
