//
//  CategoryListDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import PromiseKit

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
    var items: [Category] {
        return self.categoryList?.categories ?? []
    }

    func fetch() {
        self.state = .loading

        firstly {
            self.apiClient.fetchCategoryList()
        }.done {
            self.state = .loaded
            self.categoryList = $0
            self.saveToCache()
        }.catch { error in
            self.state = .error(error)
        }.finally {
            NotificationCenter.default.post(name: self.didUpdateNotification, object: self)
        }
    }
}

private extension CategoryListDataProvider {
    enum CacheKeys {
        static let categoryListKey = "categories.json"
    }

    func loadFromCache() {
        firstly {
            self.cacheManager.loadJson(key: CacheKeys.categoryListKey)
        }.compactMap { cachedCategoryListJson in
            CategoryList.fromJson(json: cachedCategoryListJson)
        }.done { cachedCategoryList in
            self.categoryList = cachedCategoryList
            logDebug("Loaded \(cachedCategoryList.categories.count) categories from cache.")
        }.catch { error in
            // TODO: Handle JSON schema changes.
            logDebug("Could not load category list from cache.")
        }
    }

    func saveToCache() {
        guard let categoryList = self.categoryList, let json = categoryList.toJson() else { return }

        firstly {
            self.cacheManager.saveJson(json, key: CacheKeys.categoryListKey)
        }.done {
            logDebug("Saved \(categoryList.categories.count) categories to cache")
        }.catch { error in
            logError("Could not save category list to cache: \(error)")
        }
    }
}
