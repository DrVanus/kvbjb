//
//  HomeViewModel.swift
//  CSAI1
//
//  ViewModel to provide data for Home screen: portfolio, news, heatmap, market overview.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Child ViewModels
    @Published var portfolioVM = PortfolioViewModel()
    @Published var newsVM      = CryptoNewsFeedViewModel()
    @Published var heatMapVM   = HeatMapViewModel()

    // Published market slices for UI sections
    @Published var liveTrending: [MarketCoin] = []
    @Published var liveTopGainers: [MarketCoin] = []
    @Published var liveTopLosers: [MarketCoin] = []

    // Shared Market ViewModel (injected at creation)
    let marketVM: MarketViewModel

    init(marketVM: MarketViewModel) {
        self.marketVM = marketVM
    }

    // MARK: - Market Data Fetching
    /// Fetches the full coin list once, then updates our three @Published slices.
    func fetchMarketData() {
        Task {
            do {
                try await marketVM.loadAllData()
                // Update all three slices on the main actor
                await MainActor.run {
                    liveTrending   = marketVM.trendingCoins
                    liveTopGainers = marketVM.topGainers
                    liveTopLosers  = marketVM.topLosers
                }
            } catch {
                print("⚠️ HomeViewModel.fetchMarketData failed: \(error)")
            }
        }
    }

    /// Convenience wrappers forwarding to fetchMarketData()
    func fetchTrending()    { fetchMarketData() }
    func fetchTopGainers()  { fetchMarketData() }
    func fetchTopLosers()   { fetchMarketData() }

    /// Heatmap data (tiles & weights)
    var heatMapTiles: [HeatMapTile] {
        heatMapVM.tiles
    }
    var heatMapWeights: [Double] {
        heatMapVM.weights()
    }
}
