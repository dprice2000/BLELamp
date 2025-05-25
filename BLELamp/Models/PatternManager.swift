import Foundation

/**
 * Manages available lamp patterns.
 * Public functions:
 * - patterns
 */
class PatternManager: ObservableObject {
    /// The array of available patterns
    @Published var m_patterns: [Pattern] = []

    init() {
        m_patterns = [
            Pattern(m_id: 0, m_name: "Color"),
            Pattern(m_id: 1, m_name: "Waves"),
            Pattern(m_id: 2, m_name: "Rainbow"),
            Pattern(m_id: 3, m_name: "Meteor"),
            Pattern(m_id: 4, m_name: "Breathe"),
            Pattern(m_id: 5, m_name: "Rotation")
        ]
    }
} 