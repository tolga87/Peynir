//
//  UserInfoManager.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

struct UserCredentials {
    let username: String
    let password: String
}

protocol UserInfoManagerInterface {
    var userCredentials: UserCredentials? { get }
    func saveUserCredentials(newCredentials: UserCredentials?)
}

class UserInfoManager: UserInfoManagerInterface {
    private let customKeychainWrapperInstance = KeychainWrapper(serviceName: Consts.serviceName, accessGroup: Consts.accessGroupName)

    var userCredentials: UserCredentials? {
        guard
            let username = self.customKeychainWrapperInstance.string(forKey: Consts.usernameKey),
            let password = self.customKeychainWrapperInstance.string(forKey: Consts.passwordKey),
            username.count > 0, password.count > 0 else {
                return nil
        }
        return UserCredentials(username: username, password: password)
    }

    func saveUserCredentials(newCredentials: UserCredentials?) {
        guard let credentials = newCredentials else {
            self.customKeychainWrapperInstance.removeObject(forKey: Consts.usernameKey)
            self.customKeychainWrapperInstance.removeObject(forKey: Consts.passwordKey)
            return
        }

        self.customKeychainWrapperInstance.set(credentials.username, forKey: Consts.usernameKey)
        self.customKeychainWrapperInstance.set(credentials.password, forKey: Consts.passwordKey)
    }
}

private extension UserInfoManager {
    struct Consts {
        static let serviceName = "ServiceName"
        static let accessGroupName = "286BN4BY9J.PeynirKeychainAccessGroup"
        static let usernameKey = "UsernameKey"
        static let passwordKey = "PasswordKey"
        static let loginCookieKey = "LoginCookieKey"
    }
}
