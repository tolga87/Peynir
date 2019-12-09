//
//  TopicListCoordinator.swift
//  Peynir
//
//  Created by tolga on 12/8/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class TopicListCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    private var topicListDataProvider: TopicListDataProvider

    init(topicListDataProvider: TopicListDataProvider, navigationController: UINavigationController) {
        self.topicListDataProvider = topicListDataProvider
        self.navigationController = navigationController
    }

    func start() {
        let categoryListViewController = TopicListViewController(dataProvider: topicListDataProvider)
        self.navigationController.pushViewController(categoryListViewController, animated: true)
    }
}
