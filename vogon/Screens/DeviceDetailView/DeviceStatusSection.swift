import SwiftUI

struct DeviceStatusSection: View {
  @Environment(\.authManager) private var authManager
  @Environment(\.configManager) private var configManager

  private func updateStatus() {
    Task { await configManager.fetchDeviceStatus() }
  }

  @ViewBuilder
  var statusText: some View {
    if authManager.status != .authenticated {
      Text("Unknown")
    } else {
      switch configManager.status {
      case .unknown:
        Text("Unknown")
      case .pending:
        ProgressView()
      case .registered:
        Text("Registered ✅")
      }
    }
  }

  var body: some View {
    Section(
      header: Text("Device status")
    ) {
      LabeledContent {
        statusText
      } label: {
        Text("Status")
      }
    }
    .onChange(of: authManager.status) {
      updateStatus()
    }
    .onAppear {
      updateStatus()
    }
  }
}
