import CoreBluetooth
import SwiftUI

struct DeviceDetailView: View {
  let peripheral: CBPeripheral

  @Environment(\.bluetoothManager) var bluetoothManager
  @Environment(\.configManager) var configManager

  struct PendingStates {
    var load = false
    var write = false

    var any: Bool {
      return load || write
    }
  }

  @State private var pending = PendingStates()

  private func handleDisconnect() {
    bluetoothManager.disconnect()
  }

  private func handleAppear() {
    Task {
      if configManager.initialized { return }

      pending.load = true
      await configManager.initialize()
      pending.load = false
    }
  }

  private func handleLoad() {
    Task {
      pending.load = true
      try await configManager.loadConfiguration()
      pending.load = false
    }
  }

  private func handleSave() {
    Task {
      pending.write = true
      try await configManager.writeConfiguration()
      pending.write = false
    }
  }

  private func handleDiscardAndReboot() {
    Task {
      pending.write = true
      try await configManager.reboot()
      pending.write = false
    }
  }

  private func handleSaveAndReboot() {
    Task {
      pending.write = true
      try await configManager.writeConfiguration()
      try await configManager.reboot()
      pending.write = false
    }
  }

  var body: some View {
    List {
      DeviceStatusSection()

      Section(header: Text("Settings & configuration")) {
        NavigationLink("🛜 WiFi") { SettingsWifi() }
          .disabled(pending.load)
        NavigationLink("🔧 Advanced") { SettingsAdvanced() }
          .disabled(pending.load)
      }

      Section {
        Button("Discard and reboot", role: .destructive, action: handleDiscardAndReboot)
          .disabled(pending.any)

        Button("Discard changes", action: handleLoad)
          .disabled(pending.any)
      }

      Section {
        Button("Save & reboot", action: handleSaveAndReboot)
          .disabled(pending.any)
      }
    }
    .navigationBarBackButtonHidden(true)
    .navigationTitle("🐸 \(peripheral.name ?? "Unknown")")
    .onAppear { handleAppear() }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("Disconnect") { handleDisconnect() }
          .disabled(pending.any)
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button("Save") { handleSave() }
          .disabled(pending.any)
      }
    }
  }
}
