//
//  String+Extensions.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

public extension String {
    func toJson() -> JSON? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? JSON
        } catch {
            return nil
        }
    }
}
