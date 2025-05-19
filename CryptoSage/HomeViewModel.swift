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

    // Shared Market ViewModel (injected at creation)
    let marketVM: MarketViewModel

    init(marketVM: MarketViewModel) {
        self.marketVM = marketVM
    }

    // MARK: - Exposed Data for Home Screen
    /// Trending coins (by 24h volume, excluding stablecoins)
    var liveTrending: [MarketCoin] {
        marketVM.trendingCoins
    }

    /// Top 10 gainers by 24h percent change
    var liveTopGainers: [MarketCoin] {
        marketVM.topGainers
    }

    /// Top 10 losers by 24h percent change
    var liveTopLosers: [MarketCoin] {
        marketVM.topLosers
    }

    /// Heatmap data (tiles & weights)
    var heatMapTiles: [HeatMapTile] {
        heatMapVM.tiles
    }
    var heatMapWeights: [Double] {
        heatMapVM.weights()
    }
}
