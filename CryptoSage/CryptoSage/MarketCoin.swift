//
// MarketCoin.swift
// CryptoSage
//

import Foundation

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
    var sparklineIn7d: [Double]?

    /// 1-hour price change percentage from API
    var priceChangePercentage1h: Double?

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice             = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case totalVolume              = "total_volume"
        case marketCap                = "market_cap"
        case sparklineIn7d            = "sparkline_in_7d"
        case priceChangePercentage1h  = "price_change_percentage_1h_in_currency"
    }

    // The `sparkline_in_7d` JSON is an object containing a `price` array.
    // We decode it as a nested container:
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id                          = try container.decode(String.self, forKey: .id)
        symbol                      = try container.decode(String.self, forKey: .symbol)
        name                        = try container.decode(String.self, forKey: .name)
        image                       = try container.decode(String.self, forKey: .image)
        currentPrice                = try container.decode(Double.self, forKey: .currentPrice)
        priceChangePercentage24h    = try container.decode(Double.self, forKey: .priceChangePercentage24h)
        totalVolume                 = try container.decode(Double.self, forKey: .totalVolume)
        marketCap                   = try container.decode(Double.self, forKey: .marketCap)
        priceChangePercentage1h     = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage1h)

        if let sparklineContainer = try? container.nestedContainer(keyedBy: SparklineKeys.self, forKey: .sparklineIn7d) {
            sparklineIn7d = try sparklineContainer.decodeIfPresent([Double].self, forKey: .price)
        } else {
            sparklineIn7d = nil
        }
    }

    private enum SparklineKeys: String, CodingKey {
        case price
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
    var sparklineData: [Double] {
        get { sparklineIn7d ?? [] }
        set { sparklineIn7d = newValue }
    }
    var dailyChange: Double { priceChangePercentage24h }
    /// Backward-compatibility for hourly change
    var hourlyChange: Double { priceChangePercentage1h ?? 0 }
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
        sparklineIn7d ?? []
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
        self.sparklineIn7d = nil
        self.isFavorite = isFavorite
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
        self.sparklineIn7d = nil
        self.priceChangePercentage1h = nil
        self.isFavorite = isFavorite
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(image, forKey: .image)
        try container.encode(currentPrice, forKey: .currentPrice)
        try container.encode(priceChangePercentage24h, forKey: .priceChangePercentage24h)
        try container.encode(totalVolume, forKey: .totalVolume)
        try container.encode(marketCap, forKey: .marketCap)
        try container.encodeIfPresent(priceChangePercentage1h, forKey: .priceChangePercentage1h)
        if let sparkline = sparklineIn7d {
            var sparklineContainer = container.nestedContainer(keyedBy: SparklineKeys.self, forKey: .sparklineIn7d)
            try sparklineContainer.encode(sparkline, forKey: .price)
        }
    }
}
