//
//  CategoryList.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

struct CategoryList: JSONConstructable, JSONConvertable, Codable {
    let canCreateCategory: Bool  // TODO: This is fragile. Implement a safe method for extracting numbers.
    let categories: [Category]

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case canCreateCategory
        case categories
    }


    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.canCreateCategory, forKey: .canCreateCategory)
        try container.encode(self.categories, forKey: .categories)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.canCreateCategory = try container.decode(Bool.self, forKey: .canCreateCategory)

        do {
            self.categories = try container.decode([Category].self, forKey: .categories)
        } catch {
            self.categories = []
            print("wtf happened?")
        }
    }
}
