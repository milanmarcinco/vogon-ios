//
//  ConfigurationView.swift
//  Vogon
//
//  Created by Milan Marcinčo on 15/07/2025.
//

import SwiftUI
import CoreBluetooth

struct ConfigurationView: View {
	let characteristicGroup: CharacteristicGroup
	
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
	
	private func handleSave() {
		values.forEach { key, value in
			let newData = value.data(using: .utf8)!
			let c = btm.characteristics[key]!
			
			if newData != c.value {
				btm.write(data: newData, toCharacteristic: c)
			}
		}
	}
	
	var body: some View {
		List {
			Section(header: Text(characteristicGroup.name)) {
				ForEach(characteristicGroup.fields, id: \.uuid) { field in
					CharacteristicField(
						name: field.name,
						uuid: CBUUID(string: field.uuid),
						value: binding(for: CBUUID(string: field.uuid))
					)
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Save") { handleSave() }
			}
		}
		.navigationTitle("Configuration")
	}
}
