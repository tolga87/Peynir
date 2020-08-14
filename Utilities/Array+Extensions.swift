//
//  Array+Extensions.swift
//  Peynir
//
//  Created by tolga on 7/26/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import Foundation

extension Collection {

    subscript (safe index: Index) -> Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
}
