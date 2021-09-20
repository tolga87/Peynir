//
//  Interactor.swift
//  Peynir
//
//  Created by Tolga AKIN on 9/19/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Combine

public class Interactor<Action: ViewAction, Event: InteractorEvent> {
    public let eventSubject = PassthroughSubject<Event, Never>()

    open func handleAction(_ action: Action) {
        fatalError("This must be implemented in a subclass")
    }
}
