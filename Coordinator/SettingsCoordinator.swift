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

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.childCoordinators = []
    }

    func start(completion: CoordinatorCompletionCallback?) {
        let settingsViewController = UIViewController()
        self.navigationController.pushViewController(settingsViewController, animated: false)
    }
}
