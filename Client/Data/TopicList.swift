//
//  TopicList.swift
//  Peynir
//
//  Created by tolga on 12/7/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

struct TopicList: JSONConstructable, JSONConvertable, Codable {
    let canCreateTopic: Bool
    let topics: [Topic]
}
