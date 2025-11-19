import CoreBluetooth
import SwiftUI

let CONFIGURATION_SERVICE_UUID = CBUUID(string: "d0a823a6-fa98-4597-b0c1-d8577be0e158")

let CONFIGURATION_CHARACTERISTIC_UUID = CBUUID(string: "0101")
let MAC_ADDRESS_CHARACTERISTIC_UUID = CBUUID(string: "0201")
let RESTART_CHARACTERISTIC_UUID = CBUUID(string: "0301")

enum BluetoothError: Error {
  case internalError
}

struct ScannedPeripheral {
  let peripheral: CBPeripheral
  var rssi: NSNumber
  var lastAdvertisedAt: Date
}

final class ContinuationMap<Value> {
  private var storage: [CBUUID: CheckedContinuation<Value, Error>] = [:]
  private let queue = DispatchQueue(label: "ContinuationMap.queue.\(Value.self)")

  func set(_ uuid: CBUUID, _ continuation: CheckedContinuation<Value, Error>) {
    queue.sync {
      storage[uuid] = continuation
    }
  }

  func peek(_ uuid: CBUUID) -> CheckedContinuation<Value, Error>? {
    queue.sync {
      storage[uuid]
    }
  }

  func take(_ uuid: CBUUID) -> CheckedContinuation<Value, Error>? {
    queue.sync {
      storage.removeValue(forKey: uuid)
    }
  }

  func removeAll() {
    queue.sync {
      storage.removeAll()
    }
  }

  func drainAll() -> [CBUUID: CheckedContinuation<Value, Error>] {
    queue.sync {
      let result = storage
      storage.removeAll()
      return result
    }
  }
}

final class TaskMap<Value> {
  private var storage: [CBUUID: Task<Value, Error>] = [:]
  private let queue = DispatchQueue(label: "TaskMap.queue.\(Value.self)")

  func set(_ uuid: CBUUID, task: Task<Value, Error>) {
    queue.sync {
      storage[uuid] = task
    }
  }

  func peek(_ uuid: CBUUID) -> Task<Value, Error>? {
    queue.sync {
      storage[uuid]
    }
  }

  func take(_ uuid: CBUUID) -> Task<Value, Error>? {
    queue.sync {
      storage.removeValue(forKey: uuid)
    }
  }

  func removeAll() {
    queue.sync {
      storage.removeAll()
    }
  }

  func drainAll() -> [CBUUID: Task<Value, Error>] {
    queue.sync {
      let result = storage
      storage.removeAll()
      return result
    }
  }
}

final class ContinuationStore {
  let services = ContinuationMap<CBService>()
  let characteristics = ContinuationMap<CBCharacteristic>()
  let reads = ContinuationMap<Data>()
  let writes = ContinuationMap<Void>()

  let serviceTasks = TaskMap<CBService>()
  let characteristicTasks = TaskMap<CBCharacteristic>()
}

