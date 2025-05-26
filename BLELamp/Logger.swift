import Foundation
import Combine

/**
 * Thread-safe logger for the BLELamp app.
 * Public functions:
 * - log(level:message:)
 * - shared (singleton)
 * - logPublisher (for UI binding)
 */
class Logger {
    /// Singleton instance
    static let shared = Logger()

    /// Published log string for UI
    private let m_logSubject = CurrentValueSubject<String, Never>("")
    var logPublisher: AnyPublisher<String, Never> { m_logSubject.eraseToAnyPublisher() }

    /// Internal log storage
    private var m_log: String = ""
    private let m_queue = DispatchQueue(label: "com.blelamp.logger", attributes: .concurrent)
    private let m_maxLogLength = 10000  // Maximum number of characters to keep in log
    
    private init() {}

    /**
     * Logs a message at the given level.
     * @param level The log level (default: .debug).
     * @param message The message to log.
     */
    func log(level: Globals.LogLevel = .debug, message: String) {
        // Check if message should be logged based on current log level
        guard level >= Globals.g_logLevel else { return }
        
        let t_timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let t_logLine = "[\(t_timestamp)] \(level.displayValue):\t\(message)"
        print(t_logLine)
        
        m_queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Create new log string with the new line
            var t_newLog = self.m_log
            if !t_newLog.isEmpty {
                t_newLog += "\n"
            }
            t_newLog += t_logLine
            
            // Trim log if it gets too long
            if t_newLog.count > self.m_maxLogLength {
                let t_startIndex = t_newLog.index(t_newLog.startIndex, offsetBy: t_newLog.count - self.m_maxLogLength)
                t_newLog = String(t_newLog[t_startIndex...])
            }
            
            // Update the log and publish on main thread
            self.m_log = t_newLog
            DispatchQueue.main.async {
                self.m_logSubject.send(self.m_log)
            }
        }
    }
} 