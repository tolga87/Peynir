//
//  PostListDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

class PostListDataProvider: DataProvider {
    let topicId: Int
    let topicTitle: String

    public let apiClient: APIClientInterface
    public let cacheManager: CacheManagerInterface
    private var postList: PostList?

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
        self.apiClient.fetchPostList(withTopicId: self.topicId) { result in
            switch result {
            case .success(let postList):
                self.state = .loaded
                self.postList = postList
                self.saveToCache()

            case .failure(let error):
                self.state = .error(error)
            }

            NotificationCenter.default.post(name: self.didUpdateNotification, object: self)
        }
    }

    func numberOfItems() -> Int {
        guard let postList = self.postList else {
            return 0
        }
        return postList.posts.count
    }

    func item(atIndexPath indexPath: IndexPath) -> Post? {
        guard let postList = self.postList else {
            return nil
        }
        return postList.posts[indexPath.row]
    }

    // MARK: - DataProvider

    typealias DataType = Post

    let didUpdateNotification = Notification.Name("PostsDataProviderDidUpdate")

    var state: DataProviderState = .unknown
}

private extension PostListDataProvider {
    func loadFromCache() {
        if
            let cachedPostListJson = self.cacheManager.loadJson(withId: self.cacheManager.keys.postListKeyFormat).successValue,
            let cachedPostList = PostList.fromJson(json: cachedPostListJson) {
                self.postList = cachedPostList
                logDebug("Loaded \(cachedPostList.posts.count) categories from cache.")
        } else {
            // TODO: Handle JSON schema changes.
            logDebug("Could not load post list from cache.")
        }
    }

    func saveToCache() {
        guard let postList = self.postList, let json = postList.toJson() else { return }

        if let saveError = self.cacheManager.save(json: json, withId: self.cacheManager.keys.postListKeyFormat) {
            logError("Could not save post list to cache: \(saveError)")
        } else {
            logDebug("Saved \(postList.posts.count) categories to cache")
        }
    }
}

