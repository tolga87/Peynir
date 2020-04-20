//
//  TopicsDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/7/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import PromiseKit

class TopicListDataProvider: DataProvider {
    let categoryId: Int
    let categoryName: String

    public let apiClient: APIClientInterface
    public let cacheManager: CacheManagerInterface
    private var topicList: TopicList?
    private var topicListCacheKey: String {
        return String(format: self.cacheManager.keys.topicListKeyFormat, self.categoryId)
    }

    init(categoryId: Int, categoryName: String, apiClient: APIClientInterface, cacheManager: CacheManagerInterface) {
        self.categoryId = categoryId
        self.categoryName = categoryName
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

        firstly {
            self.apiClient.fetchTopicList(withCategoryId: self.categoryId)
        }.done {
            self.state = .loaded
            self.topicList = $0
            self.saveToCache()
        }.catch { error in
            self.state = .error(error)
        }.finally {
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
            let cachedtopicListJson = self.cacheManager.loadJson(withId: self.topicListCacheKey).successValue,
            let cachedtopicList = TopicList.fromJson(json: cachedtopicListJson) {
                self.topicList = cachedtopicList
                logDebug("Loaded \(cachedtopicList.topics.count) topics from cache for category \(self.categoryId)")
        } else {
            logDebug("Could not load topic list from cache for category \(self.categoryId)")
            // TODO: Handle JSON schema changes.
        }
    }

    func saveToCache() {
        guard let topicList = self.topicList, let json = topicList.toJson() else { return }

        if let saveError = self.cacheManager.save(json: json, withId: self.topicListCacheKey) {
            logDebug("Could not save topic list to cache for category \(self.categoryId): \(saveError)")
        } else {
            logDebug("Saved \(topicList.topics.count) topics to cache for category \(self.categoryId)")
        }
    }
}
