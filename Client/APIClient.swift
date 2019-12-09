//
//  APIClient.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

enum APIError: Error {
    case badData
}

private typealias JSONCallback = (Result<JSON, Error>) -> Void
typealias CategoryListCallback = (Result<CategoryList, Error>) -> Void
typealias TopicListCallback = (Result<TopicList, Error>) -> Void

protocol APIClientInterface {
    func fetchCategoryList(completion: CategoryListCallback?)
    func fetchTopicList(withCategoryId categoryId: Int, completion: TopicListCallback?)
}

class APIClient: APIClientInterface {
    private let networkManager: NetworkManagerInterface

    init(networkManager: NetworkManagerInterface) {
        self.networkManager = networkManager
    }

    func fetchCategoryList(completion: CategoryListCallback?) {
        let url = "\(self.networkManager.baseUrl)/categories.json"
        self.networkManager.getJson(atUrl: url) { result in
            switch result {
            case .success(let json):
                guard
                    let categoryListJson = json["category_list"] as? JSON,
                    let categoryList = CategoryList.fromJson(json: categoryListJson) else {
                        completion?(.failure(APIError.badData))
                        return
                }

                completion?(.success(categoryList))

            case .failure(let error):
                completion?(.failure(error))
                return
            }
        }
    }

    func fetchTopicList(withCategoryId categoryId: Int, completion: TopicListCallback?) {
        let url = "\(self.networkManager.baseUrl)/c/\(categoryId).json"
        self.fetchJson(atUrl: url) { result in
            switch result {
            case .success(let json):
                guard
                    let topicListJson = json["topic_list"] as? JSON,
                    let topicList = TopicList.fromJson(json: topicListJson) else {
                        completion?(.failure(APIError.badData))
                        return
                }
                completion?(.success(topicList))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
}

private extension APIClient {
    func fetchJson(atUrl urlString: String, completion: JSONCallback?) {
        self.networkManager.getJson(atUrl: urlString) { result in
            switch result {
            case .success(let json):
                completion?(.success(json))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
}
