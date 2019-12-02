//
//  CategoryListDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

class CategoryListDataProvider: DataProvider {
    private let apiClient: APIClient
    private var categoryList: CategoryList?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - DataProvider

    typealias DataType = Category

    let didUpdateNotification = Notification.Name("CategoryListDataProviderDidUpdate")

    var state: DataProviderState = .unknown

    func fetch() {
        self.state = .loading
        self.apiClient.fetchCategoryList { result in
            switch result {
            case .success(let categoryList):
                self.state = .loaded
                self.categoryList = categoryList

            case .failure(let error):
                self.state = .error(error)
            }

            NotificationCenter.default.post(name: self.didUpdateNotification, object: self)
        }
    }

    func numberOfItems() -> Int {
        guard let categoryList = self.categoryList else {
            return 0
        }
        return categoryList.categories.count
    }

    func item(atIndexPath indexPath: IndexPath) -> Category? {
        guard let categoryList = self.categoryList else {
            return nil
        }
        return categoryList.categories[indexPath.row]
    }
}
