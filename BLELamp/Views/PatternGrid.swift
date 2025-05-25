import SwiftUI

/**
 * Public functions:
 * - body
 */
struct PatternGrid: View {
    @Binding var t_currentPattern: Pattern?
    let p_patterns: [Pattern]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            alignment: .center,
            spacing: 16
        ) {
            ForEach(p_patterns) { t_pattern in
                Button(t_pattern.m_name) {
                    if t_currentPattern?.m_id == t_pattern.m_id {
                        t_currentPattern = nil
                    } else {
                        t_currentPattern = t_pattern
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                .buttonStyle(ProminentBoldButtonStyle(p_tint: t_currentPattern?.m_id == t_pattern.m_id ? .green : .accentColor))
            }
        }
    }
} 