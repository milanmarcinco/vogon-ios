import CoreBluetooth
import SwiftUI

struct DeviceDetailView: View {
	let peripheral: CBPeripheral

	@EnvironmentObject var btm: BluetoothManager

	private func handleDisconnect() {
		btm.disconnect()
	}

	var body: some View {
		List {
			Section(header: Text("Settings & configuration")) {
				ForEach(config, id: \.name) { collection in
					NavigationLink(collection.name) {
						ConfigurationView(
							configCollection: collection
						)
					}
				}
			}
		}
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button("Disconnect") { handleDisconnect() }
			}
		}
		.navigationTitle("🐸 \(peripheral.name ?? "Unknown")")
	}
}
