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

// Firmware defaults and valid ranges for the SCD41 CO2 sensor keys.
// The firmware validates them only on boot; an invalid value sends the
// device back into BLE setup mode, so the app must validate before writing.
enum CO2Settings {
  static let defaultAltitude = 0
  static let defaultBulkSize = 3
  static let defaultBulkSleep = 5

  static let altitudeRange = 0...3000
  static let minBulkSize = 1
  static let minBulkSleep = 1
}

enum ConfigError: LocalizedError {
  case notLoaded
  case invalid
  case tooLarge(size: Int, limit: Int)

  var errorDescription: String? {
    switch self {
    case .notLoaded:
      "The current configuration could not be read from the device. Reload it before saving."
    case .invalid:
      "Some settings have invalid values."
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
  var co2Altitude: String = String(CO2Settings.defaultAltitude)
  var co2BulkSize: String = String(CO2Settings.defaultBulkSize)
  var co2BulkSleep: String = String(CO2Settings.defaultBulkSleep)

  // The config object as last read from the device. Writes are merged into it,
  // because a write replaces the whole stored config and unknown keys would be lost.
  private var rawConfig: [String: Any]?

  var co2AltitudeError: String? {
    Self.validate(
      co2Altitude,
      min: CO2Settings.altitudeRange.lowerBound,
      max: CO2Settings.altitudeRange.upperBound
    )
  }

  var co2BulkSizeError: String? {
    Self.validate(co2BulkSize, min: CO2Settings.minBulkSize)
  }

  var co2BulkSleepError: String? {
    Self.validate(co2BulkSleep, min: CO2Settings.minBulkSleep)
  }

  var isValid: Bool {
    co2AltitudeError == nil && co2BulkSizeError == nil && co2BulkSleepError == nil
  }

  private static func validate(_ value: String, min: Int, max: Int? = nil) -> String? {
    guard let number = Int(value), number >= min, number <= (max ?? Int(Int32.max)) else {
      if let max {
        return String(localized: "Enter a whole number from \(min) to \(max).")
      }
      return String(localized: "Enter a whole number of at least \(min).")
    }
    return nil
  }

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
    let rawConfig = try JSONSerialization.jsonObject(with: data) as? [String: Any]

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
    self.co2Altitude = config.co2_altitude.asString(String(CO2Settings.defaultAltitude))
    self.co2BulkSize = config.co2_bulk_size.asString(String(CO2Settings.defaultBulkSize))
    self.co2BulkSleep = config.co2_bulk_sleep.asString(String(CO2Settings.defaultBulkSleep))
    self.rawConfig = rawConfig
  }

  // Merges the edited values into the config last read from the device.
  // Integers are written as JSON numbers; the firmware ignores strings.
  // An empty integer field removes its key, so the firmware uses its default.
  func serializeConfiguration() throws -> Data {
    guard var json = rawConfig else { throw ConfigError.notLoaded }
    guard isValid else { throw ConfigError.invalid }

    json["wifi_ssid"] = wifiName
    json["wifi_username"] = wifiUsername
    json["wifi_password"] = wifiPassword
    json["wifi_protocol"] = wifiProtocol.rawValue
    json["mqtt_broker_url"] = mqttBrokerUrl
    json["measurement_interval"] = Int(measurementInterval)
    json["environmental_bulk_size"] = Int(environmentalBulkSize)
    json["environmental_bulk_sleep"] = Int(environmentalBulkSleep)
    json["particulate_warm_up"] = Int(particulateWarmUp)
    json["particulate_bulk_size"] = Int(particulateBulkSize)
    json["particulate_bulk_sleep"] = Int(particulateBulkSleep)
    json["co2_altitude"] = Int(co2Altitude)
    json["co2_bulk_size"] = Int(co2BulkSize)
    json["co2_bulk_sleep"] = Int(co2BulkSleep)

    // Compact output (no whitespace, no escaped slashes) to fit in one ATT write.
    return try JSONSerialization.data(
      withJSONObject: json,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  }

  func writeConfiguration() async throws {
    let serializedConfig = try serializeConfiguration()

    // The firmware rejects long (prepared) writes, so the config must fit in
    // a single ATT write: the negotiated MTU minus 3 bytes.
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
