//
//  MainCoordinator.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import PromiseKit
import UIKit

public protocol DeinitDelegate: class {
    func didDeinit(sender: Any)
}

public typealias CoordinatorCompletionCallback = (Any?) -> Void

public protocol Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start(completion: CoordinatorCompletionCallback?)
}

class MainCoordinator {
    private let apiClient: APIClientInterface
    private let cacheManager: CacheManagerInterface
    private let userInfoManager: UserInfoManagerInterface
    private let loginManager: LoginManagerInterface
    private let rootViewController: RootViewController

    private var categoryListCoordinator: CategoryListCoordinator?
    private var settingsCoordinator: SettingsCoordinator?

    public init(apiClient: APIClientInterface,
                cacheManager: CacheManagerInterface,
                userInfoManager: UserInfoManagerInterface,
                loginManager: LoginManagerInterface,
                rootViewController: RootViewController) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        self.userInfoManager = userInfoManager
        self.loginManager = loginManager
        self.rootViewController = rootViewController
    }

    // `completion` should never get called.
    public func start(completion: CoordinatorCompletionCallback?) {
        UITabBar.appearance().tintColor = UIColor.label

        NotificationCenter.default.addObserver(self, selector: #selector(didLogout), name: self.loginManager.didLogoutNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLogin), name: self.loginManager.didLoginNotification, object: nil)

        self.pushLoginScreen()

        if self.loginManager.isLoggedIn {
            self.pushHomeScreen()
        }
    }
}

private extension MainCoordinator {
    func pushLoginScreen() {
        let loginViewController = LoginViewController(loginManager: self.loginManager, userInfoManager: self.userInfoManager)
        self.rootViewController.push(loginViewController, animated: false)
    }

    func pushHomeScreen() {
        let categoryListDataProvider = CategoryListDataProvider(apiClient: self.apiClient, cacheManager: self.cacheManager)
        let newsNavController = UINavigationController()
        newsNavController.tabBarItem = UITabBarItem(title: "News", image: UIImage(named: "news")!, tag: 0)
        let categoryListCoordinator = CategoryListCoordinator(categoryListDataProvider: categoryListDataProvider,
                                                              cacheManager: self.cacheManager,
                                                              navigationController: newsNavController)
        self.categoryListCoordinator = categoryListCoordinator

        let settingsNavController = UINavigationController()
        settingsNavController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings")!, tag: 1)
        let settingsCoordinator = SettingsCoordinator(navigationController: settingsNavController,
                                                      loginManager: self.loginManager,
                                                      cacheManager: self.cacheManager)
        self.settingsCoordinator = settingsCoordinator

        let navigationViewControllers = [categoryListCoordinator.navigationController, settingsCoordinator.navigationController]
        let homeViewController = HomeViewController(viewControllers: navigationViewControllers)
        self.rootViewController.push(homeViewController, animated: false)

        categoryListCoordinator.start(completion: nil)
        settingsCoordinator.start(completion: nil)
    }

    // MARK: Callbacks

    @objc func didLogin() {
        guard self.categoryListCoordinator == nil else {
            logWarning("Did receive login notification with active `categoryListCoordinator`")
            return
        }

        DispatchQueue.main.async {
            self.pushHomeScreen()
        }
    }

    @objc func didLogout() {
        if self.categoryListCoordinator == nil {
            logWarning("Did receive logout notification with nil `categoryListCoordinator`")
        }

        DispatchQueue.main.async {
            self.rootViewController.popToRoot(animated: false)

            self.categoryListCoordinator = nil
            self.settingsCoordinator = nil
        }
    }
}
