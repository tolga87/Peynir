//
//  FileSizeFormatterTests.swift
//  PeynirTests
//
//  Created by Tolga AKIN on 1/24/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Foundation
@testable import Peynir
import XCTest

class FileSizeFormatterTests: XCTestCase {
    func testFileSizeStrings() {
        // ZB and YB overflow Int ¯\_(ツ)_/¯
        let fileSizes = [
            -1, 0, 1, 512, 1024, 1025, 5432, 1_000_000, 1_048_576, Int(1.3e6), Int(1.5e9), Int(1.8e12), Int(3.4e15), Int(4.8e18)
        ]
        let expectedSuffixes = [
            "bytes", "bytes", "bytes", "bytes", "KB", "KB", "KB", "KB", "MB", "MB", "GB", "TB", "PB", "EB"
        ]

        for (fileSize, expectedSuffix) in zip(fileSizes, expectedSuffixes) {
            let string = FileSizeFormatter.fileSizeString(fileSizeInBytes: fileSize)
            XCTAssert(string.hasSuffix(expectedSuffix))
        }
    }
}
