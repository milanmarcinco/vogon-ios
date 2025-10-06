import CoreBluetooth
import SwiftUI

struct ConfigurationField: View {
	let name: String
	let hint: String?
	let uuid: CBUUID
	let valueType: ConfigOptionValueType

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
		LabeledContent {
			if initialized {
				HStack(spacing: 0) {
					TextField("", text: $value)
					.labelsHidden()
					.multilineTextAlignment(.trailing)
					.foregroundStyle(.secondary)
					.keyboardType(keyboardType)

				if let hint {
					Text(hint)
						.foregroundStyle(.secondary)
				}
				}
			} else {
				ProgressView()
			}
		} label: {
			Text(name)
		}
		.onChange(of: characteristic) { initialize() }
		.onAppear { initialize() }
	}
}
