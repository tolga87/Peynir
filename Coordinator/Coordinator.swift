//
//  Coordinator.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class Coordinator {
    private let apiClient: APIClient
    private let userInfoManager: UserInfoManagerInterface
    private let loginManager: LoginManagerInterface
    private let rootViewController: RootViewController

    public init(apiClient: APIClient, userInfoManager: UserInfoManagerInterface, loginManager: LoginManagerInterface, rootViewController: RootViewController) {
        self.apiClient = apiClient
        self.userInfoManager = userInfoManager
        self.loginManager = loginManager
        self.rootViewController = rootViewController
    }

    public func start() {
        if self.loginManager.isLoggedIn {
            self.showHomeScreen()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didLogin), name: self.loginManager.didLoginNotification, object: nil)
            self.showLoginScreen()
        }
    }
}

private extension Coordinator {
    func showLoginScreen() {
        let loginViewController = LoginViewController(loginManager: self.loginManager, userInfoManager: self.userInfoManager)
        loginViewController.modalPresentationStyle = .fullScreen
        self.rootViewController.present(loginViewController, animated: false, completion: nil)
    }

    func showHomeScreen() {
        DispatchQueue.main.async {
            let categoryListDataProvider = CategoryListDataProvider(apiClient: self.apiClient)
            let categoryListViewController = CategoryListViewController(dataProvider: categoryListDataProvider)
            let homeNavController = UINavigationController(rootViewController: categoryListViewController)
            homeNavController.tabBarItem = UITabBarItem(title: "Home", image: nil, tag: 0)

            let settingsViewController = UIViewController()
            let settingsNavController = UINavigationController(rootViewController: settingsViewController)
            settingsNavController.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 0)

            let homeViewController = HomeViewController(viewControllers: [homeNavController, settingsNavController])
            homeViewController.modalPresentationStyle = .fullScreen

            let presentingViewController = self.rootViewController.presentedViewController ?? self.rootViewController
            presentingViewController.present(homeViewController, animated: false, completion: nil)
        }
    }

    // MARK: Callbacks

    @objc func didLogin() {
        self.showHomeScreen()
    }
}
