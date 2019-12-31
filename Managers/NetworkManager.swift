//
//  NetworkManager.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

public enum NetworkError: Error {
    case invalidUrl
    case invalidData
    case unknown
}

public typealias DataResourceResult = Result<Data, Error>
public typealias StringResourceResult = Result<String, Error>
public typealias JSONResourceResult = Result<JSON, Error>

public typealias DataResourceResultCallback = (DataResourceResult) -> Void
public typealias StringResourceResultCallback = (StringResourceResult) -> Void
public typealias JSONResourceResultCallback = (JSONResourceResult) -> Void

public protocol NetworkManagerInterface {
    var baseUrl: String { get }

    func getData(atUrl urlString: String, completion: DataResourceResultCallback?)
    func getString(atUrl urlString: String, completion: StringResourceResultCallback?)
    func getJson(atUrl urlString: String, completion: JSONResourceResultCallback?)
}

public class NetworkManager: NetworkManagerInterface {
    public let baseUrl = "https://cow.ceng.metu.edu.tr"

    public static let sharedInstance = NetworkManager()

    // `completion` will be called on the main thread.
    public func getData(atUrl urlString: String, completion: DataResourceResultCallback?) {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion?(.failure(NetworkError.invalidUrl)) }
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                let error = error ?? NetworkError.unknown
                DispatchQueue.main.async { completion?(.failure(error)) }
                return
            }

            DispatchQueue.main.async { completion?(.success(data)) }
        }

        task.resume()
    }

    public func getString(atUrl urlString: String, completion: StringResourceResultCallback?) {
        self.getData(atUrl: urlString) { result in
            guard
                let data = result.successValue,
                let string = String(data: data, encoding: .utf8) else {
                    completion?(.failure(NetworkError.invalidData))
                    return
            }
            completion?(.success(string))
        }
    }

    public func getJson(atUrl urlString: String, completion: JSONResourceResultCallback?) {
        self.getString(atUrl: urlString) { result in
            guard
                let string = result.successValue,
                let json = string.toJson() else {
                    completion?(.failure(NetworkError.invalidData))
                    return
            }
            completion?(.success(json))
        }
    }
}
