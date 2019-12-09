//
//  MainCoordinator.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

public protocol Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}

class MainCoordinator {
    private let apiClient: APIClientInterface
    private let cacheManager: CacheManagerInterface
    private let userInfoManager: UserInfoManagerInterface
    private let loginManager: LoginManagerInterface
    private let rootViewController: RootViewController

    private var categoryListCoordinator: CategoryListCoordinator?
    private var settingsCoordinator: SettingsCoordinator?

    public init(apiClient: APIClientInterface, cacheManager: CacheManagerInterface, userInfoManager: UserInfoManagerInterface, loginManager: LoginManagerInterface, rootViewController: RootViewController) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        self.userInfoManager = userInfoManager
        self.loginManager = loginManager
        self.rootViewController = rootViewController
    }

    public func start() {
        UITabBar.appearance().tintColor = UIColor.label

        let categoryListDataProvider = CategoryListDataProvider(apiClient: self.apiClient, cacheManager: cacheManager)
        let newsNavController = UINavigationController()
        newsNavController.tabBarItem = UITabBarItem(title: "News", image: UIImage(named: "news")!, tag: 0)
        self.categoryListCoordinator = CategoryListCoordinator(categoryListDataProvider: categoryListDataProvider,
                                                               navigationController: newsNavController)

        let settingsNavController = UINavigationController()
        settingsNavController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings")!, tag: 1)
        self.settingsCoordinator = SettingsCoordinator(navigationController: settingsNavController)

        if self.loginManager.isLoggedIn {
            self.showHomeScreen()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didLogin), name: self.loginManager.didLoginNotification, object: nil)
            self.showLoginScreen()
        }
    }
}

private extension MainCoordinator {
    func showLoginScreen() {
        let loginViewController = LoginViewController(loginManager: self.loginManager, userInfoManager: self.userInfoManager)
        loginViewController.modalPresentationStyle = .fullScreen
        self.rootViewController.present(loginViewController, animated: false, completion: nil)
    }

    func showHomeScreen() {
        let navigationViewControllers = [self.categoryListCoordinator?.navigationController, self.settingsCoordinator?.navigationController].compactMap { $0 }
        let homeViewController = HomeViewController(viewControllers: navigationViewControllers)
        homeViewController.modalPresentationStyle = .fullScreen

        let presentingViewController = self.rootViewController.presentedViewController ?? self.rootViewController
        presentingViewController.present(homeViewController, animated: false, completion: nil)

        self.categoryListCoordinator?.start()
    }

    // MARK: Callbacks

    @objc func didLogin() {
        DispatchQueue.main.async {
            self.showHomeScreen()
        }
    }
}
