//
//  NewsAPIResponse.swift
//  CryptoSage
//
//  Created by DM on 5/25/25.
//


import Foundation

// MARK: – NewsAPI response wrapper
private struct NewsAPIResponse: Decodable {
    let status: String
    let totalResults: Int
    let articles: [CryptoNewsArticle]
}

/// A service for fetching crypto news from NewsAPI.org
class CryptoNewsFeedService {
    private let apiKey = "fe1702f65ad54c4aa51b209b54f8ba3f"
    private let session = URLSession.shared

    /// Fetch the latest crypto news (full list).
    func fetchLatestNews() async throws -> [CryptoNewsArticle] {
        try await fetchNews(pageSize: 50)
    }

    /// Fetch a preview list of crypto news (e.g., first 5).
    func fetchPreviewNews() async throws -> [CryptoNewsArticle] {
        try await fetchNews(pageSize: 5)
    }

    /// Internal helper to call the NewsAPI endpoint.
    private func fetchNews(pageSize: Int) async throws -> [CryptoNewsArticle] {
        // Construct URLComponents for the HTTPS endpoint
        var components = URLComponents(string: "https://newsapi.org/v2/everything")!
        components.queryItems = [
            URLQueryItem(name: "q",         value: "crypto"),
            URLQueryItem(name: "sortBy",    value: "publishedAt"),
            URLQueryItem(name: "pageSize",  value: "\(pageSize)"),
            URLQueryItem(name: "apiKey",    value: apiKey)
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        // Perform network request
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Decode using ISO8601 for publishedAt
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let apiResponse = try decoder.decode(NewsAPIResponse.self, from: data)
        return apiResponse.articles
    }
}