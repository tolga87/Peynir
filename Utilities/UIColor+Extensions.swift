//
//  UIColor+Extensions.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/15/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hex: String) {
        guard hex.count == 6 else {
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
            return
        }

        let redHex = hex[0..<2]
        let greenHex = hex[2..<4]
        let blueHex = hex[4..<6]

        guard
            let red = Int(redHex, radix: 16),
            let green = Int(greenHex, radix: 16),
            let blue = Int(blueHex, radix: 16) else {
                self.init(red: 0, green: 0, blue: 0, alpha: 0)
                return
        }

        self.init(red: CGFloat(red) / 255.0,
                  green: CGFloat(green) / 255.0,
                  blue: CGFloat(blue) / 255.0,
                  alpha: 1.0)
    }
}

extension String {
    subscript(_ range: Range<Int>) -> String {
        let lowerIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let upperIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[lowerIndex..<upperIndex])
    }
}
