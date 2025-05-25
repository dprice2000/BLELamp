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
 */
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    /// The current Bluetooth state
    @Published var m_bluetoothState: CBManagerState = .unknown

    /// List of discovered peripherals
    @Published var m_discoveredPeripherals: [CBPeripheral] = []
    /// The currently selected peripheral
    @Published var m_selectedPeripheral: CBPeripheral? = nil

    /// Whether the app is currently connected to a peripheral
    @Published var m_isConnected: Bool = false

    private var m_centralManager: CBCentralManager!

    override init() {
        super.init()
        m_centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /**
     * Called when the central manager's state is updated.
     * @param p_central The central manager whose state has changed.
     */
    func centralManagerDidUpdateState(_ p_central: CBCentralManager) {
        m_bluetoothState = p_central.state
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
     */
    public func startScan() {
        m_discoveredPeripherals = []
        m_centralManager.scanForPeripherals(withServices: nil, options: nil)
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
            m_centralManager.cancelPeripheralConnection(t_peripheral)
        }
    }

    /**
     * Requests Bluetooth permissions by accessing the central manager's state.
     */
    public func requestBluetoothPermissions() {
        // Accessing state will trigger the permission dialog if needed
        _ = m_centralManager.state
    }

    // CBCentralManagerDelegate: Discover peripheral
    func centralManager(_ p_central: CBCentralManager, didDiscover p_peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !m_discoveredPeripherals.contains(where: { $0.identifier == p_peripheral.identifier }) {
            m_discoveredPeripherals.append(p_peripheral)
        }
    }

    // CBCentralManagerDelegate: Did connect
    func centralManager(_ p_central: CBCentralManager, didConnect p_peripheral: CBPeripheral) {
        if p_peripheral.identifier == m_selectedPeripheral?.identifier {
            m_isConnected = true
        }
    }

    // CBCentralManagerDelegate: Did disconnect
    func centralManager(_ p_central: CBCentralManager, didDisconnectPeripheral p_peripheral: CBPeripheral, error: Error?) {
        if p_peripheral.identifier == m_selectedPeripheral?.identifier {
            m_isConnected = false
            m_selectedPeripheral = nil
        }
    }
} 