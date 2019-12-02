//
//  JSON.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

public typealias JSON = [String: Any]

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

public extension JSON {
    func toString() -> String? {
        guard
            let data = try? JSONSerialization.data(withJSONObject: self, options: []),
            let string = String(data: data, encoding: .utf8) else {
                return nil
        }
        return string
    }

    func prettyPrint() {
        self.forEach { print("\($0): \($1)") }
    }
}

public protocol JSONConstructable {
    static func fromJson(json: JSON) -> Self?
}

extension Result {
    public var successValue: Success? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
}
