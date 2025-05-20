import Foundation

final class CryptoAPIService {
    static let shared = CryptoAPIService()
    private init() {}

    /// Fetches global market data from the CoinGecko `/global` endpoint.
    func fetchGlobalData() async throws -> GlobalMarketData {
        print("▶️ fetchGlobalData() called")
        let url = URL(string: "https://api.coingecko.com/api/v3/global")!
        var attempts = 0
        var lastError: Error?
        while attempts < 2 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 fetchGlobalData JSON:", jsonString)
                }
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let wrapper = try JSONDecoder().decode(GlobalDataResponse.self, from: data)
                return wrapper.data
            } catch let urlError as URLError where urlError.code == .timedOut {
                attempts += 1
                lastError = urlError
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                throw error
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    /// Fetches top coin market data from the CoinGecko `/coins/markets` endpoint.
    func fetchCoinMarkets() async throws -> [MarketCoin] {
        let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false&price_change_percentage=24h")!
        var attempts = 0
        var lastError: Error?
        while attempts < 2 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([MarketCoin].self, from: data)
            } catch let urlError as URLError where urlError.code == .timedOut {
                attempts += 1
                lastError = urlError
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                throw error
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    // Add other purely data‐focused API methods below.
}
