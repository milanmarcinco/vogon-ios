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
  @State private var errorMessage: String?

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

  private func run(_ keyPath: WritableKeyPath<PendingStates, Bool>, _ action: @escaping () async throws -> Void) {
    Task {
      pending[keyPath: keyPath] = true
      defer { pending[keyPath: keyPath] = false }

      do {
        try await action()
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }

  private func handleLoad() {
    run(\.load) { try await configManager.loadConfiguration() }
  }

  private func handleSave() {
    run(\.write) { try await configManager.writeConfiguration() }
  }

  private func handleDiscardAndReboot() {
    run(\.write) { try await configManager.reboot() }
  }

  private func handleSaveAndReboot() {
    run(\.write) {
      try await configManager.writeConfiguration()
      try await configManager.reboot()
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
          .disabled(pending.any || !configManager.isValid)
      } footer: {
        if !configManager.isValid {
          Text("Some settings have invalid values. Fix them before saving.")
            .foregroundStyle(.red)
        }
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
          .disabled(pending.any || !configManager.isValid)
      }
    }
    .alert(
      "Something went wrong",
      isPresented: Binding(
        get: { errorMessage != nil },
        set: { if !$0 { errorMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage ?? "")
    }
  }
}
