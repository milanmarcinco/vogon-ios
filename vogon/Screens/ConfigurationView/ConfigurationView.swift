import CoreBluetooth
import SwiftUI

struct CharacteristicFieldValue {
	let value: String
	let valueType: ConfigOptionValueType
}

struct ConfigurationView: View {
	let configCollection: ConfigCollection

	@EnvironmentObject var btm: BluetoothManager
	@State private var values: [CBUUID: CharacteristicFieldValue] = [:]

	private func binding(for uuid: CBUUID, valueType: ConfigOptionValueType) -> Binding<String> {
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
			ForEach(configCollection.sections, id: \.id) { section in
				Section(
					header: section.name != nil ? Text(section.name!) : nil,
					footer: section.description != nil ? Text(section.description!) : nil
				) {
					ForEach(section.options, id: \.uuid) { option in
						ConfigurationField(
							name: option.name,
							hint: option.hint,
							uuid: CBUUID(string: option.uuid),
							valueType: option.valueType,
							value: binding(for: CBUUID(string: option.uuid), valueType: option.valueType)
						)
					}
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Save") { handleSave() }
			}
		}
		.navigationTitle(configCollection.name)
	}
}
