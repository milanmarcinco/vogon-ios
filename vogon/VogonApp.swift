import SwiftUI

@main
struct VogonApp: App {
	@State private var bluetoothManager: BluetoothManager
	@State private var configManager: ConfigManager

	init() {
		let bluetoothManager = BluetoothManager()
		let configManager = ConfigManager(bluetoothManager: bluetoothManager)

		_bluetoothManager = State(wrappedValue: bluetoothManager)
		_configManager = State(wrappedValue: configManager)
	}

	var body: some Scene {
		WindowGroup {
			MainView()
				.environment(\.bluetoothManager, bluetoothManager)
				.environment(\.configManager, configManager)
		}
	}
}