@Observable
final class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  private var centralManager: CBCentralManager!

  private(set) var state: CBManagerState = .unknown
  private(set) var scanning: Bool = false
  private(set) var scannedPeripherals: [ScannedPeripheral] = []

  private(set) var pendingPeripheral: CBPeripheral?
  private(set) var connectedPeripheral: CBPeripheral?

  private let continuationStore = ContinuationStore()
  private var cleanupTimer: Timer?

  override init() {
    super.init()
    self.centralManager = CBCentralManager(delegate: self, queue: nil)

    cleanupTimer = Timer.scheduledTimer(
      withTimeInterval: 1,
      repeats: true
    ) { [weak self] _ in
      self?.removeStalePeripherals()
    }
  }

  deinit {
    cleanupTimer?.invalidate()
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    self.state = central.state

    if central.state == .poweredOn {
      self.scan()
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi: NSNumber
  ) {
    let alreadyScannedIndex = self.scannedPeripherals.firstIndex(where: { p in
      p.peripheral.identifier == peripheral.identifier
    })

    let p = ScannedPeripheral(
      peripheral: peripheral,
      rssi: rssi,
      lastAdvertisedAt: Date()
    )

    if let alreadyScannedIndex {
      self.scannedPeripherals[alreadyScannedIndex] = p
    } else {
      self.scannedPeripherals.append(p)
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    self.stopScan()
    peripheral.delegate = self

    self.pendingPeripheral = nil
    self.connectedPeripheral = peripheral
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: (any Error)?
  ) {
    if let error = error {
      print("Error connecting: \(error.localizedDescription)")
    }

    if self.pendingPeripheral == peripheral {
      self.pendingPeripheral = nil
    }

    if self.connectedPeripheral == peripheral {
      self.connectedPeripheral = nil
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: (any Error)?
  ) {
    if let error = error {
      print("Error disconnecting: \(error.localizedDescription)")
    }

    if self.pendingPeripheral == peripheral {
      self.pendingPeripheral = nil
    }

    if self.connectedPeripheral == peripheral {
      self.connectedPeripheral = nil
    }

    self.scan()
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
    if let error = error {
      // Resume all pending service continuations with error and clear tasks.
      let continuations = continuationStore.services.drainAll()
      continuationStore.serviceTasks.removeAll()

      for (_, cont) in continuations {
        cont.resume(throwing: error)
      }

      return
    }

    guard let services = peripheral.services else { return }

    for service in services {
      if let continuation = continuationStore.services.take(service.uuid) {
        continuation.resume(returning: service)
      }
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: (any Error)?
  ) {
    if let error = error {
      // Resume all pending characteristic continuations with error and clear tasks.
      let continuations = continuationStore.characteristics.drainAll()
      continuationStore.characteristicTasks.removeAll()

      for (_, continuation) in continuations {
        continuation.resume(throwing: error)
      }

      return
    }

    guard let characteristics = service.characteristics else { return }

    for characteristic in characteristics {
      if let continuation =
        continuationStore.characteristics.take(characteristic.uuid)
      {
        continuation.resume(returning: characteristic)
      }
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: (any Error)?
  ) {
    guard
      let continuation = continuationStore.reads.take(characteristic.uuid)
    else { return }

    if let error = error {
      continuation.resume(throwing: error)
      return
    }

    guard let data = characteristic.value else {
      continuation.resume(throwing: BluetoothError.internalError)
      return
    }

    continuation.resume(returning: data)
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didWriteValueFor characteristic: CBCharacteristic,
    error: (any Error)?
  ) {
    guard
      let continuation = continuationStore.writes.take(characteristic.uuid)
    else { return }

    if let error = error {
      continuation.resume(throwing: error)
      return
    }

    continuation.resume(returning: ())
  }

  private func scan() {
    self.scanning = true
    self.scannedPeripherals = []

    self.centralManager.scanForPeripherals(
      withServices: [
        CONFIGURATION_SERVICE_UUID
      ],
      options: [
        CBCentralManagerScanOptionAllowDuplicatesKey: true
      ]
    )
  }

  private func stopScan() {
    self.centralManager.stopScan()
    self.scanning = false
  }

  private func removeStalePeripherals() {
    let cutoff = Date().addingTimeInterval(-3)
    scannedPeripherals.removeAll { p in
      p.lastAdvertisedAt < cutoff
    }
  }

  public func connect(peripheral: CBPeripheral) {
    if let p = self.connectedPeripheral {
      centralManager.cancelPeripheralConnection(p)
    }

    self.pendingPeripheral = peripheral
    self.centralManager.connect(peripheral)
  }

  public func disconnect() {
    if let p = self.connectedPeripheral {
      centralManager.cancelPeripheralConnection(p)
    }
  }

  public func discoverService(uuid: CBUUID) async throws -> CBService {
    // 1. If there's already an in-flight discovery, reuse the task
    if let existingTask = continuationStore.serviceTasks.peek(uuid) {
      return try await existingTask.value
    }

    // 2. Otherwise, create a new task representing this async work
    let task = Task<CBService, Error> {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<CBService, Error>) in

        guard let peripheral = self.connectedPeripheral else {
          continuation.resume(throwing: BluetoothError.internalError)
          return
        }

        // Store continuation for delegate BEFORE triggering discovery
        self.continuationStore.services.set(uuid, continuation)

        // Trigger service discovery
        peripheral.discoverServices([uuid])
      }
    }

    // 3. Cache the task for future callers
    continuationStore.serviceTasks.set(uuid, task: task)

    // 4. Wait for the result
    let service = try await task.value

    // 5. Clean up task if you want to prevent stale storage
    _ = continuationStore.serviceTasks.take(uuid)

    return service
  }

  public func discoverCharacteristic(
    uuid: CBUUID,
    on service: CBService
  ) async throws -> CBCharacteristic {

    // 1. If there's already an in-flight discovery for this UUID, reuse the task
    if let existingTask = continuationStore.characteristicTasks.peek(uuid) {
      return try await existingTask.value
    }

    // 2. Otherwise, create a new task representing this async work
    let task = Task<CBCharacteristic, Error> {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<CBCharacteristic, Error>) in

        guard let peripheral = self.connectedPeripheral else {
          continuation.resume(throwing: BluetoothError.internalError)
          return
        }

        // Store the continuation so the delegate can resume it later,
        // BEFORE starting discovery to avoid races.
        self.continuationStore.characteristics.set(
          uuid,
          continuation
        )

        peripheral.discoverCharacteristics([uuid], for: service)
      }
    }

    // 3. Store the task itself so later calls reuse it
    continuationStore.characteristicTasks.set(uuid, task: task)

    // 4. This suspends until the continuation is resumed by the delegate
    let characteristic = try await task.value

    // 5. Optional cleanup of the cached task now that it's resolved
    _ = continuationStore.characteristicTasks.take(uuid)

    return characteristic
  }

  public func readValue(
    for characteristic: CBCharacteristic,
    timeout: TimeInterval = 5
  ) async throws -> Data {
    try await withThrowingTaskGroup(of: Data.self) { group in
      group.addTask {
        try await withCheckedThrowingContinuation { continuation in
          guard let peripheral = self.connectedPeripheral else {
            continuation.resume(throwing: BluetoothError.internalError)
            return
          }

          // Store continuation BEFORE triggering read
          self.continuationStore.reads.set(
            characteristic.uuid,
            continuation
          )

          peripheral.readValue(for: characteristic)
        }
      }

      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        throw BluetoothError.internalError
      }

      let result = try await group.next()!
      group.cancelAll()
      return result
    }
  }

  public func writeValue(
    for characteristic: CBCharacteristic,
    data: Data,
    timeout: TimeInterval = 5
  ) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        try await withCheckedThrowingContinuation { continuation in
          guard let peripheral = self.connectedPeripheral else {
            continuation.resume(throwing: BluetoothError.internalError)
            return
          }

          // Store continuation BEFORE triggering write
          self.continuationStore.writes.set(
            characteristic.uuid,
            continuation
          )

          peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
      }

      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        throw BluetoothError.internalError
      }

      _ = try await group.next()!
      group.cancelAll()
    }
  }
}
