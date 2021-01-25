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

    private var settingsViewController: SettingsViewController?
    private let loginManager: LoginManagerInterface
    private let cacheManager: CacheOperationsManagerInterface

    private var settingsViewModel: SettingsViewModel!

    private func generateSettingsViewModel() -> SettingsViewModel {
        let clearCacheTitleGuarantee: Guarantee<String> = self.cacheManager.cacheSize().map { sizeInBytes in
            let sizeString = FileSizeFormatter.fileSizeString(fileSizeInBytes: sizeInBytes)
            return "Clear Cache (\(sizeString))"
        }.recover { error in
            logError("Could not calculate cache size: \(error)")
            return .value("Clear Cache")
        }

        return SettingsViewModel(actions: [
            SettingsAction(title: clearCacheTitleGuarantee) {
                firstly {
                    self.cacheManager.clearCache()
                }.done(on: .main) {
                    logInfo("Cache cleared successfully")
                }.catch { error in
                    logError("Could not clear cache: \(error)")
                }.finally {
                    self.reloadData()
                    self.settingsViewController?.tableView.reloadData()
                }
            },
            SettingsAction(title: .value("Log Out")) {
                _ = self.loginManager.logout()
            }
        ])
    }

    init(navigationController: UINavigationController, loginManager: LoginManagerInterface, cacheManager: CacheOperationsManagerInterface) {
        self.navigationController = navigationController
        self.loginManager = loginManager
        self.cacheManager = cacheManager
        self.childCoordinators = []

        self.settingsViewModel = self.generateSettingsViewModel()
    }

    func start(completion: CoordinatorCompletionCallback?) {
        let settingsViewController = SettingsViewController(dataSource: self)
        self.navigationController.pushViewController(settingsViewController, animated: false)
        self.settingsViewController = settingsViewController
    }
}

extension SettingsCoordinator: SettingsViewControllerDataSource {
    func getViewModel() -> SettingsViewModel {
        return self.settingsViewModel
    }

    func reloadData() {
        self.settingsViewModel = self.generateSettingsViewModel()
    }


}
