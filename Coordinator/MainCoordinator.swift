//
//  MainCoordinator.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

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

    public init(apiClient: APIClientInterface, cacheManager: CacheManagerInterface, userInfoManager: UserInfoManagerInterface, loginManager: LoginManagerInterface, rootViewController: RootViewController) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        self.userInfoManager = userInfoManager
        self.loginManager = loginManager
        self.rootViewController = rootViewController
    }

    // `completion` should never get called.
    public func start(completion: CoordinatorCompletionCallback?) {
        UITabBar.appearance().tintColor = UIColor.label

        if self.loginManager.isLoggedIn {
            self.showHomeScreen()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didLogin), name: self.loginManager.didLoginNotification, object: nil)
            self.showLoginScreen()
        }

        DebugOptionsManager.sharedInstance.addShakeGestureListener(listener: self)
    }
}

extension MainCoordinator: ShakeGestureListener {
    func didReceiveShakeGesture() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Debug Options",
                                          message: nil,
                                          preferredStyle: .actionSheet)
            let clearCacheAction = UIAlertAction(title: "Clear cache", style: .default) { _ in
                if let error = self.cacheManager.clearAllJsons() {
                    logError("Could not clear cache: \(error)")
                } else {
                    logInfo("Cache cleared")
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(clearCacheAction)
            alert.addAction(cancelAction)

            let presentingViewController = self.rootViewController.presentedViewController ?? self.rootViewController
            presentingViewController.present(alert, animated: true, completion: nil)
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
        let categoryListDataProvider = CategoryListDataProvider(apiClient: self.apiClient, cacheManager: self.cacheManager)
        let newsNavController = UINavigationController()
        newsNavController.tabBarItem = UITabBarItem(title: "News", image: UIImage(named: "news")!, tag: 0)
        let categoryListCoordinator = CategoryListCoordinator(categoryListDataProvider: categoryListDataProvider,
                                                              navigationController: newsNavController)
        self.categoryListCoordinator = categoryListCoordinator

        let settingsNavController = UINavigationController()
        settingsNavController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings")!, tag: 1)
        let settingsCoordinator = SettingsCoordinator(navigationController: settingsNavController)
        self.settingsCoordinator = settingsCoordinator

        let navigationViewControllers = [categoryListCoordinator.navigationController, settingsCoordinator.navigationController]
        let homeViewController = HomeViewController(viewControllers: navigationViewControllers)
        homeViewController.modalPresentationStyle = .fullScreen

        let presentingViewController = self.rootViewController.presentedViewController ?? self.rootViewController
        presentingViewController.present(homeViewController, animated: false, completion: nil)

        categoryListCoordinator.start(completion: nil)
    }

    // MARK: Callbacks

    @objc func didLogin() {
        DispatchQueue.main.async {
            self.showHomeScreen()
        }
    }
}
