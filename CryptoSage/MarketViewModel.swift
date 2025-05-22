import Foundation

@MainActor
final class MarketViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var coins: [MarketCoin] = []
    @Published var globalData: GlobalMarketData?
    @Published var isLoadingCoins: Bool = false
    @Published var coinError: String? = nil

    @Published var favoriteIDs: Set<String> = []
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    @Published var selectedSegment: MarketSegment = .all
    @Published var sortField: SortField = .coin
    @Published var sortDirection: SortDirection = .desc
    @Published var filteredCoins: [MarketCoin] = []

    // MARK: - Computed Stats & Lists
    var marketCapUSD: Double { globalData?.totalMarketCap["usd"] ?? 0 }
    var volume24hUSD: Double { globalData?.totalVolume["usd"] ?? 0 }
    var btcDominance:  Double { globalData?.marketCapPercentage["btc"]  ?? 0 }
    var ethDominance:  Double { globalData?.marketCapPercentage["eth"]  ?? 0 }

    var trendingCoins: [MarketCoin] {
        let nonStable = coins.filter { !stableSymbols.contains($0.symbol.uppercased()) }
        return Array(nonStable.sorted { $0.totalVolume > $1.totalVolume }.prefix(10))
    }

    var topGainers: [MarketCoin] {
        Array(coins.sorted { $0.priceChangePercentage24h > $1.priceChangePercentage24h }.prefix(10))
    }

    var topLosers: [MarketCoin] {
        Array(coins.sorted { $0.priceChangePercentage24h < $1.priceChangePercentage24h }.prefix(10))
    }

    // MARK: - Networking & Caching
    private let session: URLSession
    private let cacheURL: URL
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private let stableSymbols: Set<String> = ["USDT","USDC","BUSD","DAI"]

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheURL = caches.appendingPathComponent("market_coins.json")

        _ = loadCachedCoins()
        loadFavorites()
    }

    /// Public API: load both coins and global data
    func loadAllData() async {
        guard !isLoadingCoins else { return }
        isLoadingCoins = true
        coinError = nil
        defer { isLoadingCoins = false }

        do {
            coinError = nil
            async let coinsTask = CryptoAPIService.shared.fetchCoinMarkets()
            async let globalTask = CryptoAPIService.shared.fetchGlobalData()
            let (fetchedCoins, fetchedGlobal) = try await (coinsTask, globalTask)
            coins = fetchedCoins
            globalData = fetchedGlobal
            applyAllFiltersAndSort()
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Task was cancelled (e.g., user switched segments) - ignore silently
        } catch let urlError as URLError where urlError.code == .timedOut {
            // Request timed out - fallback to cache
            print("Market load timeout, using cache")
            _ = loadCachedCoins()
        } catch {
            coinError = "Could not load market data"
            print("Market load error:", error)
            _ = loadCachedCoins()
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
        case .all:      break
        case .trending: temp = trendingCoins
        case .gainers:  temp = topGainers
        case .losers:   temp = topLosers
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
        temp.sort { a, b in
            let result: Bool
            switch sortField {
            case .coin:        result = a.name.lowercased() < b.name.lowercased()
            case .price:       result = a.currentPrice < b.currentPrice
            case .dailyChange: result = a.priceChangePercentage24h < b.priceChangePercentage24h
            case .volume:      result = a.totalVolume < b.totalVolume
            case .marketCap:   result = a.marketCap < b.marketCap
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
        applyAllFiltersAndSort()
        saveFavorites()
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: "FavoriteCoinIDs") {
            favoriteIDs = Set(saved)
        }
    }

    private func loadCachedCoins() -> [MarketCoin]? {
        guard let data = try? Data(contentsOf: cacheURL),
              let saved = try? jsonDecoder.decode([MarketCoin].self, from: data)
        else { return nil }
        coins = saved
        applyAllFiltersAndSort()
        return saved
    }

    private func saveFavorites() {
        let ids = Array(favoriteIDs)
        UserDefaults.standard.set(ids, forKey: "FavoriteCoinIDs")
    }
}

extension SortDirection {
    mutating func toggle() { self = (self == .asc ? .desc : .asc) }
}
