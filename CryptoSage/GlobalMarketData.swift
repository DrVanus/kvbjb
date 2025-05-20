//
//  GlobalMarketData.swift
//  CSAI1
//
//  Created by DM on 4/30/25.
//


// GlobalMarketData.swift
// Models the JSON returned by CoinGecko’s `/global` endpoint


import Foundation

/// Wrapper for CoinGecko’s `/global` endpoint.
public struct GlobalDataResponse: Codable {
    public let data: GlobalMarketData
}


/// Represents the “data” object inside the CoinGecko /global response.
public struct GlobalMarketData: Codable {
    /// Total market cap by currency (e.g. ["usd": 1.2e12])
    public let totalMarketCap: [String: Double]
    /// Total 24h volume by currency
    public let totalVolume: [String: Double]
    /// Market cap dominance percentages (e.g. ["btc": 48.2, "eth": 18.5])
    public let marketCapPercentage: [String: Double]
    /// 24h change in USD (%) for total market cap
    public let marketCapChange24hUSD: Double

    private enum CodingKeys: String, CodingKey {
        case totalMarketCap               = "total_market_cap"
        case totalVolume                  = "total_volume"
        case marketCapPercentage          = "market_cap_percentage"
        case marketCapChange24hUSD = "market_cap_change_percentage_24h_usd"
    }
}
