//
//  Post.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

struct Post: JSONConstructable, Codable {
    let id: Int
    let name: String
    let username: String
    let avatarTemplate: String
    let createdAt: String
    let cooked: String
}
