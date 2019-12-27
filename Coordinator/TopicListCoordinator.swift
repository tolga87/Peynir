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

    private let topicListDataProvider: TopicListDataProvider

    init(topicListDataProvider: TopicListDataProvider, navigationController: UINavigationController) {
        self.topicListDataProvider = topicListDataProvider
        self.navigationController = navigationController
    }

    func start() {
        let categoryListViewController = TopicListViewController(dataProvider: topicListDataProvider)
        categoryListViewController.actionHandler = self
        self.navigationController.pushViewController(categoryListViewController, animated: true)
    }
}

extension TopicListCoordinator: TopicListActionHandler {
    func didSelectTopic(_ topic: Topic) {
        let postListDataProvider = PostListDataProvider(topicId: topic.id,
                                                        topicTitle: topic.title,
                                                        apiClient: self.topicListDataProvider.apiClient,
                                                        cacheManager: self.topicListDataProvider.cacheManager)
        let postListCoordinator = PostListCoordinator(postListDataProvider: postListDataProvider, navigationController: self.navigationController)
        self.childCoordinators.append(postListCoordinator)

        postListCoordinator.start()
    }
}
