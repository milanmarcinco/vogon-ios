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
		values.forEach { key, field in
			var newData = Data()

			switch field.valueType {
				case .number:
					if let intValue = UInt16(field.value) {
						var littleEndian = intValue.littleEndian
						newData = withUnsafeBytes(of: &littleEndian) { bytes in
							Data(bytes)
						}
					}
				case .string:
					if let data = field.value.data(using: .utf8) {
						newData = data
					}
			}

			guard let c = btm.characteristics[key] else { return }

			if newData != c.value {
				btm.write(to: c, data: newData)
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
