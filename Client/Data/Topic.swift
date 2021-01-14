//
//  Topic.swift
//  Peynir
//
//  Created by tolga on 12/7/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

struct Topic: JSONConstructable, Codable {
    let id: Int
    let title: String
    let lastPostedAt: String

    let views: Int
    let likeCount: Int
    let replyCount: Int
    let postsCount: Int

    let hasAcceptedAnswer: Bool
}
