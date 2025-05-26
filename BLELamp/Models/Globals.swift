//
//  Globals.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import Foundation

/**
 * Global settings and state for the app.
 */
class Globals {
    /// Debug mode flag
    static var g_debugMode: Bool = false
    
    /// Log level for the app
    static var g_logLevel: LogLevel = .debug
    
    /// Log levels for filtering messages
    enum LogLevel: Int, Comparable {
        case verbose = 0
        case debug = 1
        case warning = 2
        case error = 3
        
        var displayValue: String {
            switch self {
            case .verbose: return "VERB"
            case .debug: return "DEBUG"
            case .warning: return "WARN"
            case .error: return "ERROR"
            }
        }
        
        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
} 