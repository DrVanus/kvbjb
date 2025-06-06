//
//  CryptoNewsResponse.swift
//  CryptoSage
//
//  Created by DM on 5/26/25.
//


//
//  CryptoNewsFeedService.swift
//  CryptoSage
//

import Foundation
import Combine

// MARK: – NewsAPI response wrapper
private struct CryptoNewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [CryptoNewsArticle]
}

final class CryptoNewsFeedService {
    // ← your NewsAPI key
    private let apiKey = "fe1702f65ad54c4aa51b209b54f8ba3f"
    private let baseURL = URL(string: "https://newsapi.org/v2/top-headlines")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Combine publisher version
    func fetchNewsPublisher() -> AnyPublisher<[CryptoNewsArticle], Error> {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "category",   value: "technology"),
            .init(name: "language",   value: "en"),
            .init(name: "apiKey",     value: apiKey)
        ]
        let request = URLRequest(url: components.url!)

        return session
            .dataTaskPublisher(for: request)
            .tryMap { data, resp in
                guard let http = resp as? HTTPURLResponse,
                      200..<300 ~= http.statusCode
                else { throw URLError(.badServerResponse) }
                return data
            }
            .decode(type: CryptoNewsResponse.self, decoder: JSONDecoder())
            .map(\.articles)
            .eraseToAnyPublisher()
    }

    /// Completion handler fallback
    func fetchNews(completion: @escaping (Result<[CryptoNewsArticle], Error>) -> Void) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "category",   value: "technology"),
            .init(name: "language",   value: "en"),
            .init(name: "apiKey",     value: apiKey)
        ]
        let request = URLRequest(url: components.url!)

        session.dataTask(with: request) { data, resp, err in
            if let err = err {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            guard let http = resp as? HTTPURLResponse,
                  200..<300 ~= http.statusCode
            else {
                DispatchQueue.main.async { completion(.failure(URLError(.badServerResponse))) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(URLError(.unknown))) }
                return
            }
            do {
                let wrapped = try JSONDecoder().decode(CryptoNewsResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(wrapped.articles)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}