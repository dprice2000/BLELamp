//
//  ContentView.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    /// Observed Bluetooth manager instance
    @StateObject private var m_bluetoothManager = BluetoothManager()
    @State private var t_showDeviceConnect = false
    @State private var t_colorValue = 127.5
    @State private var t_intensityValue = 127.5
    @State private var t_brightnessValue = 127.5
    @State private var t_showDeveloperView = false
    
    // New state variables for color saving
    @State private var t_showSaveColorAlert = false
    @State private var t_colorName = ""
    @State private var t_showSaveError = false
    @State private var t_saveErrorMessage = ""

    // New state variable for color loading
    @State private var t_showColorSelection = false
    
    // Environment value for dynamic type size
    @Environment(\.dynamicTypeSize) private var t_dynamicTypeSize
    
    // Computed property for title font size
    private var t_titleFontSize: CGFloat {
        let t_baseSize = UIFontMetrics.default.scaledValue(for: 16)
        return min(t_baseSize, 20) // Cap at 20 points
    }
    
    // Computed property for label font size
    private var t_labelFontSize: CGFloat {
        let t_baseSize = UIFontMetrics.default.scaledValue(for: 8)
        return min(t_baseSize, 10) // Cap at 10 points
    }

    /**
     * Main view body.
     */
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    VStack(spacing: geometry.size.height * 0.02) {
                        // Centered title at the top with padding
                        Text("Lamp Controls")
                            .font(.system(size: t_titleFontSize))
                            .fontWeight(.bold)
                            .padding(.top, geometry.size.height * 0.02)
                            .frame(maxWidth: .infinity, alignment: .center)

                        // Sliders
                        VStack(alignment: .center, spacing: geometry.size.height * 0.015) {
                            ColorSlider(
                                p_label: "Color",
                                p_value: $t_colorValue,
                                p_saturationValue: t_intensityValue,
                                p_brightnessValue: t_brightnessValue
                            )
                            VStack {
                                Text("Intensity")
                                    .font(.system(size: 16))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                HStack {
                                    Slider(value: $t_intensityValue, in: 0...255, step: 1)
                                }
                            }
                            VStack {
                                Text("Brightness")
                                    .font(.system(size: 16))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                HStack {
                                    Slider(value: $t_brightnessValue, in: 0...255, step: 1)
                                }
                            }
                            
                            // Color save/load buttons
                            HStack(spacing: geometry.size.width * 0.04) {
                                Button("Save Color") {
                                    t_showSaveColorAlert = true
                                }
                                .buttonStyle(ProminentBoldButtonStyle())
                                
                                Button("Load Color") {
                                    t_showColorSelection = true
                                }
                                .buttonStyle(ProminentBoldButtonStyle())
                            }
                            .padding(.top, geometry.size.height * 0.01)
                        }
                        .padding(.horizontal, geometry.size.width * 0.04)
                        .padding(.top, geometry.size.height * 0.01)
                        
                        // Pattern grid
                        PatternGrid(
                            m_bluetoothManager: m_bluetoothManager,
                            t_colorValue: $t_colorValue,
                            t_intensityValue: $t_intensityValue,
                            t_brightnessValue: $t_brightnessValue
                        )
                        .frame(height: geometry.size.height * 0.4)
                        .padding(.vertical, geometry.size.height * 0.01)
                        
                        // Connect/Disconnect button
                        Button(m_bluetoothManager.m_isConnected ? "Disconnect" : "Connect") {
                            if m_bluetoothManager.m_isConnected {
                                let t_deviceName = m_bluetoothManager.m_selectedPeripheral?.name ?? "Unknown Device"
                                Logger.shared.log(message: "Starting disconnect from \(t_deviceName)")
                                m_bluetoothManager.disconnect()
                            } else {
                                Logger.shared.log(message: "Starting scan for BLE LAMP device...")
                                _ = m_bluetoothManager.startScan()
                            }
                        }
                        .buttonStyle(ProminentBoldButtonStyle())
                        .disabled(m_bluetoothManager.m_isConnecting)
                        .opacity(m_bluetoothManager.m_isConnecting ? 0.5 : 1.0)
                        .padding(.horizontal, geometry.size.width * 0.04)
                        .padding(.bottom, geometry.size.height * 0.02)
                        
                        Spacer(minLength: 0)  // Changed from geometry.size.height * 0.02 to 0
                    }
                }
                .navigationBarHidden(true)
                .overlay(
                    Group {
                        if Globals.g_debugMode {
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        // Outer view with border
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color(.systemBackground).opacity(0.8))
                                            )
                                            .frame(width: min(geometry.size.width * 0.12, 55), height: min(geometry.size.width * 0.12, 55))
                                        // Ladybug button inside
                                        Button(action: {
                                            t_showDeveloperView = true
                                        }) {
                                            Image(systemName: "ladybug.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: min(geometry.size.width * 0.08, 35), height: min(geometry.size.width * 0.08, 35))
                                                .foregroundColor(.red)
                                        }
                                        .frame(width: min(geometry.size.width * 0.1, 45), height: min(geometry.size.width * 0.1, 45))
                                    }
                                    .frame(width: min(geometry.size.width * 0.12, 55), height: min(geometry.size.width * 0.12, 55))
                                    .shadow(radius: 4)
                                    .padding(.top, geometry.size.height * 0.01)
                                    .padding(.trailing, geometry.size.width * 0.02)
                                }
                                Spacer()
                            }
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $t_showDeveloperView) {
            DeveloperView()
        }
        .sheet(isPresented: $t_showColorSelection) {
            ColorSelectionView(
                t_hue: $t_colorValue,
                t_saturation: $t_intensityValue,
                t_value: $t_brightnessValue
            )
        }
        .onAppear {
            m_bluetoothManager.requestBluetoothPermissions()
            // Force portrait orientation
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        .alert("Save Color", isPresented: $t_showSaveColorAlert) {
            TextField("Color Name", text: $t_colorName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveCurrentColor()
            }
        } message: {
            Text("Enter a name for this color")
        }
        .alert("Save Error", isPresented: $t_showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(t_saveErrorMessage)
        }
    }
    
    /**
     * Saves the current color settings.
     */
    private func saveCurrentColor() {
        // Validate color name
        let trimmedName = t_colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            t_saveErrorMessage = "Color name cannot be empty"
            t_showSaveError = true
            return
        }
        
        // Create and save the color
        let color = LampColor(
            m_name: trimmedName,
            m_hue: UInt8(t_colorValue),
            m_saturation: UInt8(t_intensityValue),
            m_value: UInt8(t_brightnessValue)
        )
        
        DataStore.shared.saveColor(color: color)
        Logger.shared.log(message: "Saved color: \(trimmedName)")
    }
}

#Preview {
    ContentView()
}
