//
//  SettingsCoordinator.swift
//  Peynir
//
//  Created by tolga on 12/8/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class SettingsCoordinator: Coordinator {
    var childCoordinators: [Coordinator]

    var navigationController: UINavigationController

    private let loginManager: LoginManagerInterface

    private lazy var settingsViewModel =
        SettingsViewModel(actions: [
                            SettingsAction(title: "Log Out") {
                                _ = self.loginManager.logout()
                            }
        ])

    init(navigationController: UINavigationController, loginManager: LoginManagerInterface) {
        self.navigationController = navigationController
        self.loginManager = loginManager
        self.childCoordinators = []
    }

    func start(completion: CoordinatorCompletionCallback?) {
        let settingsViewController = SettingsViewController(viewModel: self.settingsViewModel)
        self.navigationController.pushViewController(settingsViewController, animated: false)
    }
}
