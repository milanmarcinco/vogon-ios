import Foundation
import CoreBluetooth

func getCharacteristicValue(_ characteristic: CBCharacteristic, as type: CharacteristicValueType) -> String {
	var value = "N/A"
	
	if let data = characteristic.value {
		switch type {
			case .number:
				let number = data.withUnsafeBytes { bytes in bytes.load(as: UInt16.self) }
				value = String(format: "%u", number)
			default:
				if let stringValue = String(data: data, encoding: .utf8) {
					value = stringValue
				}
		}
	}
	
	return value
}
