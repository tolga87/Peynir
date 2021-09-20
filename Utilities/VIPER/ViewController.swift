//
//  ViewController.swift
//  Peynir
//
//  Created by Tolga AKIN on 9/19/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Combine
import UIKit

class ViewController<State: ViewState, Action: ViewAction, Event: InteractorEvent>: UIViewController {
    public let presenter: Presenter<State, Action, Event>
    public var cancellables: Set<AnyCancellable> = []

    init(presenter: Presenter<State, Action, Event>) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewState in
                self?.handle(viewState: viewState)
            }.store(in: &self.cancellables)
    }

    func handle(viewState: State) {
        fatalError("This must be implemented in a subclass")
    }
}
