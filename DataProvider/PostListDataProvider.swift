//
//  PostListDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import PromiseKit

class PostListDataProvider: BaseDataProvider<PostList> {

    let topicId: Int
    let topicTitle: String

    public let apiClient: APIClientInterface
    public let cacheManager: CacheManagerInterface
//    private var postList: PostList? {
//        didSet {
//            if postList != oldValue {
//                self.saveToCache()
//                NotificationCenter.default.post(name: self.didUpdateNotification, object: self)
//            }
//        }
//    }
    private var postListCacheKey: String {
        return String(format: CacheKeys.postListKeyFormat, self.topicId)
    }

    init(topicId: Int, topicTitle: String, apiClient: APIClientInterface, cacheManager: CacheManagerInterface) {
        self.topicId = topicId
        self.topicTitle = topicTitle
        self.apiClient = apiClient
        self.cacheManager = cacheManager

        super.init()

        self.loadFromCache()
        self.requestFetch()
    }

    // MARK: - DataProvider

    override func requestFetch() {
        super.requestFetch()

        firstly {
            self.apiClient.fetchPostList(withTopicId: self.topicId)
        }.done { newPostList in
            self.subject.value = .loaded(newPostList)
        }.catch { error in
            self.subject.value = .error(error)
        }
    }

    override func didReceiveUpdate(_ update: DataProviderState<PostList>) {
        super.didReceiveUpdate(update)

        switch update {
        case .loaded:
            self.saveToCache()

        case .unknown, .loading, .error:
            ()
        }
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
            self.subject.value = .loaded(postList)
            logDebug("Loaded \(postList.posts.count) posts from cache.")
        }.catch { error in
            self.subject.value = .error(error)
            // TODO: Handle JSON schema changes.
            logDebug("Could not load post list from cache.")
        }
    }

    func saveToCache() {
        guard let postList = self.subject.value.getData(), let json = postList.toJson() else { return }

        firstly {
            self.cacheManager.saveJson(json, key: self.postListCacheKey)
        }.done {
            logDebug("Saved \(postList.posts.count) posts to cache")
        }.catch { error in
            logError("Could not save post list to cache: \(error)")
        }
    }
}


