//
//  PostListDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import PromiseKit

class PostListDataProvider: DataProvider {
    let topicId: Int
    let topicTitle: String

    public let apiClient: APIClientInterface
    public let cacheManager: CacheManagerInterface
    private var postList: PostList? {
        didSet {
            if postList != oldValue {
                self.saveToCache()
                NotificationCenter.default.post(name: self.didUpdateNotification, object: self)
            }
        }
    }
    private var postListCacheKey: String {
        return String(format: CacheKeys.postListKeyFormat, self.topicId)
    }

    init(topicId: Int, topicTitle: String, apiClient: APIClientInterface, cacheManager: CacheManagerInterface) {
        self.topicId = topicId
        self.topicTitle = topicTitle
        self.apiClient = apiClient
        self.cacheManager = cacheManager

        self.loadFromCache()
        self.fetch()
    }

    func fetch() {
        self.state = .loading

        firstly {
            self.apiClient.fetchPostList(withTopicId: self.topicId)
        }.done { newPostList in
            self.state = .loaded
            self.postList = newPostList
        }.catch { error in
            self.state = .error(error)
            NotificationCenter.default.post(name: self.didUpdateNotification, object: self)
        }
    }

    // MARK: - DataProvider

    typealias DataType = Post

    let didUpdateNotification = Notification.Name("PostsDataProviderDidUpdate")

    var state: DataProviderState = .unknown
    var items: [Post] {
        return self.postList?.posts ?? []
    }
}

private extension PostListDataProvider {
    enum CacheKeys {
        static let postListKeyFormat = "t/%d.json"
    }

    func loadFromCache() {
        firstly {
            self.cacheManager.loadJson(key: self.postListCacheKey)
        }.compactMap { json in
            PostList.fromJson(json: json)
        }.done { postList in
            self.postList = postList
            logDebug("Loaded \(postList.posts.count) posts from cache.")
        }.catch { _ in
            // TODO: Handle JSON schema changes.
            logDebug("Could not load post list from cache.")
        }
    }

    func saveToCache() {
        guard let postList = self.postList, let json = postList.toJson() else { return }

        firstly {
            self.cacheManager.saveJson(json, key: self.postListCacheKey)
        }.done {
            logDebug("Saved \(postList.posts.count) posts to cache")
        }.catch { error in
            logError("Could not save post list to cache: \(error)")
        }
    }
}


