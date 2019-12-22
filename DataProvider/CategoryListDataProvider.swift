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
                logDebug("Loaded \(cachedCategoryList.categories.count) categories from cache.")
        } else {
            // TODO: Handle JSON schema changes.
            logDebug("Could not load category list from cache.")
        }
    }

    func saveToCache() {
        guard let categoryList = self.categoryList, let json = categoryList.toJson() else { return }

        if let saveError = self.cacheManager.save(json: json, withId: self.cacheManager.keys.categoryListKey) {
            logError("Could not save category list to cache: \(saveError)")
        } else {
            logDebug("Saved \(categoryList.categories.count) categories to cache")
        }
    }
}
