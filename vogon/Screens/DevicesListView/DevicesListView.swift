import CoreBluetooth
import SwiftUI

struct DevicesListView: View {
	@State private var navPath = NavigationPath()
	@EnvironmentObject var btm: BluetoothManager

	var body: some View {
		NavigationStack(path: $navPath) {
			FoundDevicesList()
				.onChange(of: btm.connectedPeripheral) { _, newPeripheral in
					if let peripheral = newPeripheral {
						navPath.append(peripheral)
					} else if !navPath.isEmpty {
						navPath.removeLast()
					}
				}
				.onChange(of: navPath) { _, newPath in
					if newPath.isEmpty && btm.connectedPeripheral != nil {
						btm.disconnect()
					}
				}
				.navigationDestination(for: CBPeripheral.self) { p in
					DeviceDetailView(peripheral: p)
				}
				.navigationTitle("🐸 Vogon")
		}
	}
}

struct FoundDevicesList: View {
	@EnvironmentObject var btm: BluetoothManager

	private func handleConnect(_ peripheral: CBPeripheral) {
		btm.connect(peripheral: peripheral)
	}

	var body: some View {
		List {
			Section(
				header: Text("Found devices"),
				footer: btm.scanning ? Text("Scanning...") : nil
			) {
				ForEach(btm.scannedPeripherals, id: \.peripheral.identifier) { p in
					let isConnecting = p.peripheral.identifier == btm.pendingPeripheral?.identifier

					FoundDeviceItem(
						peripheral: p.peripheral,
						isConnecting: isConnecting,
						handleConnect: { handleConnect(p.peripheral) }
					)
				}

				if btm.scannedPeripherals.isEmpty {
					Text("No devices found")
						.foregroundStyle(.secondary)
				}
			}
		}
	}
}

struct FoundDeviceItem: View {
	let peripheral: CBPeripheral
	let isConnecting: Bool
	let handleConnect: () -> Void

	var body: some View {
		let uuidShort = String(peripheral.identifier.uuidString.prefix(5))
		let peripheralLabel = peripheral.name ?? uuidShort

		Button {
			handleConnect()
		} label: {
			HStack {
				Text(peripheralLabel)
				Spacer()

				if isConnecting {
					ProgressView()
				}
			}
		}
		.foregroundStyle(Color.primary)
		.disabled(isConnecting)
	}
}
