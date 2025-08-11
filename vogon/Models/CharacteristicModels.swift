import Foundation

enum CharacteristicValueType {
	case number
	case string
}

struct CharacteristicGroup {
	let name: String
	let fields: [CharacteristicDetail]
}

struct CharacteristicDetail {
	let name: String
	let uuid: String
	let valueType: CharacteristicValueType
}

let characteristicGroups: [CharacteristicGroup] = [
	CharacteristicGroup(
		name: "General",
		fields: [
			CharacteristicDetail(name: "Read interval", uuid: "0101", valueType: .number),
		]
	),
	
	CharacteristicGroup(
		name: "Temperature & humidity sensor",
		fields: [
			CharacteristicDetail(name: "Bulk size", uuid: "0201", valueType: .number),
			CharacteristicDetail(name: "Bulk sleep", uuid: "0202", valueType: .number),
		]
	),
	
	CharacteristicGroup(
		name: "Particle sensor",
		fields: [
			CharacteristicDetail(name: "Warm up time", uuid: "0203", valueType: .number),
			CharacteristicDetail(name: "Bulk size", uuid: "0204", valueType: .number),
			CharacteristicDetail(name: "Bulk sleep", uuid: "0205", valueType: .number),
		]
	),
	
	CharacteristicGroup(
		name: "Synchronization",
		fields: [
			CharacteristicDetail(name: "WiFi name", uuid: "0701", valueType: .string),
			CharacteristicDetail(name: "WiFi password", uuid: "0702", valueType: .string),
			CharacteristicDetail(name: "MQTT broker URL", uuid: "0703", valueType: .string),
		]
	),
]
