//
//  Helpers.swift
//  Vogon
//
//  Created by Milan Marcinčo on 27/07/2025.
//

import CoreBluetooth

func getCharacteristicName(_ characteristic: CBCharacteristic) -> String {
	let descriptionDescriptor = characteristic.descriptors?.first(where: { descriptor in
		descriptor.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString
	})
	
	var name = String(characteristic.uuid.uuidString.prefix(5))
	
	if let dd = descriptionDescriptor {
		if let data = dd.value as? String {
			name = data
		}
	}
	
	return name
}

func getCharacteristicValue(_ characteristic: CBCharacteristic) -> String {
	var value = "N/A"
	
	if let data = characteristic.value {
		if let stringValue = String(data: data, encoding: .utf8) {
			value = stringValue
		}
	}
	
	return value
}
