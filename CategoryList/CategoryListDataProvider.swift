//
//  CategoryListDataProvider.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import PromiseKit

class CategoryListDataProvider: BaseDataProvider<CategoryList> {

    // TODO: Fix these public properties.
    public let apiClient: APIClientInterface
    public let cacheManager: JsonCacheManagerInterface

    init(apiClient: APIClientInterface, cacheManager: JsonCacheManagerInterface) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager

        super.init()

        self.loadFromCache()
        self.requestFetch()
    }

    // MARK: - DataProvider

    override var fetchPromise: Promise<CategoryList> {
        return self.apiClient.fetchCategoryList()
    }

    override func didReceiveUpdate(_ update: DataProviderState<CategoryList>) {
        super.didReceiveUpdate(update)

        switch update {
        case .loaded(let newCategoryList):
            self.saveToCache(categoryList: newCategoryList)

        case .unknown, .loading, .error:
            ()
        }
    }
}

private extension CategoryListDataProvider {
    enum CacheKeys {
        static let categoryListKey = "categories.json"
    }

    func loadFromCache() {
        firstly { () -> Promise<JSON> in
            self.subject.value = .loading(self.data)
            return self.cacheManager.loadJson(key: CacheKeys.categoryListKey)
        }.compactMap { cachedCategoryListJson in
            CategoryList.fromJson(json: cachedCategoryListJson)
        }.done { cachedCategoryList in
            self.subject.value = .loaded(cachedCategoryList)
            logDebug("Loaded \(cachedCategoryList.categories.count) categories from cache.")
        }.catch { error in
            self.subject.value = .error(error)
            // TODO: Handle JSON schema changes.
            logDebug("Could not load category list from cache.")
        }
    }

    func saveToCache(categoryList: CategoryList) {
        guard let json = categoryList.toJson() else { return }

        firstly {
            self.cacheManager.saveJson(json, key: CacheKeys.categoryListKey)
        }.done {
            logDebug("Saved \(categoryList.categories.count) categories to cache")
        }.catch { error in
            logError("Could not save category list to cache: \(error)")
        }
    }
}
