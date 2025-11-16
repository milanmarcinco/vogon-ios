import CoreBluetooth
import SwiftUI

enum WifiProtocol: String, Codable {
  case open = "open"
  case wpa2 = "wpa2"
  case wpa2e = "wpa2e"  // enterprise
}

// Each field key is expected by the ESP32 firmware.
// Do not change them unless the firmware is updated accordingly.
struct Config: Codable {
  let wifi_ssid: String?
  let wifi_username: String?
  let wifi_password: String?
  let wifi_protocol: WifiProtocol?
  let mqtt_broker_url: String?
  let measurement_interval: Int?
  let environmental_bulk_size: Int?
  let environmental_bulk_sleep: Int?
  let particulate_warm_up: Int?
  let particulate_bulk_size: Int?
  let particulate_bulk_sleep: Int?
}

@Observable
final class ConfigManager {
  private let btm: BluetoothManager
  
  var initialized: Bool = false

  var wifiName: String = ""
  var wifiUsername: String = ""
  var wifiPassword: String = ""
  var wifiProtocol: WifiProtocol = .wpa2
  var mqttBrokerUrl: String = ""
  var measurementInterval: String = ""
  var environmentalBulkSize: String = ""
  var environmentalBulkSleep: String = ""
  var particulateWarmUp: String = ""
  var particulateBulkSize: String = ""
  var particulateBulkSleep: String = ""

  init(bluetoothManager: BluetoothManager) {
    self.btm = bluetoothManager
  }

  func loadConfiguration() async throws {
    let service = try await btm.discoverService(uuid: CONFIGURATION_SERVICE_UUID)
    let characteristic = try await btm.discoverCharacteristic(
      uuid: CONFIGURATION_CHARACTERISTIC_UUID,
      on: service
    )

    let data = try await btm.readValue(for: characteristic)
    let config = try JSONDecoder().decode(Config.self, from: data)

    self.wifiName = config.wifi_ssid ?? ""
    self.wifiUsername = config.wifi_username ?? ""
    self.wifiPassword = config.wifi_password ?? ""
    self.wifiProtocol = config.wifi_protocol ?? .wpa2
    self.mqttBrokerUrl = config.mqtt_broker_url ?? ""
    self.measurementInterval = config.measurement_interval.asString()
    self.environmentalBulkSize = config.environmental_bulk_size.asString()
    self.environmentalBulkSleep = config.environmental_bulk_sleep.asString()
    self.particulateWarmUp = config.particulate_warm_up.asString()
    self.particulateBulkSize = config.particulate_bulk_size.asString()
    self.particulateBulkSleep = config.particulate_bulk_sleep.asString()

    self.initialized = true
  }

  func writeConfiguration() async throws {
    let config = Config(
      wifi_ssid: self.wifiName,
      wifi_username: self.wifiUsername,
      wifi_password: self.wifiPassword,
      wifi_protocol: self.wifiProtocol,
      mqtt_broker_url: self.mqttBrokerUrl,
      measurement_interval: Int(self.measurementInterval),
      environmental_bulk_size: Int(self.environmentalBulkSize),
      environmental_bulk_sleep: Int(self.environmentalBulkSleep),
      particulate_warm_up: Int(self.particulateWarmUp),
      particulate_bulk_size: Int(self.particulateBulkSize),
      particulate_bulk_sleep: Int(self.particulateBulkSleep)
    )

    let encoder = JSONEncoder()
    let serializedConfig = try! encoder.encode(config)

    let service = try await btm.discoverService(uuid: CONFIGURATION_SERVICE_UUID)
    let characteristic = try await btm.discoverCharacteristic(
      uuid: CONFIGURATION_CHARACTERISTIC_UUID,
      on: service
    )

    try await btm.writeValue(for: characteristic, data: serializedConfig, timeout: 10)
  }

  func reboot() async throws {
    let service = try await btm.discoverService(uuid: CONFIGURATION_SERVICE_UUID)
    let characteristic = try await btm.discoverCharacteristic(
      uuid: RESTART_CHARACTERISTIC_UUID,
      on: service
    )

    try await btm.writeValue(for: characteristic, data: Data(), timeout: 10)
  }
}
