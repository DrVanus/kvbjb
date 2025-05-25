import Foundation

final class CryptoAPIService {
    static let shared = CryptoAPIService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()

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
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let wrapper = try decoder.decode(GlobalDataResponse.self, from: data)
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

    func fetchCoinMarkets() async throws -> [MarketCoin] {
        var components = URLComponents(string: "https://api.coingecko.com/api/v3/coins/markets")!
        components.queryItems = [
            URLQueryItem(name: "vs_currency",              value: "usd"),
            URLQueryItem(name: "order",                    value: "market_cap_desc"),
            URLQueryItem(name: "per_page",                 value: "20"),
            URLQueryItem(name: "page",                     value: "1"),
            URLQueryItem(name: "sparkline",                value: "true"),
            URLQueryItem(name: "price_change_percentage",  value: "1h,24h")
        ]
        let url = components.url!
        print("▶️ fetchCoinMarkets() →", url)

        var attempts = 0
        var lastError: Error?
        while attempts < 2 {
            do {
                let (data, response) = try await session.data(from: url)
                print("✅ fetchCoinMarkets: received \(data.count) bytes from \(url)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 fetchCoinMarkets JSON:", jsonString)
                }
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode([MarketCoin].self, from: data)
            } catch let urlError as URLError where urlError.code == .timedOut {
                attempts += 1; lastError = urlError
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                throw error
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    func fetchWatchlistMarkets(ids: [String]) async throws -> [MarketCoin] {
        guard !ids.isEmpty else { return [] }
        let idList = ids.joined(separator: ",")
        var components = URLComponents(string: "https://api.coingecko.com/api/v3/coins/markets")!
        components.queryItems = [
            URLQueryItem(name: "vs_currency",             value: "usd"),
            URLQueryItem(name: "ids",                     value: idList),
            URLQueryItem(name: "order",                   value: "market_cap_desc"),
            URLQueryItem(name: "sparkline",               value: "true"),
            URLQueryItem(name: "price_change_percentage", value: "1h,24h")
        ]
        let url = components.url!
        print("▶️ fetchWatchlistMarkets() →", url)

        var attempts = 0
        var lastError: Error?
        while attempts < 2 {
            do {
                let (data, response) = try await session.data(from: url)
                print("✅ fetchWatchlistMarkets: received \(data.count) bytes from \(url)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 fetchWatchlistMarkets JSON:", jsonString)
                }
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode([MarketCoin].self, from: data)
            } catch let urlError as URLError where urlError.code == .timedOut {
                attempts += 1; lastError = urlError
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                throw error
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    // Add other purely data‐focused API methods below.
}
