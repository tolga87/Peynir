//
//  JSON.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

public typealias JSON = [String: Any]

public extension JSON {
    func toData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }

    func toString() -> String? {
        guard
            let data = self.toData(),
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

extension JSONConstructable where Self: Decodable {
    static func fromJson(json: JSON) -> Self? {
        guard let data = json.toData() else { return nil }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Self.self, from: data)
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
}
