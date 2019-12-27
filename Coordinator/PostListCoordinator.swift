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

    init(postListDataProvider: PostListDataProvider, navigationController: UINavigationController) {
        self.postListDataProvider = postListDataProvider
        self.navigationController = navigationController
    }

    func start() {
        let categoryListViewController = PostListViewController(dataProvider: self.postListDataProvider)
        self.navigationController.pushViewController(categoryListViewController, animated: true)
    }
}
