//
//  CharacteristicField.swift
//  Vogon
//
//  Created by Milan Marcinčo on 31/07/2025.
//

import SwiftUI
import CoreBluetooth

struct CharacteristicGroup {
	let name: String
	let fields: [CharacteristicDetail]
}

struct CharacteristicDetail {
	let name: String
	let uuid: String
}

let characteristicGroups: [CharacteristicGroup] = [
	CharacteristicGroup(
		name: "General",
		fields: [
			CharacteristicDetail(name: "Read interval", uuid: "0101"),
		]
	),
	
	CharacteristicGroup(
		name: "Temperature & humidity sensor",
		fields: [
			CharacteristicDetail(name: "Bulk size", uuid: "0201"),
			CharacteristicDetail(name: "Bulk sleep", uuid: "0202"),
		]
	),
	
	CharacteristicGroup(
		name: "Particle sensor",
		fields: [
			CharacteristicDetail(name: "Warm up time", uuid: "0203"),
			CharacteristicDetail(name: "Bulk size", uuid: "0204"),
			CharacteristicDetail(name: "Bulk sleep", uuid: "0205"),
		]
	),
	
	CharacteristicGroup(
		name: "Synchronization",
		fields: [
			CharacteristicDetail(name: "WiFi name", uuid: "0701"),
			CharacteristicDetail(name: "WiFi password", uuid: "0702"),
			CharacteristicDetail(name: "MQTT broker URL", uuid: "0703"),
		]
	),
]

struct CharacteristicField: View {
	let name: String
	let uuid: CBUUID
	@Binding var value: String
	
	@EnvironmentObject private var btm: BluetoothManager
	
	@State private var initialized = false
	
	private var characteristic: CBCharacteristic? {
		btm.characteristics[uuid]
	}
	
	private func initialize() {
		if let c = characteristic {
			value = getCharacteristicValue(c)
			initialized = true
		} else {
			value = ""
			initialized = false
		}
	}
	
	var body: some View {
		Group {
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
		}
		.onChange(of: characteristic) { initialize() }
		.onAppear { initialize() }
	}
}
