import SwiftUI

/**
 * Public functions:
 * - body
 */
struct ColorSelectionView: View {
    @Environment(\.dismiss) private var t_dismiss
    @Binding var t_hue: Double
    @Binding var t_saturation: Double
    @Binding var t_value: Double
    
    @State private var t_colors: [LampColor] = []
    
    var body: some View {
        NavigationView {
            List(t_colors) { t_color in
                Button {
                    loadColor(t_color)
                } label: {
                    HStack {
                        Text(t_color.m_name)
                        Spacer()
                        Circle()
                            .fill(SwiftUI.Color(
                                hue: Double(t_color.m_hue) / 255.0,
                                saturation: Double(t_color.m_saturation) / 255.0,
                                brightness: Double(t_color.m_value) / 255.0
                            ))
                            .frame(width: 24, height: 24)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        DataStore.shared.deleteColor(name: t_color.m_name)
                        t_colors = DataStore.shared.getAllColors()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Load Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        t_dismiss()
                    }
                }
            }
        }
        .onAppear {
            t_colors = DataStore.shared.getAllColors()
        }
    }
    
    private func loadColor(_ color: LampColor) {
        t_hue = Double(color.m_hue)
        t_saturation = Double(color.m_saturation)
        t_value = Double(color.m_value)
        t_dismiss()
    }
} 