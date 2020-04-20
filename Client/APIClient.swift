//
//  APIClient.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import PromiseKit

enum APIError: Error {
    case badData
}

protocol APIClientInterface {
    func fetchCategoryList() -> Promise<CategoryList>
    func fetchTopicList(withCategoryId categoryId: Int) -> Promise<TopicList>
    func fetchPostList(withTopicId topicId: Int) -> Promise<PostList>
}

class APIClient: APIClientInterface {
    private let networkManager: NetworkManagerInterface

    init(networkManager: NetworkManagerInterface) {
        self.networkManager = networkManager
    }

    func fetchCategoryList() -> Promise<CategoryList> {
        let url = "\(self.networkManager.baseUrl)/categories.json"

        return firstly {
            self.networkManager.getJson(atUrl: url)
        }.compactMap { json in
            guard
                let categoryListJson = json["category_list"] as? JSON,
                let categoryList = CategoryList.fromJson(json: categoryListJson) else {
                    throw APIError.badData
            }

            return categoryList
        }
    }

    func fetchTopicList(withCategoryId categoryId: Int) -> Promise<TopicList> {
        let url = "\(self.networkManager.baseUrl)/c/\(categoryId).json"

        return firstly {
            self.fetchJson(atUrl: url)
        }.compactMap { json in
            guard
                let topicListJson = json["topic_list"] as? JSON,
                let topicList = TopicList.fromJson(json: topicListJson) else {
                    throw APIError.badData
            }
            return topicList
        }
    }

    func fetchPostList(withTopicId topicId: Int) -> Promise<PostList> {
        let url = "\(self.networkManager.baseUrl)/t/\(topicId).json"

        return firstly {
            self.fetchJson(atUrl: url)
        }.compactMap { json in
            guard
                let postListJson = json["post_stream"] as? JSON,
                let postList = PostList.fromJson(json: postListJson) else {
                    throw APIError.badData
            }
            return postList
        }
    }
}

private extension APIClient {
    func fetchJson(atUrl urlString: String) -> Promise<JSON> {
        self.networkManager.getJson(atUrl: urlString)
    }
}
