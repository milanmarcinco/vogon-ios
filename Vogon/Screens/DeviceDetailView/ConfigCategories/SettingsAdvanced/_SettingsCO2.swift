import SwiftUI

struct SettingsCO2: View {
  @Environment(\.configManager) private var configManager

  @State private var locating = false
  @State private var locationError: String?

  private func handleUseCurrentAltitude() {
    Task {
      locating = true
      defer { locating = false }

      do {
        let altitude = try await AltitudeProvider.currentAltitude()
        let range = CO2Settings.altitudeRange
        configManager.co2Altitude = String(min(max(altitude, range.lowerBound), range.upperBound))
      } catch {
        locationError = error.localizedDescription
      }
    }
  }

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

        Button(action: handleUseCurrentAltitude) {
          HStack {
            Text("Use current altitude")
            if locating {
              Spacer()
              ProgressView()
            }
          }
        }
        .disabled(locating)
      } footer: {
        VStack(alignment: .leading, spacing: 4) {
          if let error = cfg.co2AltitudeError {
            Text(error).foregroundStyle(.red)
          }
          Text(
            "Height of the device above sea level in metres (0–3000). The sensor uses it to correct its CO2 reading, so set the real elevation. Takes effect after a reboot."
          )
        }
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
        VStack(alignment: .leading, spacing: 4) {
          if let error = cfg.co2BulkSizeError {
            Text(error).foregroundStyle(.red)
          }
          Text("Number of readings to average for each sensor read.")
        }
      }

      Section {
        ConfigField(
          name: "Bulk sleep",
          hint: "s",
          valueType: .number,
          value: $cfg.co2BulkSleep,
        )
      } footer: {
        VStack(alignment: .leading, spacing: 4) {
          if let error = cfg.co2BulkSleepError {
            Text(error).foregroundStyle(.red)
          }
          Text("Amount of time in seconds waiting between each reading in a bulk.")
        }
      }
    }
    .navigationTitle("🌫️ CO2")
    .alert(
      "Altitude unavailable",
      isPresented: Binding(
        get: { locationError != nil },
        set: { if !$0 { locationError = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(locationError ?? "")
    }
  }
}
