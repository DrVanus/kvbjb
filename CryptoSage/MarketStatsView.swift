//
//  MarketStatsView.swift
//  CryptoSage
//
//  Created by DM on 5/19/25.
//

import SwiftUI

// MARK: - MarketStatsView

struct MarketStatsView: View {
    @StateObject private var vm = MarketStatsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Label("Market Stats", systemImage: "chart.bar")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            // Grid of stats
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
            LazyVGrid(columns: columns, spacing: 4) {
                StatItemView(icon: "globe", title: "Market Cap",  value: vm.globalMarketCap)
                StatItemView(icon: "clock", title: "24h Volume",  value: vm.volume24h)
                StatItemView(icon: "bitcoinsign.circle", title: "BTC Dom",  value: vm.btcDominance)
                StatItemView(icon: "chart.bar.fill", title: "ETH Dom",   value: vm.ethDominance)
                StatItemView(icon: "dollarsign.circle", title: "BTC Price", value: vm.btcPrice)
                StatItemView(icon: "dollarsign.circle", title: "ETH Price", value: vm.ethPrice)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground).opacity(0.05))
        )
        .task {
            await vm.loadGlobalStats()
            await vm.loadCurrentPrices()
        }
    }
}

// MARK: - StatItemView

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 1) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline).bold()
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ViewModel

@MainActor
class MarketStatsViewModel: ObservableObject {
    @Published var globalMarketCap = "$0"
    @Published var volume24h      = "$0"
    @Published var btcDominance   = "0.00%"
    @Published var ethDominance   = "0.00%"
    @Published var btcPrice       = "$0"
    @Published var ethPrice       = "$0"

    func loadGlobalStats() async {
        print("▶️ loadGlobalStats called")
        do {
            let stats = try await CryptoAPIService.shared.fetchGlobalData()
            let cap  = stats.totalMarketCap["usd"] ?? 0
            let vol  = stats.totalVolume["usd"]    ?? 0
            let btcD = stats.marketCapPercentage["btc"] ?? 0
            let ethD = stats.marketCapPercentage["eth"] ?? 0

            globalMarketCap = cap.formattedWithAbbreviations(prefix: "$ ")
            volume24h      = vol.formattedWithAbbreviations(prefix: "$ ")
            btcDominance   = String(format: "%.2f%%", btcD)
            ethDominance   = String(format: "%.2f%%", ethD)
        } catch {
            print("❌ loadGlobalStats failed:", error)
        }
    }

    func loadCurrentPrices() async {
        print("▶️ loadCurrentPrices called")
        let ids = "bitcoin,ethereum"
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(ids)&vs_currencies=usd") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = String(data: data, encoding: .utf8) {
                print("📡 Price JSON:", json)
            }
            let dict = try JSONDecoder().decode([String: [String: Double]].self, from: data)
            if let b = dict["bitcoin"]?["usd"] {
                btcPrice = b.formattedWithAbbreviations(prefix: "$ ")
            }
            if let e = dict["ethereum"]?["usd"] {
                ethPrice = e.formattedWithAbbreviations(prefix: "$ ")
            }
        } catch {
            print("Error fetching current prices:", error)
        }
    }
}


// MARK: - Extensions

extension Double {
    func formattedWithAbbreviations(prefix: String = "") -> String {
        let absValue = Swift.abs(self)
        let sign = (self < 0) ? "-" : ""
        switch absValue {
        case 1_000_000_000_000...:
            return "\(sign)\(prefix)\(String(format: "%.1fT", absValue / 1_000_000_000_000))"
        case 1_000_000_000...:
            return "\(sign)\(prefix)\(String(format: "%.1fB", absValue / 1_000_000_000))"
        case 1_000_000...:
            return "\(sign)\(prefix)\(String(format: "%.1fM", absValue / 1_000_000))"
        case 1_000...:
            return "\(sign)\(prefix)\(String(format: "%.1fK", absValue / 1_000))"
        default:
            return "\(sign)\(prefix)\(Int(absValue))"
        }
    }
}
