//
// MarketCoin.swift
// CryptoSage
//

import Foundation

// MARK: - Sparkline helper
struct SparklineIn7D: Codable {
    let price: [Double]
}

/// Represents a single coin returned by the CoinGecko `/coins/markets` endpoint.
struct MarketCoin: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    var currentPrice: Double
    var priceChangePercentage24h: Double
    var totalVolume: Double
    var marketCap: Double
    var sparkline7d: SparklineIn7D?

    /// 1-hour price change percentage from API
    var priceChangePercentage1h: Double

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        // 24-hour price change percentage from API
        case priceChangePercentage24h = "price_change_percentage_24h_in_currency"
        case currentPrice             = "current_price"
        case totalVolume              = "total_volume"
        case marketCap                = "market_cap"
        case sparkline7d              = "sparkline_in_7d"
        case priceChangePercentage1h  = "price_change_percentage_1h_in_currency"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        image = try container.decode(String.self, forKey: .image)
        currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        totalVolume = try container.decode(Double.self, forKey: .totalVolume)
        marketCap = try container.decode(Double.self, forKey: .marketCap)
        sparkline7d = try? container.decode(SparklineIn7D.self, forKey: .sparkline7d)
        priceChangePercentage24h = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage24h) ?? 0
        priceChangePercentage1h = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage1h) ?? 0
    }

    /// Convenience alias for sparkline price array
    var sparklineData: [Double] {
        sparkline7d?.price ?? []
    }

    // MARK: - UI Compatibility Additions

    /// Local favorite flag for UI toggling
    var isFavorite: Bool = false

    /// Backward‐compatible properties for existing code
    var price: Double {
        get { currentPrice }
        set { currentPrice = newValue }
    }
    /// Mutable alias for sparkline array
    var sparklineDataMutable: [Double] {
        get { sparklineData }
        set { sparkline7d = SparklineIn7D(price: newValue) }
    }
    var dailyChange: Double { priceChangePercentage24h }
    /// Backward-compatibility for hourly change
    var hourlyChange: Double { priceChangePercentage1h }
    /// Safely create a URL by percent-encoding the image string
    var imageUrl: URL? {
        if let encodedString = image.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: encodedString)
        }
        return URL(string: image)
    }
    var finalImageUrl: URL? { imageUrl }

    /// Backward‑compatible alias for sparkline data array
    var sparkline: [Double] {
        sparklineData
    }

    /// Backward‑compatible alias for total volume
    var volume: Double {
        totalVolume
    }

    /// Convenience initializer to support manual `MarketCoin(...)` calls
    init(
        id: String,
        symbol: String,
        name: String,
        imageUrl: URL?,
        finalImageUrl: URL?,
        price: Double,
        dailyChange: Double,
        volume: Double,
        marketCap: Double,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        // Prefer the finalImageUrl if provided
        self.image = finalImageUrl?.absoluteString ?? ""
        self.currentPrice = price
        self.priceChangePercentage24h = dailyChange
        self.totalVolume = volume
        self.marketCap = marketCap
        // For manual coins, no sparkline data
        self.sparkline7d = nil
        self.isFavorite = isFavorite
        self.priceChangePercentage1h = 0
    }

    /// Convenience initializer for calls that pass image URL as String
    init(
        id: String,
        symbol: String,
        name: String,
        image: String,
        price: Double,
        dailyChange: Double,
        volume: Double,
        marketCap: Double,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.currentPrice = price
        self.priceChangePercentage24h = dailyChange
        self.totalVolume = volume
        self.marketCap = marketCap
        self.sparkline7d = nil
        self.priceChangePercentage1h = 0
        self.isFavorite = isFavorite
    }
}
