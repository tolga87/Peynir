//
//  TopicsDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/7/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

class TopicListDataProvider: DataProvider {
    let categoryId: Int

    private let apiClient: APIClientInterface
    private let cacheManager: CacheManagerInterface
    private var topicList: TopicList?

    init(categoryId: Int, apiClient: APIClientInterface, cacheManager: CacheManagerInterface) {
        self.categoryId = categoryId
        self.apiClient = apiClient
        self.cacheManager = cacheManager

        self.loadFromCache()
        self.fetch()
    }

    // MARK: - DataProvider

    typealias DataType = Topic

    let didUpdateNotification = Notification.Name("TopicsDataProviderDidUpdate")

    var state: DataProviderState = .unknown

    func fetch() {
        self.state = .loading
        self.apiClient.fetchTopicList(withCategoryId: self.categoryId) { result in
            switch result {
            case .success(let topicList):
                self.state = .loaded
                self.topicList = topicList
                self.saveToCache()

            case .failure(let error):
                self.state = .error(error)
            }

            NotificationCenter.default.post(name: self.didUpdateNotification, object: self)
        }
    }

    func numberOfItems() -> Int {
        guard let topicList = self.topicList else {
            return 0
        }
        return topicList.topics.count
    }

    func item(atIndexPath indexPath: IndexPath) -> Topic? {
        guard let topicList = self.topicList else {
            return nil
        }
        return topicList.topics[indexPath.row]
    }
}

private extension TopicListDataProvider {
    func loadFromCache() {
        if
            let cachedtopicListJson = self.cacheManager.loadJson(withId: self.cacheManager.keys.topicListKey).successValue,
            let cachedtopicList = TopicList.fromJson(json: cachedtopicListJson) {
                self.topicList = cachedtopicList
                logDebug("Loaded \(cachedtopicList.topics.count) topics from cache for category \(self.categoryId)")
        } else {
            logDebug("Could not load topic list from cache for category \(self.categoryId)")
        }
    }

    func saveToCache() {
        guard let topicList = self.topicList, let json = topicList.toJson() else { return }

        if let saveError = self.cacheManager.save(json: json, withId: self.cacheManager.keys.topicListKey) {
            logDebug("Could not save topic list to cache for category \(self.categoryId): \(saveError)")
        } else {
            logDebug("Saved \(topicList.topics.count) topics to cache for category \(self.categoryId)")
        }
    }
}
