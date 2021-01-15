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
    private let cacheManager: JsonCacheManagerInterface
    private var topicList: TopicList?
    private var topicListCacheKey: String {
        return String(format: CacheKeys.topicListKeyFormat, self.categoryId)
    }

    init(categoryId: Int, categoryName: String, apiClient: APIClientInterface, cacheManager: JsonCacheManagerInterface) {
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
    var items: [Topic] {
        return self.topicList?.topics ?? []
    }

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
}

private extension TopicListDataProvider {
    enum CacheKeys {
        static let topicListKeyFormat = "c/%d.json"
    }

    func loadFromCache() {
        firstly {
            self.cacheManager.loadJson(key: self.topicListCacheKey)
        }.compactMap { cachedtopicListJson in
            TopicList.fromJson(json: cachedtopicListJson)
        }.done { cachedtopicList in
            self.topicList = cachedtopicList
            logDebug("Loaded \(cachedtopicList.topics.count) topics from cache for category \(self.categoryId)")
        }.catch { error in
            // TODO: Handle JSON schema changes.
            logDebug("Could not load topic list from cache for category \(self.categoryId)")
        }
    }

    func saveToCache() {
        guard let topicList = self.topicList, let json = topicList.toJson() else { return }

        firstly {
            self.cacheManager.saveJson(json, key: self.topicListCacheKey)
        }.done {
            logDebug("Saved \(topicList.topics.count) topics to cache for category \(self.categoryId)")
        }.catch { error in
            logDebug("Could not save topic list to cache for category \(self.categoryId): \(error)")
        }
    }
}
