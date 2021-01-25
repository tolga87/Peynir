//
//  SettingsCoordinator.swift
//  Peynir
//
//  Created by tolga on 12/8/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit
import PromiseKit

class SettingsCoordinator: Coordinator {
    var childCoordinators: [Coordinator]

    var navigationController: UINavigationController

    private let loginManager: LoginManagerInterface
    private let cacheManager: CacheOperationsManagerInterface

    private lazy var settingsViewModel: SettingsViewModel = {
        let clearCacheTitleGuarantee: Guarantee<String> = self.cacheManager.cacheSize().map { sizeInBytes in
            let sizeString = FileSizeFormatter.fileSizeString(fileSizeInBytes: sizeInBytes)
            return "Clear Cache (\(sizeString))"
        }.recover { error in
            logError("Could not calculate cache size: \(error)")
            return .value("Clear Cache")
        }

        return SettingsViewModel(actions: [
            SettingsAction(title: clearCacheTitleGuarantee) {
                _ = self.cacheManager.clearCache()
            },
            SettingsAction(title: .value("Log Out")) {
                _ = self.loginManager.logout()
            }
        ])
    }()

    init(navigationController: UINavigationController, loginManager: LoginManagerInterface, cacheManager: CacheOperationsManagerInterface) {
        self.navigationController = navigationController
        self.loginManager = loginManager
        self.cacheManager = cacheManager
        self.childCoordinators = []
    }

    func start(completion: CoordinatorCompletionCallback?) {
        let settingsViewController = SettingsViewController(viewModel: self.settingsViewModel)
        self.navigationController.pushViewController(settingsViewController, animated: false)
    }
}
