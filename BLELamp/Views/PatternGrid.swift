import SwiftUI

/**
 * Public functions:
 * - body
 */
struct PatternGrid: View {
    @ObservedObject var m_bluetoothManager: BluetoothManager
    @Binding var t_colorValue: Double
    @Binding var t_intensityValue: Double
    @Binding var t_brightnessValue: Double
    @State private var m_showDisconnectError: Bool = false
    
    @State private var t_rotationMinutes: Int = 5
    @State private var t_showRotationSettings = false
    
    private let t_rotationOptions = stride(from: 5, through: 60, by: 5)
    
    /**
     * Main view body.
     */
    var body: some View {
        VStack(spacing: 16) {
            Text("Patterns")
                .font(.system(size: 16))
                .frame(maxWidth: .infinity, alignment: .center)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // Color button
                    Button(action: {
                        if !m_bluetoothManager.m_isConnected {
                            m_showDisconnectError = true
                            return
                        }
                        let t_color = BluetoothManager.CHSV(
                            h: UInt8(t_colorValue),
                            s: UInt8(t_intensityValue),
                            v: UInt8(t_brightnessValue)
                        )
                        _ = m_bluetoothManager.sendPatternMessage(pattern: .solidFill, color: t_color)
                    }) {
                        PatternButton(
                            p_title: "Color",
                            p_icon: "paintpalette.fill",
                            p_color: Color(hue: t_colorValue/255, saturation: t_intensityValue/255, brightness: t_brightnessValue/255)
                        )
                    }
                    
                    // Waves button
                    Button(action: {
                        if !m_bluetoothManager.m_isConnected {
                            m_showDisconnectError = true
                            return
                        }
                        _ = m_bluetoothManager.sendPatternMessage(pattern: .pacifica)
                    }) {
                        PatternButton(
                            p_title: "Waves",
                            p_icon: "water.waves",
                            p_color: .blue
                        )
                    }
                    
                    // Rainbow button
                    Button(action: {
                        if !m_bluetoothManager.m_isConnected {
                            m_showDisconnectError = true
                            return
                        }
                        _ = m_bluetoothManager.sendPatternMessage(pattern: .rainbow)
                    }) {
                        PatternButton(
                            p_title: "Rainbow",
                            p_icon: "rainbow",
                            p_color: .purple
                        )
                    }
                    
                    // Meteor button
                    Button(action: {
                        if !m_bluetoothManager.m_isConnected {
                            m_showDisconnectError = true
                            return
                        }
                        _ = m_bluetoothManager.sendPatternMessage(pattern: .meteor)
                    }) {
                        PatternButton(
                            p_title: "Meteor",
                            p_icon: "sparkles",
                            p_color: .yellow
                        )
                    }
                    
                    // Fire button
                    Button(action: {
                        if !m_bluetoothManager.m_isConnected {
                            m_showDisconnectError = true
                            return
                        }
                        _ = m_bluetoothManager.sendPatternMessage(pattern: .fire)
                    }) {
                        PatternButton(
                            p_title: "Fire",
                            p_icon: "flame.fill",
                            p_color: .orange
                        )
                    }
                    
                    // Rotation button
                    Button(action: {
                        if !m_bluetoothManager.m_isConnected {
                            m_showDisconnectError = true
                            return
                        }
                        t_showRotationSettings = true
                    }) {
                        PatternButton(
                            p_title: "Rotation",
                            p_icon: "arrow.triangle.2.circlepath",
                            p_color: .green
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)  // Limit the height to allow scrolling
            
            // Fixed height container for error message to prevent layout shifts
            HStack(spacing: 4) {
                if m_showDisconnectError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Please connect to a lamp first")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .frame(height: 20)  // Fixed height to prevent layout shifts
            .opacity(m_showDisconnectError ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: m_showDisconnectError)
            .onChange(of: m_showDisconnectError) { oldValue, newValue in
                if newValue {
                    // Hide the error after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            m_showDisconnectError = false
                        }
                    }
                }
            }
            
            Spacer(minLength: 20)  // Add some space before the connect button
        }
        .sheet(isPresented: $t_showRotationSettings) {
            NavigationView {
                VStack(spacing: 20) {
                    Picker("Minutes", selection: $t_rotationMinutes) {
                        ForEach(Array(t_rotationOptions), id: \.self) { minute in
                            Text("\(minute) min").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    
                    Button("Start Rotation") {
                        if !m_bluetoothManager.m_isConnected {
                            m_showDisconnectError = true
                            return
                        }
                        // First set the pattern to rotate mode
                        _ = m_bluetoothManager.sendPatternMessage(pattern: .rotate)
                        // Then set the rotation duration
                        _ = m_bluetoothManager.sendRotationMessage(duration: UInt16(t_rotationMinutes * 60))
                        t_showRotationSettings = false
                    }
                    .buttonStyle(ProminentBoldButtonStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .frame(width: 300, height: 300)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 20)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Rotation Duration")
                            .font(.headline)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            t_showRotationSettings = false
                        }
                    }
                }
            }
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
}

/**
 * A button for selecting a pattern.
 */
struct PatternButton: View {
    let p_title: String
    let p_icon: String
    let p_color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: p_icon)
                .font(.system(size: 24))
                .foregroundColor(p_color)
            Text(p_title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    PatternGrid(
        m_bluetoothManager: BluetoothManager(),
        t_colorValue: .constant(127.5),
        t_intensityValue: .constant(127.5),
        t_brightnessValue: .constant(127.5)
    )
} 