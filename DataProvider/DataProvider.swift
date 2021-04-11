//
//  DataProvider.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import Foundation
import PromiseKit

public enum DataProviderState<DataType> {
    case unknown
    case loading(DataType?)
    case loaded(DataType)
    case error(Error)

    func getData() -> DataType? {
        switch self {
        case .unknown, .error:
            return nil
        case .loading(let data):
            return data
        case .loaded(let data):
            return data
        }
    }
}

public protocol DataProvider {
    associatedtype DataType

    var subject: CurrentValueSubject<DataProviderState<DataType>, Never> { get }
    var fetchPromise: Promise<DataType> { get }

    // If overridden by a subclass, the subclass should call this method on super.
    func requestFetch()
}

open class BaseDataProvider<DataType>: DataProvider {
    public typealias DataType = DataType

    open var data: DataType?
    open var fetchPromise: Promise<DataType> {
        return Promise(error: BaseDataProviderError.mustBeOverriddenBySubclass)
    }
    open var subject: CurrentValueSubject<DataProviderState<DataType>, Never> = CurrentValueSubject(.unknown)

    public init() {
        self.subject.receive(on: DispatchQueue.main).sink { [weak self] newState in
            self?.didReceiveUpdate(newState)
        }.store(in: &self.cancellables)
    }

    open func requestFetch() {
        self.subject.value = .loading(self.data)

        firstly {
            self.fetchPromise
        }.done(on: .main) { [weak self] data in
            self?.subject.value = .loaded(data)
        }.catch { [weak self] error in
            self?.subject.value = .error(error)
        }
    }

    open func didReceiveUpdate(_ update: DataProviderState<DataType>) {
        self.data = update.getData()
    }

    enum BaseDataProviderError: Error {
        case mustBeOverriddenBySubclass
    }

    // MARK: - Private

    private var cancellables: [AnyCancellable] = []

}
