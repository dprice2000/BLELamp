import Foundation

/**
 * Represents a saved color setting with HSV values.
 * Members:
 * - m_name: The name of the color setting
 * - m_hue: The hue value (0-255)
 * - m_saturation: The saturation value (0-255)
 * - m_value: The value/brightness (0-255)
 */
struct LampColor: Identifiable, Codable {
    let m_name: String
    let m_hue: UInt8
    let m_saturation: UInt8
    let m_value: UInt8
    
    var id: String { m_name }
} 