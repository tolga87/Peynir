//
//  PostListCoordinator.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class PostListCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    private let postListDataProvider: PostListDataProvider

    private var completionCallback: CoordinatorCompletionCallback?

    init(postListDataProvider: PostListDataProvider, navigationController: UINavigationController) {
        self.postListDataProvider = postListDataProvider
        self.navigationController = navigationController
    }

    func start(completion: CoordinatorCompletionCallback?) {
        self.completionCallback = completion
        let postListViewController = PostListViewController(dataProvider: self.postListDataProvider)
        postListViewController.deinitDelegate = self
        self.navigationController.pushViewController(postListViewController, animated: true)
    }
}

extension PostListCoordinator: DeinitDelegate {
    func didDeinit(sender: Any) {
        self.completionCallback?("PostListCoordinator has finished")
    }
}
