//
//  NetworkManager.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import PromiseKit

public enum NetworkError: Error {
    case invalidUrl
    case invalidData
    case unknown
}

public protocol NetworkManagerInterface {
    var baseUrl: String { get }

    func getData(atUrl urlString: String) -> Promise<Data>
    func getString(atUrl urlString: String) -> Promise<String>
    func getJson(atUrl urlString: String) -> Promise<JSON>
}

public class NetworkManager: NetworkManagerInterface {
    public let baseUrl = "https://cow.ceng.metu.edu.tr"

    public static let sharedInstance = NetworkManager()

    public func getData(atUrl urlString: String) -> Promise<Data> {
        return Promise<Data> { seal in
            guard let url = URL(string: urlString) else {
                seal.reject(NetworkError.invalidUrl)
                return
            }

            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else {
                    let error = error ?? NetworkError.unknown
                    seal.reject(error)
                    return
                }

                seal.fulfill(data)
            }

            task.resume()
        }
    }

    public func getString(atUrl urlString: String) -> Promise<String> {
        return firstly {
            self.getData(atUrl: urlString)
        }.compactMap {
            guard let string = String(data: $0, encoding: .utf8) else {
                throw NetworkError.invalidData
            }
            return string
        }
    }


    public func getJson(atUrl urlString: String) -> Promise<JSON> {
        return firstly {
            self.getString(atUrl: urlString)
        }.compactMap {
            guard let json = $0.toJson() else {
                throw NetworkError.invalidData
            }
            return json
        }
    }
}
