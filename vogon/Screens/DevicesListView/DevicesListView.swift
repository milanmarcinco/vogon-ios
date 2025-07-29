//
//  DevicesListView.swift
//  Vogon
//
//  Created by Milan Marcinčo on 23/07/2025.
//


import SwiftUI
import CoreBluetooth

struct DevicesListView: View {
	@State private var navPath = NavigationPath()
	@EnvironmentObject var btm: BluetoothManager
	
	private func handleConnect(_ peripheral: CBPeripheral) {
		btm.connect(peripheral: peripheral)
	}
	
	var body: some View {
		NavigationStack(path: $navPath) {
			List {
				Section(
					header: Text("Found devices"),
					footer: btm.scanning ? Text("Scanning...") : nil
				) {
					ForEach(btm.scannedPeripherals, id: \.identifier) { peripheral in
						let uuidShort = String(peripheral.identifier.uuidString.prefix(5))
						let peripheralLabel = "\(peripheral.name ?? uuidShort)"
						
						let isConnecting = peripheral == btm.pendingPeripheral
						
						Button { handleConnect(peripheral) } label: {
							HStack() {
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
					
					if btm.scannedPeripherals.isEmpty {
						Text("No devices found")
							.foregroundStyle(.secondary)
					}
				}
			}
			.onChange(of: btm.connectedPeripheral) { _, newValue in
				if let peripheral = newValue {
					navPath.append(peripheral)
				} else {
					navPath.removeLast()
				}
			}
			.navigationDestination(for: CBPeripheral.self) { p in
				ConfigurationView(peripheral: p)
			}
			.navigationTitle("🐸 Vogon")
		}
	}
}
