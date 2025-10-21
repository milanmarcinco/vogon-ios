import Observation
import SwiftUI

struct SettingsSync: View {
  @Environment(\.configManager) private var configManager

  var body: some View {
    @Bindable var cfg = configManager

    List {
      Section {
        Picker("WiFi Security", selection: $cfg.wifiProtocol) {
          Text("Open").tag(WifiProtocol.open)
          Text("WPA2 Personal").tag(WifiProtocol.wpa2)
          Text("WPA2 Enterprise").tag(WifiProtocol.wpa2e)
        }

        ConfigField(
          name: "WiFi name",
          hint: nil,
          valueType: .string,
          value: $cfg.wifiName
        )

        if cfg.wifiProtocol == .wpa2 {
          ConfigField(
            name: "WiFi password",
            hint: nil,
            valueType: .string,
            value: $cfg.wifiPassword
          )
        }

        if cfg.wifiProtocol == .wpa2e {
          ConfigField(
            name: "Username",
            hint: nil,
            valueType: .string,
            value: $cfg.wifiUsername
          )

          ConfigField(
            name: "Password",
            hint: nil,
            valueType: .string,
            value: $cfg.wifiPassword
          )
        }
      }

      Section(footer: Text("The URL of the MQTT broker to send data to.")) {
        ConfigField(
          name: "MQTT broker URL",
          hint: nil,
          valueType: .string,
          value: $cfg.mqttBrokerUrl,
        )
      }
    }
    .navigationTitle("🛜 WiFi & Sync")
  }
}
