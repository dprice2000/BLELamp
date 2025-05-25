//
//  DeviceConnectView.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import SwiftUI
import CoreBluetooth

/**
 * Public functions:
 * - body
 */
struct DeviceConnectView: View {
    @ObservedObject var m_bluetoothManager: BluetoothManager
    @Environment(\.presentationMode) var t_presentationMode

    @State private var t_isScanning = false
    @State private var t_selectedPeripheral: CBPeripheral? = nil

    /**
     * Main view body.
     */
    var body: some View {
        VStack {
            // Pull-down indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .center)

            List(m_bluetoothManager.m_discoveredPeripherals, id: \.identifier) { t_peripheral in
                HStack {
                    Text(t_peripheral.name ?? "Unknown Device")
                    Spacer()
                    if t_selectedPeripheral?.identifier == t_peripheral.identifier {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    t_selectedPeripheral = t_peripheral
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                Button(action: {
                    if t_isScanning {
                        m_bluetoothManager.stopScan()
                    } else {
                        m_bluetoothManager.startScan()
                    }
                    t_isScanning.toggle()
                }) {
                    Text(t_isScanning ? "Stop Search" : "Search")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProminentBoldButtonStyle())

                Button(action: {
                    if m_bluetoothManager.m_isConnected {
                        m_bluetoothManager.disconnect()
                    } else if let t_peripheral = t_selectedPeripheral {
                        m_bluetoothManager.connectToDevice(t_peripheral)
                        t_presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text(m_bluetoothManager.m_isConnected ? "Disconnect" : "Connect")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProminentBoldButtonStyle())
                .disabled(!m_bluetoothManager.m_isConnected && t_selectedPeripheral == nil)
            }
            .padding()
        }
        .navigationTitle("Connect Device")
    }
} 