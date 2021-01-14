//
//  LoginManager.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation
import PromiseKit

public enum LoginError: Error {
    case invalidCredentials
    case unknown
}

// TODO: Change this to use NetworkManager.
protocol LoginManagerInterface {
    var isLoggedIn: Bool { get }
    func login(username: String, password: String) -> Promise<Void>
    var didLoginNotification: Notification.Name { get }
    var didLogoutNotification: Notification.Name { get }
}

class LoginManager: LoginManagerInterface {
    var didLoginNotification = Notification.Name("LoginManagerDidLogin")
    var didLogoutNotification = Notification.Name("LoginManagerDidLogout")

    private let userInfoManager: UserInfoManagerInterface
    private let networkManager: NetworkManagerInterface

    public init(networkManager: NetworkManagerInterface, userInfoManager: UserInfoManagerInterface) {
        self.networkManager = networkManager
        self.userInfoManager = userInfoManager
    }

    var isLoggedIn: Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return false
        }

        return (cookies.count > 0)
    }

    func login(username: String, password: String) -> Promise<Void> {
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
                    NotificationCenter.default.post(name: self.didLoginNotification, object: self)
                    seal.fulfill(())
                } else {
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
}

private extension LoginManager {
    var loginUrl: URL {
        return URL(string: "\(self.networkManager.baseUrl)/auth/ldap/callback")!
    }
}
