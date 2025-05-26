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
