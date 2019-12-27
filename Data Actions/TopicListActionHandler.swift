//
//  TopicListActionHandler.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

protocol TopicListActionHandler: class {
    func didSelectTopic(_ topic: Topic)
}
