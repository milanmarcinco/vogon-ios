import Foundation
import SwiftUI

private struct AuthManagerKey: EnvironmentKey {
  static let defaultValue = AuthManager()
}

private struct BluetoothManagerKey: EnvironmentKey {
  static let defaultValue = BluetoothManager()
}

private struct ConfigManagerKey: EnvironmentKey {
  static let defaultValue = ConfigManager(
    bluetoothManager: BluetoothManager()
  )
}

extension EnvironmentValues {
  var authManager: AuthManager {
    get { self[AuthManagerKey.self] }
    set { self[AuthManagerKey.self] = newValue }
  }
  
  var bluetoothManager: BluetoothManager {
    get { self[BluetoothManagerKey.self] }
    set { self[BluetoothManagerKey.self] = newValue }
  }

  var configManager: ConfigManager {
    get { self[ConfigManagerKey.self] }
    set { self[ConfigManagerKey.self] = newValue }
  }
}
