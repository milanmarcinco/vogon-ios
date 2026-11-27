import SwiftUI

struct SettingsCO2: View {
  @Environment(\.configManager) private var configManager

  var body: some View {
    @Bindable var cfg = configManager

    List {
      Section {
        ConfigField(
          name: "Altitude",
          hint: "m",
          valueType: .number,
          value: $cfg.co2Altitude,
        )
      } footer: {
        Text(
          "Height of the device above sea level in metres (0–3000). The sensor uses it to correct its CO2 reading, so set the real elevation. Takes effect after a reboot."
        )
      }

      Section {
        ConfigField(
          name: "Bulk size",
          hint: nil,
          valueType: .number,
          value: $cfg.co2BulkSize,
        )
      } header: {
        Text("Advanced")
      } footer: {
        Text("Number of readings to average for each sensor read.")
      }

      Section {
        ConfigField(
          name: "Bulk sleep",
          hint: "s",
          valueType: .number,
          value: $cfg.co2BulkSleep,
        )
      } footer: {
        Text("Amount of time in seconds waiting between each reading in a bulk.")
      }
    }
    .navigationTitle("🌫️ CO2")
  }
}
