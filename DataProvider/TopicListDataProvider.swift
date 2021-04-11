//
//  TopicsDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/7/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import PromiseKit

class TopicListDataProvider: BaseDataProvider<TopicList> {

    let categoryId: Int
    let categoryName: String

    public let apiClient: APIClientInterface
    private let cacheManager: JsonCacheManagerInterface
//    private var topicList: TopicList?
    private var topicListCacheKey: String {
        return String(format: CacheKeys.topicListKeyFormat, self.categoryId)
    }

    init(categoryId: Int, categoryName: String, apiClient: APIClientInterface, cacheManager: JsonCacheManagerInterface) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.apiClient = apiClient
        self.cacheManager = cacheManager

        super.init()

        self.loadFromCache()
        self.requestFetch()
    }

    override var fetchPromise: Promise<TopicList> {
        return self.apiClient.fetchTopicList(withCategoryId: self.categoryId)
    }

    override func didReceiveUpdate(_ update: DataProviderState<TopicList>) {
        super.didReceiveUpdate(update)

        switch update {
        case .loaded(let newTopicList):
            self.saveToCache(topicList: newTopicList)

        case .unknown, .loading, .error:
            ()
        }
    }
}

private extension TopicListDataProvider {
    enum CacheKeys {
        static let topicListKeyFormat = "c/%d.json"
    }

    func loadFromCache() {
        firstly { () -> Promise<JSON> in
            self.subject.value = .loading(self.data)
            return self.cacheManager.loadJson(key: self.topicListCacheKey)
        }.compactMap { cachedtopicListJson in
            TopicList.fromJson(json: cachedtopicListJson)
        }.done { cachedtopicList in
            self.subject.value = .loaded(cachedtopicList)
            logDebug("Loaded \(cachedtopicList.topics.count) topics from cache for category \(self.categoryId)")
        }.catch { error in
            self.subject.value = .error(error)
            // TODO: Handle JSON schema changes.
            logDebug("Could not load topic list from cache for category \(self.categoryId)")
        }
    }

    func saveToCache(topicList: TopicList) {
        guard let json = topicList.toJson() else { return }

        firstly {
            self.cacheManager.saveJson(json, key: self.topicListCacheKey)
        }.done {
            logDebug("Saved \(topicList.topics.count) topics to cache for category \(self.categoryId)")
        }.catch { error in
            logDebug("Could not save topic list to cache for category \(self.categoryId): \(error)")
        }
    }
}
