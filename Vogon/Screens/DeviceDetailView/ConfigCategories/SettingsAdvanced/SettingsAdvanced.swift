import SwiftUI

struct SettingsAdvanced: View {
  var body: some View {
    List {
      NavigationLink("⚙️ General") { SettingsGeneral() }
      NavigationLink("🥵 Temp & humidity") { SettingsEnvironmental() }
      NavigationLink("💩 Particulate matter") { SettingsParticulate() }
      NavigationLink("🌫️ CO2") { SettingsCO2() }
      NavigationLink("🔁 Sync") { SettingsSync() }
    }
    .navigationTitle("🔧 Advanced")
  }
}
