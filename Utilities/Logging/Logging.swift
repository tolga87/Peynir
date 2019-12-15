//
//  Logging.swift
//  Peynir
//
//  Created by tolga on 12/15/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

enum LoggingLevel: Int {
    case debug
    case info
    case warning
    case error
    case fatal

    static func < (lhs: LoggingLevel, rhs: LoggingLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

var globalLoggingLevel = LoggingLevel.debug

func log(loggingLevel: LoggingLevel, _ items: [Any], separator: String = " ", terminator: String) {
    if loggingLevel < globalLoggingLevel {
        return
    }

    let icons: [LoggingLevel: String] = [
        .debug: "🐛",
        .info: "ℹ️",
        .warning: "⚠️",
        .error: "❌",
        .fatal: "💀"
    ]

    var string = items.map { "\($0)" }.joined(separator: separator)
    if let icon = icons[loggingLevel] {
        string = "\(icon) \(string)"
    }

    print(string, separator: separator, terminator: terminator)
}

func logDebug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    log(loggingLevel: .debug, items, separator: separator, terminator: terminator)
}

func logInfo(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    log(loggingLevel: .info, items, separator: separator, terminator: terminator)
}

func logWarning(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    log(loggingLevel: .warning, items, separator: separator, terminator: terminator)
}

func logError(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    log(loggingLevel: .error, items, separator: separator, terminator: terminator)
}

func logFatal(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    log(loggingLevel: .fatal, items, separator: separator, terminator: terminator)
}
