//
//  LoginInteractor.swift
//  Peynir
//
//  Created by Tolga AKIN on 9/19/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Combine
import PromiseKit

struct AuthInfo {
    let username: String
    let password: String
    let isValid: Bool

    init(username: String = "", password: String = "", isValid: Bool = false) {
        self.username = username
        self.password = password
        self.isValid = isValid
    }
}

enum LoginEvent: InteractorEvent {
    case loginInitiated
    case errorOccurred(errorMessage: String)
}

class LoginInteractor: Interactor<LoginViewAction, LoginEvent> {
    let inputDataSubject = CurrentValueSubject<AuthInfo, Never>(AuthInfo())
    let loadingSubject = CurrentValueSubject<Bool, Never>(false)

    private let loginManager: LoginManagerInterface
    private let userInfoManager: UserInfoManagerInterface
    private var cancellables: Set<AnyCancellable> = []

    init(loginManager: LoginManagerInterface, userInfoManager: UserInfoManagerInterface) {
        self.loginManager = loginManager
        self.userInfoManager = userInfoManager

        super.init()

        self.loginManager.authStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authStatus in
                switch authStatus {
                case .loggingIn:
                    self?.loadingSubject.value = true
                default:
                    self?.loadingSubject.value = false
                }
            }.store(in: &self.cancellables)
    }

    override func handleAction(_ action: LoginViewAction) {
        switch action {
        case .textEntered(let username, let password):
            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            let isValid = !trimmedUsername.isEmpty && !trimmedPassword.isEmpty
            self.inputDataSubject.send(AuthInfo(username: trimmedUsername, password: trimmedPassword, isValid: isValid))

        case .loginRequested:
            self.eventSubject.send(.loginInitiated)

            let authInfo = self.inputDataSubject.value
            guard authInfo.isValid else {
                logError("Cannot initiate authentication; input is not valid")
                return
            }

            firstly {
                self.loginManager.login(username: authInfo.username, password: authInfo.password)
            }.done(on: .main) {
                self.userInfoManager.saveUserCredentials(newCredentials: UserCredentials(username: authInfo.username, password: authInfo.password))
            }.catch(on: .main) { _ in
                self.eventSubject.send(LoginEvent.errorOccurred(errorMessage: "Invalid username/password.\nPlease try again."))
            }
        }
    }

    func login(username: String, password: String) {

    }
}
