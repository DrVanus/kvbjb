import Foundation
import Combine

@MainActor
/// ViewModel responsible for fetching and providing market data (coins + global summary).
final class MarketViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var coins: [MarketCoin] = []
    @Published var globalData: GlobalMarketData?

    // MARK: - Market Stats Computed Properties

    /// Total market cap in USD
    var marketCapUSD: Double {
        globalData?.totalMarketCap["usd"] ?? 0
    }

    /// Total 24h volume in USD
    var volume24hUSD: Double {
        globalData?.totalVolume["usd"] ?? 0
    }

    /// Bitcoin dominance percentage
    var btcDominance: Double {
        globalData?.marketCapPercentage["btc"] ?? 0
    }

    /// Ethereum dominance percentage
    var ethDominance: Double {
        globalData?.marketCapPercentage["eth"] ?? 0
    }
    @Published var isLoadingCoins: Bool = false
    @Published var isLoadingGlobal: Bool = false
    @Published var coinError: String?
    @Published var globalError: String?
    @Published var favoriteIDs: Set<String> = []

    // MARK: - UI State
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    @Published var selectedSegment: MarketSegment = .all
    @Published var sortField: SortField = .coin
    @Published var sortDirection: SortDirection = .desc
    @Published var filteredCoins: [MarketCoin] = []

    // MARK: - Computed Market Lists

    /// Top 10 trending coins by 24h volume (excluding stablecoins)
    var trendingCoins: [MarketCoin] {
        let nonStable = coins.filter { !stableSymbols.contains($0.symbol.uppercased()) }
        return Array(nonStable
            .sorted { $0.volume > $1.volume }
            .prefix(10))
    }

    /// Top 10 gainers by 24h percent change
    var topGainers: [MarketCoin] {
        Array(coins
            .sorted { $0.priceChangePercentage24h > $1.priceChangePercentage24h }
            .prefix(10))
    }

    /// Top 10 losers by 24h percent change
    var topLosers: [MarketCoin] {
        Array(coins
            .sorted { $0.priceChangePercentage24h < $1.priceChangePercentage24h }
            .prefix(10))
    }

    // MARK: - Filtering & Sorting
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }

    func toggleSort(for field: SortField) {
        if sortField == field {
            sortDirection = (sortDirection == .asc ? .desc : .asc)
        } else {
            sortField = field
            sortDirection = .asc
        }
        applyAllFiltersAndSort()
    }

    func applyAllFiltersAndSort() {
        var temp = coins

        // Segment filtering
        switch selectedSegment {
        case .all:
            break
        case .trending:
            temp = trendingCoins
        case .gainers:
            temp = topGainers
        case .losers:
            temp = topLosers
        case .favorites:
            temp = coins.filter { favoriteIDs.contains($0.id) }
        }

        // Search filtering
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            temp = temp.filter {
                $0.name.lowercased().contains(query) ||
                $0.symbol.lowercased().contains(query)
            }
        }

        // Sorting
        temp.sort { a, b in
            let ordered: Bool
            switch sortField {
            case .coin:
                ordered = a.name.lowercased() < b.name.lowercased()
            case .price:
                ordered = a.price < b.price
            case .dailyChange:
                ordered = a.priceChangePercentage24h < b.priceChangePercentage24h
            case .volume:
                ordered = a.volume < b.volume
            case .marketCap:
                ordered = a.marketCap < b.marketCap
            }
            return sortDirection == .asc ? ordered : !ordered
        }

        filteredCoins = temp
    }

    // MARK: - Private
    private let session: URLSession
    private let cacheURL: URL
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    /// Symbols to exclude from top gainers/losers
    private let stableSymbols: Set<String> = ["USDT","USDC","BUSD","DAI"]

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheURL = caches.appendingPathComponent("market_coins.json")

        loadCachedCoins()
        loadFavorites()

        Task { await fetchAllData() }
    }

    // MARK: - Data Fetching
    /// Fetch both coins and global data in parallel
    func fetchAllData() async {
        await fetchCoins()
        await fetchGlobalData()
    }

    /// Fetch market coins from CoinGecko
    func fetchCoins() async {
        print("🌀 fetchCoins start")
        isLoadingCoins = true
        defer { isLoadingCoins = false }

        do {
            let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h")!
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let fetched = try jsonDecoder.decode([MarketCoin].self, from: data)
            coins = fetched
            print("✅ fetchCoins loaded: \(fetched.count) coins")
            // Cache to disk
            try jsonEncoder.encode(coins).write(to: cacheURL, options: .atomic)
            applyAllFiltersAndSort()
        } catch {
            print("❌ fetchCoins failed:", error)
            coinError = "Could not load market data."
            if let cached = loadCachedCoins() {
                coins = cached
            }
        }
    }


    // MARK: - Fetch Global Data

    /// Fetches global market summary via CryptoAPIService
    func fetchGlobalData() async {
        print("🌀 fetchGlobalData start")
        isLoadingGlobal = true
        globalError = nil
        defer { isLoadingGlobal = false }

        do {
            let data = try await CryptoAPIService.shared.fetchGlobalData()
            globalData = data
            print("✅ fetchGlobalData loaded:", data)
        } catch {
            print("❌ fetchGlobalData failed:", error)
            globalError = "Could not load global data."
        }
    }

    // MARK: - Favorites
    /// Toggle a coin in the favorites set
    func toggleFavorite(_ coin: MarketCoin) {
        if favoriteIDs.contains(coin.id) {
            favoriteIDs.remove(coin.id)
        } else {
            favoriteIDs.insert(coin.id)
        }
        // Update the coin's isFavorite flag in the array
        if let index = coins.firstIndex(where: { $0.id == coin.id }) {
            coins[index].isFavorite = favoriteIDs.contains(coin.id)
        }
        saveFavorites()
    }

    // MARK: - Persistence Helpers
    private func loadCachedCoins() -> [MarketCoin]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        let decoded = try? jsonDecoder.decode([MarketCoin].self, from: data)
        if let coins = decoded {
            self.coins = coins
            applyAllFiltersAndSort()
        }
        return decoded
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: "FavoriteCoinIDs") {
            favoriteIDs = Set(saved)
            // Apply to coins array
            for index in coins.indices {
                coins[index].isFavorite = favoriteIDs.contains(coins[index].id)
            }
        }
    }

    private func saveFavorites() {
        let ids = Array(favoriteIDs)
        UserDefaults.standard.set(ids, forKey: "FavoriteCoinIDs")
    }
}

// Simple toggle extension on your SortDirection enum
extension SortDirection {
    mutating func toggle() {
        self = (self == .asc ? .desc : .asc)
    }
}
