import Alamofire
import CoreBluetooth
import SwiftUI

enum WifiProtocol: String, Codable {
  case open = "open"
  case wpa2 = "wpa2"
  case wpa2e = "wpa2e"  // enterprise
}

enum DeviceStatus {
  case unknown
  case pending
  case registered
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
  let co2_altitude: Int?
  let co2_bulk_size: Int?
  let co2_bulk_sleep: Int?
}

enum ConfigError: LocalizedError {
  case tooLarge(size: Int, limit: Int)

  var errorDescription: String? {
    switch self {
    case .tooLarge(let size, let limit):
      "The configuration is too large (\(size) bytes, the limit is \(limit) bytes). Shorten the WiFi or MQTT settings."
    }
  }
}

@Observable
final class ConfigManager {
  private let authManager: AuthManager
  private let bluetoothManager: BluetoothManager

  var initialized: Bool = false
  private(set) var status: DeviceStatus = .unknown

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
  var co2Altitude: String = ""
  var co2BulkSize: String = ""
  var co2BulkSleep: String = ""

  init(
    authManager: AuthManager,
    bluetoothManager: BluetoothManager
  ) {
    self.authManager = authManager
    self.bluetoothManager = bluetoothManager
  }

  func fetchDeviceStatus() async {
    if authManager.status != .authenticated {
      status = .unknown
      return
    }

    status = .pending
    var macAddress: String?

    do {
      let service = try await bluetoothManager.discoverService(uuid: CONFIGURATION_SERVICE_UUID)
      let characteristic = try await bluetoothManager.discoverCharacteristic(
        uuid: MAC_ADDRESS_CHARACTERISTIC_UUID,
        on: service
      )

      let data = try await bluetoothManager.readValue(for: characteristic)
      macAddress = String(data: data, encoding: .utf8)
    } catch {
      status = .unknown
      return
    }

    guard let macAddress else {
      status = .unknown
      return
    }

    let headers: HTTPHeaders = [.authorization(bearerToken: authManager.token!)]

    let parameters: [String: String] = [
      "macAddress": macAddress
    ]

    let response = await AF.request(
      ApiRoutes.devices,
      method: .post,
      parameters: parameters,
      headers: headers
    )
    .serializingData()
    .response

    if let status = response.response?.statusCode {
      switch status {
      case 200..<300:
        self.status = .registered
      default:
        self.status = .unknown
      }
    }
  }

  func initialize() async {
    if initialized { return }
    try? await loadConfiguration()
    self.initialized = true
  }

  func loadConfiguration() async throws {
    let service = try await bluetoothManager.discoverService(uuid: CONFIGURATION_SERVICE_UUID)
    let characteristic = try await bluetoothManager.discoverCharacteristic(
      uuid: CONFIGURATION_CHARACTERISTIC_UUID,
      on: service
    )

    let data = try await bluetoothManager.readValue(for: characteristic)
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
    self.co2Altitude = config.co2_altitude.asString()
    self.co2BulkSize = config.co2_bulk_size.asString()
    self.co2BulkSleep = config.co2_bulk_sleep.asString()
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
      particulate_bulk_sleep: Int(self.particulateBulkSleep),
      co2_altitude: Int(self.co2Altitude),
      co2_bulk_size: Int(self.co2BulkSize),
      co2_bulk_sleep: Int(self.co2BulkSleep)
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = .withoutEscapingSlashes
    let serializedConfig = try! encoder.encode(config)

    // The firmware rejects long (prepared) writes.
    if let limit = bluetoothManager.maximumSingleWriteLength, serializedConfig.count > limit {
      throw ConfigError.tooLarge(size: serializedConfig.count, limit: limit)
    }

    let service = try await bluetoothManager.discoverService(uuid: CONFIGURATION_SERVICE_UUID)
    let characteristic = try await bluetoothManager.discoverCharacteristic(
      uuid: CONFIGURATION_CHARACTERISTIC_UUID,
      on: service
    )

    try await bluetoothManager.writeValue(for: characteristic, data: serializedConfig, timeout: 10)
  }

  func reboot() async throws {
    let service = try await bluetoothManager.discoverService(uuid: CONFIGURATION_SERVICE_UUID)
    let characteristic = try await bluetoothManager.discoverCharacteristic(
      uuid: RESTART_CHARACTERISTIC_UUID,
      on: service
    )

    try await bluetoothManager.writeValue(for: characteristic, data: Data(), timeout: 10)
  }
}
