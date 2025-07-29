//
//  ConfigurationView.swift
//  Vogon
//
//  Created by Milan Marcinčo on 15/07/2025.
//

import SwiftUI
import CoreBluetooth

let CONFIGURATION_CHARACTERISTIC_UUID = CBUUID(string: "01FF")

struct ConfigurationView: View {
	let peripheral: CBPeripheral
	
	@EnvironmentObject var btm: BluetoothManager
	@State private var values: [CBUUID: String] = [:]
	
	private func binding(for uuid: CBUUID) -> Binding<String> {
		Binding(
			get: { values[uuid] ?? "" },
			set: { newValue in
				values[uuid] = newValue
			}
		)
	}
	
	private func handleDisconnect() {
		btm.disconnect()
	}
	
	private func handleSave() {
		let data = values[CONFIGURATION_CHARACTERISTIC_UUID]?.data(using: .utf8)
		
		btm.write(
			data: data!,
			toCharacteristic: btm.characteristics[CONFIGURATION_CHARACTERISTIC_UUID]!
		)
	}
	
	var body: some View {
		List {
			CharacteristicField(
				uuid: CONFIGURATION_CHARACTERISTIC_UUID,
				value: binding(for: CONFIGURATION_CHARACTERISTIC_UUID)
			)
		}
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button("Disconnect") { handleDisconnect() }
			}
			
			ToolbarItem(placement: .topBarTrailing) {
				Button("Save") { handleSave() }
			}
		}
		.navigationTitle(peripheral.name ?? "Unknown")
		.navigationBarTitleDisplayMode(.large)
	}
}

struct CharacteristicField: View {
	let uuid: CBUUID
	
	@Binding var value: String
	
	@EnvironmentObject private var btm: BluetoothManager
	
	@State private var characteristic: CBCharacteristic?
	@State private var initialized = false
	
	var body: some View {
		Group {
			if let c = characteristic {
				let name = getCharacteristicName(c)
				
				LabeledContent {
					if initialized {
						TextField("", text: $value)
							.labelsHidden()
							.multilineTextAlignment(.trailing)
							.foregroundStyle(.secondary)
					} else {
						ProgressView()
					}
				} label: {
					Text(name)
				}
			} else {
				ProgressView()
			}
		}
		.onChange(of: btm.characteristics) { _, newValue in
			characteristic = btm.characteristics[uuid]
		}
		.onChange(of: characteristic) { _, newValue in
			guard let c = newValue else { return }
			
			if !initialized {
				value = getCharacteristicValue(c)
				initialized = true
			}
		}
	}
}
