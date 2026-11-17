import SwiftUI

struct SettingsParticulate: View {
  @Environment(\.configManager) private var configManager

  var body: some View {
    @Bindable var cfg = configManager

    List {
      Section(
        footer: Text(
          "Amount of time in seconds the sensor needs to warm up before taking readings.")
      ) {
        ConfigField(
          name: "Warm up time",
          hint: nil,
          valueType: .number,
          value: $cfg.particulateWarmUp,
        )
      }

      Section(
        footer: Text("Number of readings to average for each sensor read.")
      ) {
        ConfigField(
          name: "Bulk size",
          hint: nil,
          valueType: .number,
          value: $cfg.particulateBulkSize,
        )
      }

      Section(
        footer: Text("Amount of time in seconds waiting between each reading in a bulk.")
      ) {
        ConfigField(
          name: "Bulk sleep",
          hint: "s",
          valueType: .number,
          value: $cfg.particulateBulkSleep,
        )
      }
    }
    .navigationTitle("💩 Particulate matter")
  }
}
