//
//  PostMetadataViewModel.swift
//  Peynir
//
//  Created by tolga on 1/12/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import Foundation

protocol PostMetadataViewModelInterface {
    var name: String { get }
    var username: String { get }
    var avatarTemplate: String { get }
    var createdAt: String { get }
}

struct PostMetadataViewModel: PostMetadataViewModelInterface {
    let name: String
    let username: String
    let avatarTemplate: String
    let createdAt: String
}
