import CoreBluetooth
import SwiftUI

struct ConfigField: View {
  enum ValueType {
    case string
    case number
  }

  let name: String
  let hint: String?
  let valueType: ValueType
  @Binding var value: String

  private var keyboardType: UIKeyboardType {
    switch valueType {
    case .number:
      .numberPad
    default:
      .default
    }
  }

  var textField: some View {
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
  }

  var body: some View {
    LabeledContent {
      textField
    } label: {
      Text(name)
    }
  }
}
