import Foundation

/**
 * Represents a lamp pattern.
 * Members:
 * - m_id: The pattern ID.
 * - m_name: The pattern name.
 */
struct Pattern: Identifiable {
    let m_id: UInt8
    let m_name: String

    var id: UInt8 { m_id }
} 