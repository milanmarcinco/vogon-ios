import CoreBluetooth
import SwiftUI

struct DevicesListView: View {
	@State private var navPath = NavigationPath()
	@Environment(\.bluetoothManager) var bluetoothManager

	var body: some View {
		NavigationStack(path: $navPath) {
			FoundDevicesList()
				.onChange(of: bluetoothManager.connectedPeripheral) { _, newPeripheral in
					if let peripheral = newPeripheral {
						navPath.append(peripheral)
					} else if !navPath.isEmpty {
						navPath.removeLast()
					}
				}
				.onChange(of: navPath) { _, newPath in
					if newPath.isEmpty && bluetoothManager.connectedPeripheral != nil {
						bluetoothManager.disconnect()
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
	@Environment(\.bluetoothManager) var bluetoothManager

	private func handleConnect(_ peripheral: CBPeripheral) {
		bluetoothManager.connect(peripheral: peripheral)
	}

	var body: some View {
		List {
			Section(
				header: Text("Found devices"),
				footer: bluetoothManager.scanning ? Text("Scanning...") : nil
			) {
				ForEach(bluetoothManager.scannedPeripherals, id: \.peripheral.identifier) { p in
					let isConnecting =
						p.peripheral.identifier == bluetoothManager.pendingPeripheral?.identifier

					FoundDeviceItem(
						peripheral: p.peripheral,
						isConnecting: isConnecting,
						handleConnect: { handleConnect(p.peripheral) }
					)
				}

				if bluetoothManager.scannedPeripherals.isEmpty {
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
