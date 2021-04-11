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
    private let cacheManager: CacheManagerInterface

    init(topicListDataProvider: TopicListDataProvider, cacheManager: CacheManagerInterface, navigationController: UINavigationController) {
        self.topicListDataProvider = topicListDataProvider
        self.cacheManager = cacheManager
        self.navigationController = navigationController
    }

    func start(completion: CoordinatorCompletionCallback?) {
        let categoryListViewController = TopicListViewController(
            // dataProvider: topicListDataProvider
        )
//        categoryListViewController.actionHandler = self
        self.navigationController.pushViewController(categoryListViewController, animated: true)
    }
}

extension TopicListCoordinator: TopicListActionHandler {
    func didSelectTopic(_ topic: Topic) {
        let postListDataProvider = PostListDataProvider(topicId: topic.id,
                                                        topicTitle: topic.title,
                                                        apiClient: self.topicListDataProvider.apiClient,
                                                        cacheManager: self.cacheManager)
        let postListCoordinator = PostListCoordinator(postListDataProvider: postListDataProvider,
                                                      cacheManager: self.cacheManager,
                                                      navigationController: self.navigationController)
        self.childCoordinators.append(postListCoordinator)

        postListCoordinator.start { result in
            if let result = result {
                logDebug(result)
            }

            guard self.childCoordinators.count > 0 else {
                logError("TopicListCoordinator has no child coordinators")
                return
            }
            self.childCoordinators.removeLast()
        }
    }
}
