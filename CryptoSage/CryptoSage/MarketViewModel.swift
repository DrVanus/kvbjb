import Foundation

@MainActor
final class MarketViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var coins: [MarketCoin] = []
    @Published var globalData: GlobalMarketData?
    @Published var isLoadingCoins: Bool = false
    @Published var coinError: String? = nil

    @Published var favoriteIDs: Set<String> = []
    /// Coins in the user’s watchlist, fetched via dedicated API call
    @Published var watchlistCoins: [MarketCoin] = []
    private let favoritesKey = "FavoriteCoinIDs"
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    @Published var selectedSegment: MarketSegment = .all
    @Published var sortField: SortField = .coin
    @Published var sortDirection: SortDirection = .desc
    @Published var filteredCoins: [MarketCoin] = []

    /// Unfiltered list of all loaded MarketCoin objects
    var allCoins: [MarketCoin] {
        coins
    }

    // MARK: - Computed Stats & Lists
    var marketCapUSD: Double { globalData?.totalMarketCap["usd"] ?? 0 }
    var volume24hUSD: Double { globalData?.totalVolume["usd"] ?? 0 }
    var btcDominance: Double { globalData?.marketCapPercentage["btc"] ?? 0 }
    var ethDominance: Double { globalData?.marketCapPercentage["eth"] ?? 0 }

    var trendingCoins: [MarketCoin] {
        let nonStable = coins.filter { !stableSymbols.contains($0.symbol.uppercased()) }
        return Array(nonStable.sorted { $0.totalVolume > $1.totalVolume }.prefix(10))
    }

    var topGainers: [MarketCoin] {
        Array(coins.sorted { $0.dailyChange > $1.dailyChange }.prefix(10))
    }

    var topLosers: [MarketCoin] {
        Array(coins.sorted { $0.dailyChange < $1.dailyChange }.prefix(10))
    }

    // MARK: - Networking & Caching
    private let session: URLSession
    private let cacheURL: URL
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private let stableSymbols: Set<String> = ["USDT", "USDC", "BUSD", "DAI"]

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheURL = docs.appendingPathComponent("coins_cache.json")

        // Load cached coins
        if let cached = loadCachedCoins() {
            coins = cached
            applyAllFiltersAndSort()
        }
        // Load favorites
        loadFavorites()
        applyAllFiltersAndSort()

        // Fetch live data
        Task {
            await loadAllData()
        }
    }

    /// Loads coins and global market data concurrently
    func loadAllData() async {
        guard !isLoadingCoins else { return }
        isLoadingCoins = true
        coinError = nil
        defer { isLoadingCoins = false }

        do {
            async let coinsTask = CryptoAPIService.shared.fetchCoinMarkets()
            async let globalTask = CryptoAPIService.shared.fetchGlobalData()
            let (fetchedCoins, fetchedGlobal) = try await (coinsTask, globalTask)
            coins = fetchedCoins
            globalData = fetchedGlobal
            applyAllFiltersAndSort()
        } catch {
            coinError = "Could not load market data"
            print("Market load error:", error)
            _ = loadCachedCoins()
        }
    }

    /// Fetches only the favorite coins by ID with 1h and 24h change data
    func loadWatchlist(ids: [String]) async {
        guard !ids.isEmpty else {
            watchlistCoins = []
            return
        }
        do {
            let coins = try await CryptoAPIService.shared.fetchWatchlistMarkets(ids: ids)
            watchlistCoins = coins
        } catch {
            print("Watchlist load failed:", error)
        }
    }

    // MARK: - Filtering & Sorting

    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }

    func toggleSort(for field: SortField) {
        if sortField == field {
            sortDirection.toggle()
        } else {
            sortField = field
            sortDirection = .asc
        }
        applyAllFiltersAndSort()
    }

    func applyAllFiltersAndSort() {
        var temp = coins
        switch selectedSegment {
        case .all: break
        case .trending: temp = trendingCoins
        case .gainers: temp = topGainers
        case .losers: temp = topLosers
        case .favorites:
            temp = coins.filter { favoriteIDs.contains($0.id) }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            temp = temp.filter {
                $0.name.lowercased().contains(q) ||
                $0.symbol.lowercased().contains(q)
            }
        }

        temp.sort {
            let result: Bool
            switch sortField {
            case .coin:        result = $0.name.lowercased() < $1.name.lowercased()
            case .price:       result = $0.currentPrice < $1.currentPrice
            case .dailyChange: result = $0.dailyChange < $1.dailyChange
            case .volume:      result = $0.totalVolume < $1.totalVolume
            case .marketCap:   result = $0.marketCap < $1.marketCap
            }
            return sortDirection == .asc ? result : !result
        }
        filteredCoins = temp
    }

    // MARK: - Favorites

    func toggleFavorite(_ coin: MarketCoin) {
        if favoriteIDs.contains(coin.id) {
            favoriteIDs.remove(coin.id)
        } else {
            favoriteIDs.insert(coin.id)
        }
        saveFavorites()
        applyAllFiltersAndSort()
        Task {
            await loadWatchlist(ids: Array(favoriteIDs))
        }
    }

    func isFavorite(_ coin: MarketCoin) -> Bool {
        favoriteIDs.contains(coin.id)
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            favoriteIDs = Set(saved)
        }
    }

    // MARK: - Caching

    private func loadCachedCoins() -> [MarketCoin]? {
        do {
            let data = try Data(contentsOf: cacheURL)
            let saved = try jsonDecoder.decode([MarketCoin].self, from: data)
            coins = saved
            applyAllFiltersAndSort()
            return saved
        } catch {
            print("Cache decode failed, falling back to network:", error)
            return nil
        }
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }
}

extension SortDirection {
    mutating func toggle() { self = (self == .asc ? .desc : .asc) }
}
