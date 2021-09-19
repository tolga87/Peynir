//
//  LoginManager.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import Foundation
import PromiseKit

public enum LoginError: Error {
    case invalidCredentials
    case unknown
}

public enum AuthStatus {
    case unknown
    case loggingIn
    case loggedIn
    case loggedOut
}

// TODO: Change this to use NetworkManager.
protocol LoginManagerInterface {
    var authStatus: CurrentValueSubject<AuthStatus, Never> { get }
    func login(username: String, password: String) -> Promise<Void>
    func logout() -> Guarantee<Void>
}

class LoginManager: LoginManagerInterface {
    var authStatus = CurrentValueSubject<AuthStatus, Never>(.unknown)

    private let userInfoManager: UserInfoManagerInterface
    private let networkManager: NetworkManagerInterface

    public init(networkManager: NetworkManagerInterface, userInfoManager: UserInfoManagerInterface) {
        self.networkManager = networkManager
        self.userInfoManager = userInfoManager

        if let cookies = HTTPCookieStorage.shared.cookies, cookies.count > 0 {
            self.authStatus.value = .loggedIn
        } else {
            self.authStatus.value = .loggedOut
        }
    }

    func login(username: String, password: String) -> Promise<Void> {
        self.authStatus.value = .loggingIn

        return Promise<Void> { seal in
            var request = URLRequest(url: self.loginUrl)

            request.httpMethod = "POST"
            request.httpBody = "username=\(username)&password=\(password)".data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                var isLoggedIn = false
                if let cookies = HTTPCookieStorage.shared.cookies {
                    // Look for a cookie named "_t"
                    isLoggedIn = cookies.reduce(false) { (foundToken, cookie) -> Bool in
                        if foundToken {
                            return true
                        }
                        return cookie.name == "_t"
                    }
                }

                if isLoggedIn {
                    self.authStatus.value = .loggedIn
                    seal.fulfill(())
                } else {
                    self.authStatus.value = .loggedOut
                    if let urlString = response?.url?.absoluteString, urlString.contains("invalid_credentials") {
                        seal.reject(LoginError.invalidCredentials)
                    } else {
                        seal.reject(LoginError.unknown)
                    }
                }
            }
            task.resume()
        }
    }

    func logout() -> Guarantee<Void> {
        return Guarantee<Void> { seal in
            guard self.authStatus.value == .loggedIn else {
                self.authStatus.value = .loggedOut
                seal(())
                return
            }

            HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
            self.authStatus.value = .loggedOut
            seal(())
        }
    }
}

private extension LoginManager {
    var loginUrl: URL {
        return URL(string: "\(self.networkManager.baseUrl)/auth/ldap/callback")!
    }
}
