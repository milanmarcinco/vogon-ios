//
//  Helpers.swift
//  Vogon
//
//  Created by Milan Marcinčo on 27/07/2025.
//

import CoreBluetooth

func getCharacteristicValue(_ characteristic: CBCharacteristic) -> String {
	var value = "N/A"
	
	if let data = characteristic.value {
		if let stringValue = String(data: data, encoding: .utf8) {
			value = stringValue
		}
	}
	
	return value
}
