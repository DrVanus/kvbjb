import Foundation

final class CryptoAPIService {
    static let shared = CryptoAPIService()
    private init() {}

    /// Fetches global market data from the CoinGecko `/global` endpoint.
    func fetchGlobalData() async throws -> GlobalMarketData {
        let url = URL(string: "https://api.coingecko.com/api/v3/global")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let wrapper = try JSONDecoder().decode(GlobalMarketDataResponse.self, from: data)
        return wrapper.data
    }

    /// Fetches top coin market data from the CoinGecko `/coins/markets` endpoint.
    func fetchCoinMarkets() async throws -> [MarketCoin] {
        let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([MarketCoin].self, from: data)
    }

    // Add other purely data‐focused API methods below.
}
