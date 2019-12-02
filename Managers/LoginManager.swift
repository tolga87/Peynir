//
//  LoginManager.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

typealias LoginCallback = (LoginError?) -> Void

public enum LoginError: Error {
    case unknown
}

protocol LoginManagerInterface {
    var isLoggedIn: Bool { get }
    func login(username: String, password: String, completion: LoginCallback?)
    var didLoginNotification: Notification.Name { get }
    var didLogoutNotification: Notification.Name { get }
}

class LoginManager: LoginManagerInterface {
    var didLoginNotification = Notification.Name("LoginManagerDidLogin")
    var didLogoutNotification = Notification.Name("LoginManagerDidLogout")

    private var userInfoManager: UserInfoManagerInterface?

    public init(userInfoManager: UserInfoManagerInterface) {
        self.userInfoManager = userInfoManager
    }

    var isLoggedIn: Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return false
        }

        return (cookies.count > 0)
    }

    func login(username: String, password: String, completion: LoginCallback?) {
        var request = URLRequest(url: Consts.loginUrl)

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
                completion?(nil)
            } else {
                completion?(.unknown)
            }
        }
        task.resume()

    }
}

private extension LoginManager {
    struct Consts {
        static let baseUrl = URL(string: "https://cow.ceng.metu.edu.tr/")!
        static let loginUrl = URL(string: "https://cow.ceng.metu.edu.tr/auth/ldap/callback")!
    }
}
