import SwiftUI
import Toasts

@main
struct VogonApp: App {
  @State private var authManager: AuthManager
  @State private var bluetoothManager: BluetoothManager
  @State private var configManager: ConfigManager

  init() {
    let authManager = AuthManager()
    let bluetoothManager = BluetoothManager()
    let configManager = ConfigManager(bluetoothManager: bluetoothManager)

    _authManager = State(wrappedValue: authManager)
    _bluetoothManager = State(wrappedValue: bluetoothManager)
    _configManager = State(wrappedValue: configManager)
  }

  var body: some Scene {
    WindowGroup {
      MainView()
        .environment(\.authManager, authManager)
        .environment(\.bluetoothManager, bluetoothManager)
        .environment(\.configManager, configManager)
        .installToast(position: .top)
    }
  }
}
