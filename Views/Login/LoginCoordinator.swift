//
//  LoginCoordinator.swift
//  Peynir
//
//  Created by Tolga AKIN on 9/19/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import UIKit

final class LoginCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    private let loginManager: LoginManagerInterface
    private let userInfoManager: UserInfoManagerInterface

    init(loginManager: LoginManagerInterface, userInfoManager: UserInfoManagerInterface, navigationController: UINavigationController) {
        self.loginManager = loginManager
        self.userInfoManager = userInfoManager
        self.navigationController = navigationController
    }

    func start(completion: CoordinatorCompletionCallback?) {
        let interactor = LoginInteractor(loginManager: self.loginManager, userInfoManager: self.userInfoManager)
        let presenter = LoginPresenter(interactor: interactor)

        let loginViewController = LoginViewController(presenter: presenter)
        self.navigationController.pushViewController(loginViewController, animated: false)
    }

}
