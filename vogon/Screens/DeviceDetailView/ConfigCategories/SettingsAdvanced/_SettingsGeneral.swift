import SwiftUI

struct SettingsGeneral: View {
  @Environment(\.configManager) private var configManager

  var body: some View {
    @Bindable var cfg = configManager

    List {
      Section(
        footer: Text("Amount of time asleep in minutes between sensor reads.")
      ) {
        ConfigField(
          name: "Read interval",
          hint: "m",
          valueType: .number,
          value: $cfg.samplingInterval,
        )
      }
    }
    .navigationTitle("⚙️ General")
  }
}
