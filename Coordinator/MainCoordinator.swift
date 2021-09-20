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

    private var loginCoordinator: LoginCoordinator?
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

        self.loginManager.authStatus.receive(on: DispatchQueue.main).removeDuplicates().sink { [weak self] authStatus in
            guard let self = self else { return }

            switch authStatus {
            case .loggingIn:
                ()  // Do nothing

            case .loggedOut:
                if self.loginCoordinator != nil {
                    // We're already displaying the login screen. No need to restart the flow.
                    return
                }

                self.rootViewController.popToRoot(animated: false)
                self.categoryListCoordinator = nil
                self.settingsCoordinator = nil
                self.startLoginFlow()

            case .loggedIn:
                guard self.categoryListCoordinator == nil else {
                    logWarning("Did receive login notification with active `categoryListCoordinator`")
                    return
                }

                self.rootViewController.popToRoot(animated: false)
                self.loginCoordinator = nil
                self.showHomeScreen()
            }
        }.store(in: &self.cancellables)
    }
}

private extension MainCoordinator {
    func startLoginFlow() {
        self.loginCoordinator = LoginCoordinator(loginManager: self.loginManager, userInfoManager: self.userInfoManager, navigationController: self.rootViewController)
        self.loginCoordinator?.start(completion: nil)
    }

    func showHomeScreen() {
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
}
