//
//  PostList.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

struct PostList: JSONConstructable, JSONConvertable, Codable, Equatable {
//    let canCreateTopic: Bool
    let posts: [Post]
}
