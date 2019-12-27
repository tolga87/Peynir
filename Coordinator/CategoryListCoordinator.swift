//
//  CategoryListCoordinator.swift
//  Peynir
//
//  Created by tolga on 12/8/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class CategoryListCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    private let categoryListDataProvider: CategoryListDataProvider

    init(categoryListDataProvider: CategoryListDataProvider, navigationController: UINavigationController) {
        self.categoryListDataProvider = categoryListDataProvider
        self.navigationController = navigationController
    }

    func start() {
        let categoryListViewController = CategoryListViewController(dataProvider: categoryListDataProvider)
        categoryListViewController.actionHandler = self
        self.navigationController.pushViewController(categoryListViewController, animated: false)
    }
}

extension CategoryListCoordinator: CategoryListActionHandler {
    func didSelectCategory(_ category: Category) {
        let topicListDataProvider = TopicListDataProvider(categoryId: category.id,
                                                          categoryName: category.name,
                                                          apiClient: self.categoryListDataProvider.apiClient,
                                                          cacheManager: self.categoryListDataProvider.cacheManager)
        let topicListCoordinator = TopicListCoordinator(topicListDataProvider: topicListDataProvider, navigationController: self.navigationController)
        self.childCoordinators.append(topicListCoordinator)

        topicListCoordinator.start()
    }
}
