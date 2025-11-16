import CoreBluetooth
import SwiftUI

let CONFIGURATION_SERVICE_UUID = CBUUID(string: "d0a823a6-fa98-4597-b0c1-d8577be0e158")

let CONFIGURATION_CHARACTERISTIC_UUID = CBUUID(string: "0101")
let RESTART_CHARACTERISTIC_UUID = CBUUID(string: "0201")

enum BluetoothError: Error {
	case internalError
}

struct ScannedPeripheral {
	let peripheral: CBPeripheral
	var rssi: NSNumber
	var lastAdvertisedAt: Date
}

actor ContinuationMap<Value> {
	private var storage: [CBUUID: CheckedContinuation<Value, Error>] = [:]

	func set(_ uuid: CBUUID, continuation: CheckedContinuation<Value, Error>) {
		storage[uuid] = continuation
	}

	func take(_ uuid: CBUUID) -> CheckedContinuation<Value, Error>? {
		storage.removeValue(forKey: uuid)
	}

	func clear() {
		storage.removeAll()
	}

	func forEach(_ body: (CBUUID, CheckedContinuation<Value, Error>) -> Void) {
		for (uuid, continuation) in storage {
			body(uuid, continuation)
		}
	}
}

actor ContinuationStore {
	let services = ContinuationMap<CBService>()
	let characteristics = ContinuationMap<CBCharacteristic>()
	let reads = ContinuationMap<Data>()
	let writes = ContinuationMap<Void>()
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
		_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?
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
		_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
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

	//	===== ===== ===== =====

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
		Task {
			if let error = error {
				await continuationStore.services.forEach { _, continuation in
					continuation.resume(throwing: error)
				}

				await continuationStore.services.clear()

				return
			}

			guard let services = peripheral.services else { return }

			for service in services {
				if let continuation = await continuationStore.services.take(service.uuid) {
					continuation.resume(returning: service)
				}
			}
		}
	}

	func peripheral(
		_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
		error: (any Error)?
	) {
		Task {
			if let error = error {
				await continuationStore.characteristics.forEach { _, continuation in
					continuation.resume(throwing: error)
				}

				await continuationStore.characteristics.clear()

				return
			}

			guard let characteristics = service.characteristics else { return }

			for characteristic in characteristics {
				if let continuation = await continuationStore.characteristics.take(characteristic.uuid) {
					continuation.resume(returning: characteristic)
				}
			}
		}
	}

	func peripheral(
		_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
		error: (any Error)?
	) {
		Task {
			guard
				let continuation = await continuationStore.reads.take(characteristic.uuid)
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
	}

	func peripheral(
		_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic,
		error: (any Error)?
	) {
		Task {
			guard
				let continuation = await continuationStore.writes.take(characteristic.uuid)
			else { return }

			if let error = error {
				continuation.resume(throwing: error)
				return
			}

			continuation.resume(returning: ())
		}
	}

	//	===== ===== ===== =====

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
		try await withCheckedThrowingContinuation { continuation in
			guard let peripheral = self.connectedPeripheral else {
				continuation.resume(throwing: BluetoothError.internalError)
				return
			}

			Task {
				await self.continuationStore.services.set(
					uuid,
					continuation: continuation
				)
			}

			peripheral.discoverServices([uuid])
		}
	}

	public func discoverCharacteristic(
		uuid: CBUUID,
		on service: CBService
	) async throws -> CBCharacteristic {
		try await withCheckedThrowingContinuation { continuation in
			guard let peripheral = self.connectedPeripheral else {
				continuation.resume(throwing: BluetoothError.internalError)
				return
			}

			Task {
				await self.continuationStore.characteristics.set(
					uuid,
					continuation: continuation
				)
			}

			peripheral.discoverCharacteristics([uuid], for: service)
		}
	}

	public func readValue(for characteristic: CBCharacteristic, timeout: TimeInterval = 5)
		async throws -> Data
	{
		try await withThrowingTaskGroup(of: Data.self) { group in
			group.addTask {
				try await withCheckedThrowingContinuation { continuation in
					guard let peripheral = self.connectedPeripheral else {
						continuation.resume(throwing: BluetoothError.internalError)
						return
					}

					Task {
						await self.continuationStore.reads.set(
							characteristic.uuid,
							continuation: continuation
						)
					}

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
		for characteristic: CBCharacteristic, data: Data, timeout: TimeInterval = 5
	) async throws {
		try await withThrowingTaskGroup(of: Void.self) { group in
			group.addTask {
				try await withCheckedThrowingContinuation { continuation in
					guard let peripheral = self.connectedPeripheral else {
						continuation.resume(throwing: BluetoothError.internalError)
						return
					}

					Task {
						await self.continuationStore.writes.set(
							characteristic.uuid,
							continuation: continuation
						)
					}

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
