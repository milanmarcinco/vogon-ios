import SwiftUI

struct SettingsSync: View {
  @Environment(\.configManager) private var configManager

  var body: some View {
    @Bindable var cfg = configManager

    List {
      Section(
        header: Text("MQTT Broker URL"),
        footer: Text("The URL of the MQTT broker to send data to.")
      ) {
        TextField(
          "mqtts://broker.example.com:8883",
          text: $cfg.mqttBrokerUrl
        )
      }
    }
    .navigationTitle("🔁 Sync")
  }
}
