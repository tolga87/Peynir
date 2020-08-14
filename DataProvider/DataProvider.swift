//
//  DataProvider.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

public enum DataProviderState {
    case unknown
    case loading
    case loaded
    case error(Error)
}

public protocol DataProvider {
    associatedtype DataType

    var didUpdateNotification: Notification.Name { get }

    var state: DataProviderState { get }
    var items: [DataType] { get }
    func fetch()
}
