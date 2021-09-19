//
//  MainCoordinator.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import PromiseKit
import UIKit

public protocol DeinitDelegate: AnyObject {
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

    private var cancellables: Set<AnyCancellable> = []

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

        self.loginManager.authStatus.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.authStatusDidChange()
        }.store(in: &self.cancellables)

        self.pushLoginScreen()

        if self.loginManager.authStatus.value == .loggedIn {
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

    func authStatusDidChange() {
        DispatchQueue.main.async {
            switch self.loginManager.authStatus.value {
            case .loggedIn:
                guard self.categoryListCoordinator == nil else {
                    logWarning("Did receive login notification with active `categoryListCoordinator`")
                    return
                }
                self.pushHomeScreen()

            case .loggedOut:
                if self.categoryListCoordinator == nil {
                    logWarning("Did receive logout notification with nil `categoryListCoordinator`")
                }

                self.rootViewController.popToRoot(animated: false)
                self.categoryListCoordinator = nil
                self.settingsCoordinator = nil

            case .unknown, .loggingIn:
                ()  // Do nothing
            }
        }
    }
}
