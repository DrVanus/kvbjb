//
//  CoinGeckoMarketData.swift
//  CSAI1
//
//  Created by DM on 3/28/25.
//

import Foundation

struct CoinGeckoMarketData: Decodable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let totalVolume: Double
    let marketCap: Double
    let priceChangePercentage24H: Double?
    let priceChangePercentage1HInCurrency: Double?
    let sparklineIn7D: SparklineData?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice   = "current_price"
        case totalVolume    = "total_volume"
        case marketCap      = "market_cap"
        case priceChangePercentage24H     = "price_change_percentage_24h"
        case priceChangePercentage1HInCurrency = "price_change_percentage_1h_in_currency"
        case sparklineIn7D  = "sparkline_in_7d"
    }
}

struct SparklineData: Codable {
    let price: [Double]
}
