//
//  CategoryListDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

class CategoryListDataProvider: DataProvider {
    public let apiClient: APIClientInterface
    public let cacheManager: CacheManagerInterface
    private var categoryList: CategoryList?

    init(apiClient: APIClientInterface, cacheManager: CacheManagerInterface) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager

        self.loadFromCache()
        self.fetch()
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
                self.saveToCache()

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

private extension CategoryListDataProvider {
    func loadFromCache() {
        if
            let cachedCategoryListJson = self.cacheManager.loadJson(withId: self.cacheManager.keys.categoryListKey).successValue,
            let cachedCategoryList = CategoryList.fromJson(json: cachedCategoryListJson) {
                self.categoryList = cachedCategoryList
                print("ℹ️ Loaded category list from cache.")
        } else {
            print("ℹ️ Coult not load category list from cache.")
        }
    }

    func saveToCache() {
        var saveError: Error?

        if let categoryList = self.categoryList, let json = categoryList.toJson() {
            saveError = self.cacheManager.save(json: json, withId: self.cacheManager.keys.categoryListKey)
        }

        if let saveError = saveError {
            print("ℹ️ Coult not save category list to cache: \(saveError)")
        } else {
            print("ℹ️ Saved category list to cache")
        }
    }
}
