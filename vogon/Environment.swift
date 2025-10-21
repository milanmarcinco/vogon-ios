import Foundation
import SwiftUI

private struct BluetoothManagerKey: EnvironmentKey {
  static let defaultValue = BluetoothManager()
}

private struct ConfigManagerKey: EnvironmentKey {
  static let defaultValue = ConfigManager(
    bluetoothManager: BluetoothManager()
  )
}

extension EnvironmentValues {
  var bluetoothManager: BluetoothManager {
    get { self[BluetoothManagerKey.self] }
    set { self[BluetoothManagerKey.self] = newValue }
  }

  var configManager: ConfigManager {
    get { self[ConfigManagerKey.self] }
    set { self[ConfigManagerKey.self] = newValue }
  }
}
