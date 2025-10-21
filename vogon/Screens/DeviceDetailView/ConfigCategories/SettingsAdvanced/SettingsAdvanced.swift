import SwiftUI

struct SettingsAdvanced: View {
  var body: some View {
    List {
      NavigationLink("⚙️ General") { SettingsGeneral() }
      NavigationLink("🥵 Temp & humidity") { SettingsEnvironmental() }
      NavigationLink("💩 Particulate matter") { SettingsParticulate() }
    }
    .navigationTitle("🔧 Advanced")
  }
}
