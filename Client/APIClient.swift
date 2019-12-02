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

typealias CategoryListCallback = (Result<CategoryList, Error>) -> Void

class APIClient {
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
}
