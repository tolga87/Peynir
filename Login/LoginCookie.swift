//
//  LoginCookie.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

class LoginCookie: Codable {
    let httpCookie: HTTPCookie
    private let headers: [String: String]
    private let url: URL

    init?(headers: [String: String], url: URL) {
        guard let cookie = LoginCookie.httpCookie(fromHeaders: headers, url: url) else {
            return nil
        }

        self.headers = headers
        self.url = url
        self.httpCookie = cookie
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case headers, url, httpCookie
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.headers, forKey: .headers)
        try container.encode(self.url, forKey: .url)
    }

    // MARK: - Decodable

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.headers = try container.decode([String: String].self, forKey: .headers)
        self.url = try container.decode(URL.self, forKey: .url)

        guard let httpCookie = LoginCookie.httpCookie(fromHeaders: self.headers, url: self.url) else {
            throw LoginCookieDecodingError()
        }
        self.httpCookie = httpCookie
    }
}

extension LoginCookie: JSONConstructable {
    static func fromJson(json: JSON) -> Self? {
        return nil  //~TA
    }
}

private extension LoginCookie {
    static func httpCookie(fromHeaders headers: [String: String], url: URL) -> HTTPCookie? {
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        guard let cookie = cookies.first else {
            return nil
        }

        return cookie
    }
}

class LoginCookieDecodingError: Error {
}
