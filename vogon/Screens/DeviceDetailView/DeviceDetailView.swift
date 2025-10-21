import CoreBluetooth
import SwiftUI

struct DeviceDetailView: View {
	let peripheral: CBPeripheral

	@Environment(\.bluetoothManager) var bluetoothManager
	@Environment(\.configManager) var configManager

	@State var isReading: Bool = false
	@State var isWriting: Bool = false

	private func handleDisconnect() {
		bluetoothManager.disconnect()
	}

	private func handleAppear() {
		Task {
			isReading = true
			try await configManager.loadDefaults()
			isReading = false
		}
	}

	private func handleSave() {
		Task {
			isWriting = true
			try await configManager.writeConfiguration()
			isWriting = false
		}
	}

	var body: some View {
		List {
			Section(header: Text("Settings & configuration")) {
				NavigationLink("🛜 WiFi & Sync") { SettingsSync() }
					.disabled(isReading)
				NavigationLink("🔧 Advanced") { SettingsAdvanced() }
					.disabled(isReading)
			}
		}
		.navigationBarBackButtonHidden(true)
		.navigationTitle("🐸 \(peripheral.name ?? "Unknown")")
		.onAppear { handleAppear() }
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button("Disconnect") { handleDisconnect() }
					.disabled(isWriting)
			}

			ToolbarItem(placement: .topBarTrailing) {
				Button("Save") { handleSave() }
					.disabled(isWriting)
			}
		}
	}
}
