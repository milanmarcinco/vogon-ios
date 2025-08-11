import SwiftUI

@main
struct VogonApp: App {
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(bluetoothManager)
        }
    }
}
