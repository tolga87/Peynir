//
//  TopicListTableViewCellViewModel.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/13/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Foundation

struct TopicListTableViewCellViewModel {
    let title: String
    let likeCount: Int
    let postCount: Int
    let viewCount: Int
    let lastPostedAt: String
    let hasAcceptedAnswer: Bool
}
