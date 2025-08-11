import SwiftUI
import CoreBluetooth

struct CharacteristicField: View {
	let name: String
	let uuid: CBUUID
	let valueType: CharacteristicValueType
	
	@Binding var value: String

	@EnvironmentObject private var btm: BluetoothManager
	@State private var initialized = false
	
	private var keyboardType: UIKeyboardType {
		switch valueType {
			case .number:
				.numberPad
			default:
				.default
		}
	}
	
	private var characteristic: CBCharacteristic? {
		btm.characteristics[uuid]
	}
	
	private func initialize() {
		if let c = characteristic {
			value = getCharacteristicValue(c, as: valueType)
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
						.keyboardType(keyboardType)
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
