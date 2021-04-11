//
//  CategoryListViewModel.swift
//  Peynir
//
//  Created by Tolga AKIN on 4/11/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Combine
import Foundation

class CategoryListViewModel {
    enum State {
        case unknown
        case loading([CategoryListItemViewModel]?)
        case loaded([CategoryListItemViewModel])
        case error(Error)
    }

    private(set) var subject: CurrentValueSubject<State, Never> = CurrentValueSubject(.unknown)
    private let dataProvider: CategoryListDataProvider
    private var cancellables: [AnyCancellable] = []

    private func state(from state: DataProviderState<CategoryList>) -> State {
        switch state {
        case .unknown:
            return .unknown
        case .error(let error):
            return .error(error)
        case .loading(let categoryList):
            return .loading(categoryList?.categories.map { CategoryListItemViewModel.fromCategory($0) } ?? [])
        case .loaded(let categoryList):
            return .loaded(categoryList.categories.map { CategoryListItemViewModel.fromCategory($0) })
        }
    }

    init(dataProvider: CategoryListDataProvider) {
        self.dataProvider = dataProvider

        self.dataProvider.subject
            .receive(on: DispatchQueue.main)
            .map { self.state(from: $0) }
            .sink {
                self.subject.value = $0
            }.store(in: &self.cancellables)
    }
}

private extension CategoryListItemViewModel {
    static func fromCategory(_ category: Category) -> Self {
        return CategoryListItemViewModel(name: category.name,
                                         color: category.color,
                                         numTopics: category.topicsAllTime)
    }
}
