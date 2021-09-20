//
//  Presenter.swift
//  Peynir
//
//  Created by Tolga AKIN on 9/19/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Combine
import Foundation

public class Presenter<State: ViewState, Action: ViewAction, Event: InteractorEvent> {

    @Published public var viewState: State

    let interactor: Interactor<Action, Event>
    private var cancellables: Set<AnyCancellable> = []

    init(interactor: Interactor<Action, Event>, initialViewState: State, viewStatePublisher: AnyPublisher<State, Never>) {
        self.viewState = initialViewState
        self.interactor = interactor

        viewStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.viewState = $0
            }.store(in: &self.cancellables)

        self.interactor.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }.store(in: &self.cancellables)
    }

    func handleAction(_ action: Action) {
        self.interactor.handleAction(action)
    }

    func handleEvent(_ event: Event) {
        fatalError("This must be implemented in a subclass")
    }
}
