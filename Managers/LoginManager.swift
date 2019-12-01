//
//  LoginManager.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

typealias LoginCallback = (Bool, Error?) -> Void

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
        let url = Consts.loginUrl

        if HTTPCookieStorage.shared.cookies(for: url)?.first != nil {
            return true
        }
        if let loginCookie = self.userInfoManager?.loginCookie {
            HTTPCookieStorage.shared.setCookies([loginCookie.httpCookie], for: url, mainDocumentURL: nil)
            return true
        }

        return false
    }

    func login(username: String, password: String, completion: LoginCallback?) {
        let url = Consts.loginUrl
        var request = URLRequest(url: Consts.loginUrl)

        request.httpMethod = "POST"
        request.httpBody = "username=\(username)&password=\(password)".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let httpResponse = response as? HTTPURLResponse,
                let headers = httpResponse.allHeaderFields as? [String: String]
                else {
                    completion?(false, LoginError.unknown)
                    return
            }

//            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
//            guard cookies.count > 0 else {
//                completion?(false, LoginError.unknown)
//                return
//            }
            guard let loginCookie = LoginCookie(headers: headers, url: url) else {
                completion?(false, LoginError.unknown)
                return
            }

            HTTPCookieStorage.shared.setCookies([loginCookie.httpCookie], for: url, mainDocumentURL: nil)
            self.userInfoManager?.saveLoginCookie(newLoginCookie: loginCookie)

            //  let cookie = httpResponse.allHeaderFields["Set-Cookie"]
            print("Cookies updated!")
            NotificationCenter.default.post(name: self.didLoginNotification, object: self)
            completion?(true, nil)
        }
        task.resume()

    }
}

private extension LoginManager {
    func getMaxCookieAge(from headers: [String: String]) -> Int? {
        guard let string = headers["Strict-Transport-Security"] else { return nil }

        // Possible syntax:
        // max-age=31536000
        // max-age=31536000; includeSubDomains
        // max-age=31536000; preload
        let maxAgeString = "max-age"

        let tokens = string.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        for token in tokens {
            let maxAgeTokens = token.components(separatedBy: "=")
            if maxAgeTokens.count == 2 && maxAgeTokens[0] == maxAgeString {
                return Int(maxAgeTokens[1])
            }
        }

        return nil
    }

    struct Consts {
        static let loginUrl = URL(string: "https://discourse.ceng.metu.edu.tr/auth/ldap/callback")!
    }
}
