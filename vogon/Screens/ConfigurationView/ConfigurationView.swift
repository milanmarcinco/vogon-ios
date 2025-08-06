//
//  ConfigurationView.swift
//  Vogon
//
//  Created by Milan Marcinčo on 15/07/2025.
//

import SwiftUI
import CoreBluetooth

struct CharacteristicFieldValue {
	let value: String
	let valueType: CharacteristicValueType
}

struct ConfigurationView: View {
	let characteristicGroup: CharacteristicGroup
	
	@EnvironmentObject var btm: BluetoothManager
	@State private var values: [CBUUID: CharacteristicFieldValue] = [:]
	
	private func binding(for uuid: CBUUID, valueType: CharacteristicValueType) -> Binding<String> {
		Binding(
			get: {
				values[uuid]?.value ?? ""
			},
			set: { newValue in
				values[uuid] = CharacteristicFieldValue(value: newValue, valueType: valueType)
			}
		)
	}
	
	private func handleSave() {
		values.forEach { key, value in
			var newData = Data()
			
			switch value.valueType {
				case .number:
					if let intValue = UInt16(value.value) {
						var littleEndian = intValue.littleEndian
						newData = Data(
							bytes: &littleEndian,
							count: MemoryLayout<UInt16>.size
						)
					}
				case .string:
					newData = value.value.data(using: .utf8)!
			}
			
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
						valueType: field.valueType,
						value: binding(for: CBUUID(string: field.uuid), valueType: field.valueType)
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
