//
//  LoginPresenter.swift
//  Peynir
//
//  Created by Tolga AKIN on 9/19/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Foundation

class LoginPresenter: Presenter<LoginViewState, LoginViewAction, LoginEvent> {
    init(interactor: LoginInteractor) {
        let viewStatePublisher = interactor.inputDataSubject
            .combineLatest(interactor.loadingSubject)
            .map(Self.viewState)
            .eraseToAnyPublisher()

        super.init(interactor: interactor, initialViewState: LoginViewState(), viewStatePublisher: viewStatePublisher)
    }

    private static func viewState(authInfo: AuthInfo, isLoading: Bool) -> LoginViewState {
        return LoginViewState(username: authInfo.username, password: authInfo.password, isInputValid: authInfo.isValid, isLoading: isLoading)
    }

    override func handleEvent(_ event: LoginEvent) {
        switch event {
        case .errorOccurred(let errorMessage):
            self.displayAlertCallback?(errorMessage)

        case .loginInitiated:
            ()  // Do nothing
        }
    }

    var displayAlertCallback: ((String) -> Void)?
}
