//
//  FileSizeFormatter.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/24/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Foundation

class FileSizeFormatter {
    static func fileSizeString(fileSizeInBytes fileSize: Int) -> String {
        var bytes = Double(fileSize)
        let symbols = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]

        var symbolIndex = 0

        while bytes >= 1024.0 {
            bytes /= 1024.0
            symbolIndex += 1

            if symbolIndex >= symbols.count {
                break
            }
        }

        var numberString = String(format: "%.1f", bytes)
        if numberString.hasSuffix(".0") {
            numberString.removeLast(2)
        }

        let symbol = symbols[symbolIndex]
        return "\(numberString) \(symbol)"
    }
}
