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
				ForEach(characteristicGroups, id: \.name) { group in
					NavigationLink(group.name) {
						ConfigurationView(characteristicGroup: group)
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
