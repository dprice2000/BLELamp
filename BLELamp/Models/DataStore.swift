import Foundation

/**
 * Manages persistent storage of color settings.
 * Public functions:
 * - saveColor(color:)
 * - getAllColors() -> [LampColor]
 * - deleteColor(name:)
 */
class DataStore {
    /// Singleton instance
    static let shared = DataStore()
    
    /// File URL for storing colors
    private let m_fileURL: URL
    
    private init() {
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        m_fileURL = documentsDirectory.appendingPathComponent("saved_colors.json")
    }
    
    /**
     * Saves a color setting to persistent storage.
     * @param color The color to save
     */
    func saveColor(color: LampColor) {
        var colors = getAllColors()
        
        // Remove existing color with same name if it exists
        colors.removeAll { $0.m_name == color.m_name }
        
        // Add new color
        colors.append(color)
        
        // Save to file
        do {
            let data = try JSONEncoder().encode(colors)
            try data.write(to: m_fileURL)
        } catch {
            Logger.shared.log(level: .error, message: "Failed to save color: \(error.localizedDescription)")
        }
    }
    
    /**
     * Retrieves all saved color settings.
     * @return Array of saved colors
     */
    func getAllColors() -> [LampColor] {
        do {
            let data = try Data(contentsOf: m_fileURL)
            return try JSONDecoder().decode([LampColor].self, from: data)
        } catch {
            // If file doesn't exist or is empty, return empty array
            return []
        }
    }
    
    /**
     * Deletes a color setting by name.
     * @param name The name of the color to delete
     */
    func deleteColor(name: String) {
        var colors = getAllColors()
        colors.removeAll { $0.m_name == name }
        
        do {
            let data = try JSONEncoder().encode(colors)
            try data.write(to: m_fileURL)
        } catch {
            Logger.shared.log(level: .error, message: "Failed to delete color: \(error.localizedDescription)")
        }
    }
} 