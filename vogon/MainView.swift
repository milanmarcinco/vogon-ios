import CoreBluetooth
import SwiftUI

struct MainView: View {
  @Environment(\.authManager) private var authManager

  private func initializeAuth() {
    Task { await authManager.initialize() }
  }

  var body: some View {
    TabView {
      Tab("Configure", systemImage: "memorychip") {
        DevicesListView()
      }

      Tab("Account", systemImage: "person.crop.circle") {
        AccountView()
      }
    }
    .onAppear { initializeAuth() }
  }
}
