//
//  BluetoothManager.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import Foundation
import CoreBluetooth

/**
 * Public functions:
 * - centralManagerDidUpdateState(_:)
 * - bluetoothStateDescription(_:)
 * - startScan()
 * - stopScan()
 * - connectToDevice(_:)
 * - disconnect()
 * - requestBluetoothPermissions()
 * - sendPatternMessage(pattern:color:)
 * - sendRotationMessage(duration:)
 * - sendColorMessage(color:)
 * - sendStatusRequest()
 */
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    // Message type definitions
    private enum MessageType: UInt8 {
        case setPattern = 0x01
        case setRotation = 0x02
        case setColor = 0x03
        case getStatus = 0x04
        case heartbeat = 0x05  // Added heartbeat message type
    }
    
    // Pattern type definitions
    public enum PatternType: UInt8 {
        case solidFill = 0x00
        case fire = 0x01
        case pacifica = 0x02
        case rainbow = 0x03
        case meteor = 0x04
        case rotate = 0xFF
    }
    
    // Message structures
    private struct PatternMessage {
        let type: UInt8 = MessageType.setPattern.rawValue
        let pattern: UInt8
        let color: CHSV
        
        var data: Data {
            var t_data = Data()
            t_data.append(type)
            t_data.append(pattern)
            t_data.append(color.h)
            t_data.append(color.s)
            t_data.append(color.v)
            return t_data
        }
    }
    
    private struct RotationMessage {
        let type: UInt8 = MessageType.setRotation.rawValue
        let duration: UInt16
        
        var data: Data {
            var t_data = Data()
            t_data.append(type)
            t_data.append(contentsOf: withUnsafeBytes(of: duration.bigEndian) { Array($0) })
            return t_data
        }
    }
    
    private struct ColorMessage {
        let type: UInt8 = MessageType.setColor.rawValue
        let color: CHSV
        
        var data: Data {
            var t_data = Data()
            t_data.append(type)
            t_data.append(color.h)
            t_data.append(color.s)
            t_data.append(color.v)
            return t_data
        }
    }
    
    private struct StatusMessage {
        let type: UInt8 = MessageType.getStatus.rawValue
        
        var data: Data {
            var t_data = Data()
            t_data.append(type)
            return t_data
        }
    }
    
    private struct HeartbeatMessage {
        let type: UInt8 = MessageType.heartbeat.rawValue
        let sequence: UInt32
        let uptime: UInt32
        
        init?(data: Data) {
            guard data.count >= 9 else { return nil }  // type(1) + sequence(4) + uptime(4)
            guard data[0] == type else { return nil }
            
            // Convert bytes to UInt32 using bit shifting (big-endian)
            // Most significant byte first (data[4])
            sequence = (UInt32(data[4]) << 24) |
                      (UInt32(data[3]) << 16) |
                      (UInt32(data[2]) << 8) |
                       UInt32(data[1])
            
            uptime = (UInt32(data[8]) << 24) |
                    (UInt32(data[7]) << 16) |
                    (UInt32(data[6]) << 8) |
                     UInt32(data[5])
        }
    }

    // CHSV color structure to match FastLED
    struct CHSV {
        let h: UInt8
        let s: UInt8
        let v: UInt8
    }

    /// The current Bluetooth state
    @Published var m_bluetoothState: CBManagerState = .unknown

    /// List of discovered peripherals
    @Published var m_discoveredPeripherals: [CBPeripheral] = []
    /// The currently selected peripheral
    @Published var m_selectedPeripheral: CBPeripheral? = nil

    /// Whether the app is currently connected to a peripheral
    @Published var m_isConnected: Bool = false
    
    /// Whether we're in the process of connecting
    @Published var m_isConnecting: Bool = false

    private var m_centralManager: CBCentralManager!
    private var m_writeCharacteristic: CBCharacteristic?
    private var m_notifyCharacteristic: CBCharacteristic?
    private let m_serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let m_rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let m_txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    private let m_notifyDescriptorUUID = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb") // BLE2902 descriptor UUID

    override init() {
        super.init()
        // Initialize with options to show power alert and restore state
        m_centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
                CBCentralManagerOptionRestoreIdentifierKey: "com.dprice2000.BLELamp"
            ]
        )
        Logger.shared.log(message: "BluetoothManager initialized, initial state: \(BluetoothManager.bluetoothStateDescription(m_bluetoothState))")
    }

    /**
     * Called when the central manager's state is updated.
     * @param p_central The central manager whose state has changed.
     */
    func centralManagerDidUpdateState(_ p_central: CBCentralManager) {
        let t_oldState = m_bluetoothState
        m_bluetoothState = p_central.state
        
        // Log state change
        Logger.shared.log(message: "Bluetooth state changed from \(BluetoothManager.bluetoothStateDescription(t_oldState)) to \(BluetoothManager.bluetoothStateDescription(m_bluetoothState))")
        
        switch m_bluetoothState {
        case .poweredOff:
            // Clear all state when Bluetooth is turned off
            m_discoveredPeripherals = []
            m_selectedPeripheral = nil
            m_isConnected = false
            Logger.shared.log(level: .warning, message: "Bluetooth is powered off. Please turn on Bluetooth to use BLELamp.")
            
        case .unauthorized:
            Logger.shared.log(level: .error, message: "Bluetooth permission denied. Please enable Bluetooth access in Settings.")
            
        case .unsupported:
            Logger.shared.log(level: .error, message: "This device does not support Bluetooth Low Energy.")
            
        case .resetting:
            Logger.shared.log(level: .warning, message: "Bluetooth is resetting. Please wait...")
            
        case .poweredOn:
            Logger.shared.log(message: "Bluetooth is ready to use.")
            // Try to restore connection when Bluetooth becomes available
            if !m_discoveredPeripherals.isEmpty {
                restoreConnection()
            }
            
        case .unknown:
            Logger.shared.log(level: .warning, message: "Bluetooth state is unknown. Please wait...")
            
        @unknown default:
            Logger.shared.log(level: .error, message: "Unknown Bluetooth state: \(m_bluetoothState.rawValue)")
        }
    }

    /**
     * Returns a human-readable description for a Bluetooth state.
     * @param p_state The Bluetooth state.
     * @return A string describing the state.
     */
    public static func bluetoothStateDescription(_ p_state: CBManagerState) -> String {
        switch p_state {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        @unknown default: return "Unknown State"
        }
    }

    /**
     * Starts scanning for BLE devices.
     * @return true if scanning started successfully, false otherwise
     */
    public func startScan() -> Bool {
        // Check if Bluetooth is powered on
        guard m_bluetoothState == .poweredOn else {
            Logger.shared.log(level: .error, message: "Cannot start scan: Bluetooth is \(BluetoothManager.bluetoothStateDescription(m_bluetoothState))")
            return false
        }
        
        // Clear previous discoveries
        m_discoveredPeripherals = []
        
        // Set connecting state
        m_isConnecting = true
        
        // Start scanning
        m_centralManager.scanForPeripherals(withServices: nil, options: nil)
        Logger.shared.log(message: "Started scanning for BLE devices")
        return true
    }

    /**
     * Stops scanning for BLE devices.
     */
    public func stopScan() {
        m_centralManager.stopScan()
    }

    /**
     * Connects to the given peripheral.
     * @param p_peripheral The peripheral to connect to.
     */
    public func connectToDevice(_ p_peripheral: CBPeripheral) {
        m_selectedPeripheral = p_peripheral
        m_centralManager.connect(p_peripheral, options: nil)
    }

    /**
     * Disconnects from the currently connected peripheral.
     */
    public func disconnect() {
        if let t_peripheral = m_selectedPeripheral {
            m_isConnecting = true  // Set connecting state while disconnecting
            m_centralManager.cancelPeripheralConnection(t_peripheral)
        }
    }

    /**
     * Requests Bluetooth permissions by accessing the central manager's state.
     * This will trigger the system permission dialog if needed.
     */
    public func requestBluetoothPermissions() {
        Logger.shared.log(message: "Requesting Bluetooth permissions...")
        // Accessing state will trigger the permission dialog if needed
        _ = m_centralManager.state
    }

    // CBCentralManagerDelegate: Discover peripheral
    func centralManager(_ p_central: CBCentralManager, didDiscover p_peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Only add devices named "BLE LAMP"
        guard let t_deviceName = p_peripheral.name, t_deviceName == "BLE LAMP" else {
            return
        }
        
        // Stop scanning since we found our device
        stopScan()
        
        // Connect to the device
        Logger.shared.log(message: "Found BLE LAMP device, connecting...")
        connectToDevice(p_peripheral)
    }

    // CBCentralManagerDelegate: Did connect
    func centralManager(_ p_central: CBCentralManager, didConnect p_peripheral: CBPeripheral) {
        if p_peripheral.identifier == m_selectedPeripheral?.identifier {
            m_isConnected = true
            m_isConnecting = false
            let t_deviceName = p_peripheral.name ?? "Unknown Device"
            Logger.shared.log(message: "Connection Complete to \(t_deviceName)")
            
            // Set up peripheral delegate and discover services
            p_peripheral.delegate = self
            Logger.shared.log(message: "Starting service discovery...")
            // First discover all services to see what's available
            p_peripheral.discoverServices(nil)
        }
    }

    // CBCentralManagerDelegate: Did disconnect
    func centralManager(_ p_central: CBCentralManager, didDisconnectPeripheral p_peripheral: CBPeripheral, error: Error?) {
        if p_peripheral.identifier == m_selectedPeripheral?.identifier {
            let t_deviceName = p_peripheral.name ?? "Unknown Device"
            Logger.shared.log(message: "Disconnected from \(t_deviceName)")
            m_isConnected = false
            m_isConnecting = false
            m_selectedPeripheral = nil
        }
    }

    // CBCentralManagerDelegate: Will restore state
    func centralManager(_ p_central: CBCentralManager, willRestoreState p_dict: [String : Any]) {
        Logger.shared.log(message: "Restoring previous Bluetooth state...")
        
        // Store the restored peripherals for later use when Bluetooth is ready
        if let t_peripherals = p_dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for t_peripheral in t_peripherals {
                if !m_discoveredPeripherals.contains(where: { $0.identifier == t_peripheral.identifier }) {
                    m_discoveredPeripherals.append(t_peripheral)
                    Logger.shared.log(message: "Restored peripheral: \(t_peripheral.name ?? "Unknown Device")")
                }
            }
        }
        
        // Only attempt to restore connection if Bluetooth is powered on
        if m_bluetoothState == .poweredOn {
            restoreConnection()
        } else {
            Logger.shared.log(level: .warning, message: "Cannot restore connection: Bluetooth is \(BluetoothManager.bluetoothStateDescription(m_bluetoothState))")
        }
    }

    /**
     * Restores the connection to a previously connected peripheral.
     * This should only be called when Bluetooth is powered on.
     */
    private func restoreConnection() {
        guard m_bluetoothState == .poweredOn else {
            Logger.shared.log(level: .error, message: "Cannot restore connection: Bluetooth is \(BluetoothManager.bluetoothStateDescription(m_bluetoothState))")
            return
        }
        
        if let t_peripheral = m_discoveredPeripherals.first(where: { $0.state == .connected }) {
            m_selectedPeripheral = t_peripheral
            m_isConnected = true
            Logger.shared.log(message: "Restored connection to: \(t_peripheral.name ?? "Unknown Device")")
            
            // Set up peripheral delegate and discover services
            t_peripheral.delegate = self
            Logger.shared.log(message: "Starting service discovery for restored connection...")
            t_peripheral.discoverServices([m_serviceUUID])
        }
    }

    /**
     * Sends a pattern message to the device.
     * @param p_pattern The pattern type to set
     * @param p_color Optional color for solid fill pattern
     * @return true if message was sent successfully
     */
    public func sendPatternMessage(pattern p_pattern: PatternType, color p_color: CHSV? = nil) -> Bool {
        guard let t_peripheral = m_selectedPeripheral,
              let t_characteristic = m_writeCharacteristic,
              m_isConnected else {
            Logger.shared.log(level: .error, message: "Cannot send pattern: Not connected to device")
            return false
        }
        
        let t_message = PatternMessage(
            pattern: p_pattern.rawValue,
            color: p_color ?? CHSV(h: 0, s: 0, v: 0)
        )
        
        // Use write without response for better performance
        t_peripheral.writeValue(t_message.data, for: t_characteristic, type: .withoutResponse)
        Logger.shared.log(message: "Sent pattern message: \(p_pattern)")
        return true
    }
    
    /**
     * Sends a rotation message to the device.
     * @param p_duration Duration in seconds between pattern changes
     * @return true if message was sent successfully
     */
    public func sendRotationMessage(duration p_duration: UInt16) -> Bool {
        guard let t_peripheral = m_selectedPeripheral,
              let t_characteristic = m_writeCharacteristic,
              m_isConnected else {
            Logger.shared.log(level: .error, message: "Cannot send rotation: Not connected to device")
            return false
        }
        
        let t_message = RotationMessage(duration: p_duration)
        t_peripheral.writeValue(t_message.data, for: t_characteristic, type: .withoutResponse)
        Logger.shared.log(message: "Sent rotation message: \(p_duration) seconds")
        return true
    }
    
    /**
     * Sends a color message to the device.
     * @param p_color The color to set
     * @return true if message was sent successfully
     */
    public func sendColorMessage(color p_color: CHSV) -> Bool {
        guard let t_peripheral = m_selectedPeripheral,
              let t_characteristic = m_writeCharacteristic,
              m_isConnected else {
            Logger.shared.log(level: .error, message: "Cannot send color: Not connected to device")
            return false
        }
        
        let t_message = ColorMessage(color: p_color)
        t_peripheral.writeValue(t_message.data, for: t_characteristic, type: .withoutResponse)
        Logger.shared.log(message: "Sent color message: H:\(p_color.h) S:\(p_color.s) V:\(p_color.v)")
        return true
    }
    
    /**
     * Requests the current status from the device.
     * @return true if request was sent successfully
     */
    public func sendStatusRequest() -> Bool {
        guard let t_peripheral = m_selectedPeripheral,
              let t_characteristic = m_writeCharacteristic,
              m_isConnected else {
            Logger.shared.log(level: .error, message: "Cannot request status: Not connected to device")
            return false
        }
        
        let t_message = StatusMessage()
        t_peripheral.writeValue(t_message.data, for: t_characteristic, type: .withoutResponse)
        Logger.shared.log(message: "Sent status request")
        return true
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ p_peripheral: CBPeripheral, didDiscoverServices p_error: Error?) {
        guard p_error == nil else {
            Logger.shared.log(level: .error, message: "Error discovering services: \(p_error!.localizedDescription)")
            return
        }
        
        guard let t_services = p_peripheral.services else {
            Logger.shared.log(level: .error, message: "No services found")
            return
        }
        
        Logger.shared.log(message: "Discovered \(t_services.count) services:")
        for t_service in t_services {
            Logger.shared.log(message: "  Service UUID: \(t_service.uuid)")
            if t_service.uuid == m_serviceUUID {
                Logger.shared.log(message: "  Found NUS service!")
            }
        }
        
        // Now discover characteristics for the NUS service
        if let t_nusService = t_services.first(where: { $0.uuid == m_serviceUUID }) {
            Logger.shared.log(message: "Discovering characteristics for NUS service...")
            p_peripheral.discoverCharacteristics([m_rxCharacteristicUUID, m_txCharacteristicUUID], for: t_nusService)
        } else {
            Logger.shared.log(level: .error, message: "NUS service not found!")
        }
    }
    
    func peripheral(_ p_peripheral: CBPeripheral, didDiscoverCharacteristicsFor p_service: CBService, error: Error?) {
        guard error == nil else {
            Logger.shared.log(level: .error, message: "Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        
        guard let t_characteristics = p_service.characteristics else {
            Logger.shared.log(level: .error, message: "No characteristics found for service: \(p_service.uuid)")
            return
        }
        
        Logger.shared.log(message: "Discovered \(t_characteristics.count) characteristics for service: \(p_service.uuid)")
        
        // Log all characteristics and their properties
        for t_characteristic in t_characteristics {
            var t_properties: [String] = []
            if t_characteristic.properties.contains(.broadcast) { t_properties.append("broadcast") }
            if t_characteristic.properties.contains(.read) { t_properties.append("read") }
            if t_characteristic.properties.contains(.writeWithoutResponse) { t_properties.append("writeWithoutResponse") }
            if t_characteristic.properties.contains(.write) { t_properties.append("write") }
            if t_characteristic.properties.contains(.notify) { t_properties.append("notify") }
            if t_characteristic.properties.contains(.indicate) { t_properties.append("indicate") }
            if t_characteristic.properties.contains(.authenticatedSignedWrites) { t_properties.append("authenticatedSignedWrites") }
            if t_characteristic.properties.contains(.extendedProperties) { t_properties.append("extendedProperties") }
            
            Logger.shared.log(message: "  Characteristic UUID: \(t_characteristic.uuid)")
            Logger.shared.log(message: "    Properties: \(t_properties.joined(separator: ", "))")
            
            if t_characteristic.uuid == m_rxCharacteristicUUID {
                m_writeCharacteristic = t_characteristic
                Logger.shared.log(message: "    Found RX (write) characteristic")
            } else if t_characteristic.uuid == m_txCharacteristicUUID {
                m_notifyCharacteristic = t_characteristic
                Logger.shared.log(message: "    Found TX (notify) characteristic")
                
                // Discover descriptors for TX characteristic
                Logger.shared.log(message: "    Discovering descriptors for TX characteristic")
                p_peripheral.discoverDescriptors(for: t_characteristic)
            }
        }
        
        // Verify if we found both characteristics
        if m_writeCharacteristic == nil {
            Logger.shared.log(level: .error, message: "RX characteristic not found!")
        }
        if m_notifyCharacteristic == nil {
            Logger.shared.log(level: .error, message: "TX characteristic not found!")
        }
    }
    
    func peripheral(_ p_peripheral: CBPeripheral, didDiscoverDescriptorsFor p_characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            Logger.shared.log(level: .error, message: "Error discovering descriptors: \(error!.localizedDescription)")
            return
        }
        
        if p_characteristic.uuid == m_txCharacteristicUUID {
            Logger.shared.log(message: "Discovered \(p_characteristic.descriptors?.count ?? 0) descriptors for TX characteristic")
            
            for t_descriptor in p_characteristic.descriptors ?? [] {
                Logger.shared.log(message: "Found descriptor: \(t_descriptor.uuid)")
            }
            
            // Enable notifications using setNotifyValue instead of writing to descriptor
            Logger.shared.log(message: "Enabling notifications for TX characteristic")
            p_peripheral.setNotifyValue(true, for: p_characteristic)
        }
    }
    
    func peripheral(_ p_peripheral: CBPeripheral, didUpdateValueFor p_characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            Logger.shared.log(level: .error, message: "Error receiving notification: \(error!.localizedDescription)")
            return
        }
        
        if p_characteristic.uuid == m_txCharacteristicUUID,
           let t_data = p_characteristic.value {
            Logger.shared.log(level: .verbose, message: "Received notification: \(t_data.hexDescription)")
            handleReceivedData(t_data)
        }
    }
    
    private func handleReceivedData(_ p_data: Data) {
        guard p_data.count >= 1 else { return }
        
        let t_type = p_data[0]
        switch t_type {
        case MessageType.getStatus.rawValue:
            if p_data.count >= 8 {
                let t_pattern = p_data[1]
                let t_rotationDuration = UInt16(bigEndian: p_data[2...3].withUnsafeBytes { $0.load(as: UInt16.self) })
                let t_color = CHSV(h: p_data[4], s: p_data[5], v: p_data[6])
                Logger.shared.log(message: "Received status: Pattern=\(t_pattern), Rotation=\(t_rotationDuration), Color=H:\(t_color.h) S:\(t_color.s) V:\(t_color.v)")
            }
        case MessageType.heartbeat.rawValue:
            if let t_heartbeat = HeartbeatMessage(data: p_data) {
                let t_hours = t_heartbeat.uptime / 3600
                let t_minutes = (t_heartbeat.uptime % 3600) / 60
                let t_seconds = t_heartbeat.uptime % 60
                Logger.shared.log(level: .verbose, message: "Received heartbeat: sequence=\(t_heartbeat.sequence), uptime=\(t_hours)h \(t_minutes)m \(t_seconds)s")
            } else {
                Logger.shared.log(level: .warning, message: "Received invalid heartbeat message: \(p_data.hexDescription)")
            }
        default:
            Logger.shared.log(level: .warning, message: "Received unknown message type: \(t_type)")
        }
    }
}

// Add extension for Data to help with logging
extension Data {
    var hexDescription: String {
        return self.map { String(format: "%02hhx", $0) }.joined(separator: " ")
    }
} 