import SwiftUI
import CoreBluetooth

let CONFIGURATION_SERVICE_UUID = CBUUID(string: "d0a823a6-fa98-4597-b0c1-d8577be0e158")

final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
	var centralManager: CBCentralManager!
	
	@Published private(set) var state: CBManagerState = .unknown
	@Published private(set) var scanning: Bool = false
	@Published private(set) var scannedPeripherals: [CBPeripheral] = []

	@Published private(set) var pendingPeripheral: CBPeripheral?
	@Published private(set) var connectedPeripheral: CBPeripheral?

	@Published private(set) var characteristics: [CBUUID: CBCharacteristic] = [:]
	
	override init() {
		super.init()
		self.centralManager = CBCentralManager(delegate: self, queue: nil)
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
		rssi RSSI: NSNumber
	) {
		let alreadyScanned = self.scannedPeripherals.contains(where: { p in
			p.identifier == peripheral.identifier
		})
		
		if !alreadyScanned {
			self.scannedPeripherals.append(peripheral)
		}
	}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		self.stopScan()
		peripheral.delegate = self
		
		self.pendingPeripheral = nil
		self.connectedPeripheral = peripheral
		
		self.characteristics = [:]
		
		peripheral.discoverServices([
			CONFIGURATION_SERVICE_UUID
		])
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
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
	
	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
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
		if let error = error {
			print("Error discovering services: \(error.localizedDescription)")
		}
		
		guard let services = peripheral.services else { return }
		let configService = services.first(where: { s in 
			s.uuid == CONFIGURATION_SERVICE_UUID
		})

		guard let configService else { return }
		peripheral.discoverCharacteristics(nil, for: configService)
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
		if let error = error {
			print("Error discovering characteristics: \(error.localizedDescription)")
		}
		
		guard let characteristics = service.characteristics else { return }

		characteristics.forEach { c in
			peripheral.readValue(for: c)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
		if let error = error {
			print("Error reading characteristic: \(error.localizedDescription)")
		}
		
		self.characteristics[characteristic.uuid] = characteristic
	}
	
	func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
		if let error = error {
			print("Error writing characteristic: \(error.localizedDescription)")
		}
		
		peripheral.readValue(for: characteristic)
	}
	
	//	===== ===== ===== =====
	
	func scan() {
		self.scanning = true
		self.scannedPeripherals = []
		
		self.centralManager.scanForPeripherals(
			withServices: [
				CONFIGURATION_SERVICE_UUID
			]
		)
	}
	
	func stopScan() {
		self.centralManager.stopScan()
		self.scanning = false
	}
	
	func connect(peripheral: CBPeripheral) {
		if let p = self.connectedPeripheral {
			centralManager.cancelPeripheralConnection(p)
		}
		
		self.pendingPeripheral = peripheral
		self.centralManager.connect(peripheral)
	}
	
	func disconnect() {
		if let p = self.connectedPeripheral {
			centralManager.cancelPeripheralConnection(p)
		}
	}
	
	func write(to characteristic: CBCharacteristic, data: Data) {
		guard let p = self.connectedPeripheral else { return }
		p.writeValue(data, for: characteristic, type: .withResponse)
	}
}
