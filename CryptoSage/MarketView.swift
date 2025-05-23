import SwiftUI
import Foundation
import Charts

struct MarketView: View {
    @StateObject var viewModel = MarketViewModel()

    // Column widths for the list layout
    private let coinWidth: CGFloat   = 140
    private let priceWidth: CGFloat  = 70
    private let dailyWidth: CGFloat  = 50
    private let volumeWidth: CGFloat = 70
    private let starWidth: CGFloat   = 40

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Global market summary at the top

                    // Segmented filter row & search toggle
                    segmentRow

                    // Search bar
                    if viewModel.showSearchBar {
                        TextField("Search coins...", text: $viewModel.searchText)
                            .foregroundColor(.white)
                            .onChange(of: viewModel.searchText) { _ in
                                viewModel.applyAllFiltersAndSort()
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    // Table column headers
                    columnHeader

                    // Content
                    if viewModel.filteredCoins.isEmpty && viewModel.isLoadingCoins {
                        loadingView
                    } else if viewModel.filteredCoins.isEmpty {
                        emptyOrErrorView
                    } else {
                        coinList
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            do {
                try await viewModel.loadAllData()
            } catch {
                viewModel.coinError = "Could not load market data: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Subviews

    private var segmentRow: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MarketSegment.allCases, id: \.self) { seg in
                        Button {
                            viewModel.updateSegment(seg)
                        } label: {
                            Text(seg.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.selectedSegment == seg ? .black : .white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(viewModel.selectedSegment == seg ? Color.white : Color.white.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            Button {
                withAnimation { viewModel.showSearchBar.toggle() }
            } label: {
                Image(systemName: viewModel.showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.trailing, 16)
            }
        }
        .background(Color.black)
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            headerButton("Coin", .coin)
                .frame(width: coinWidth, alignment: .leading)
            Text("7D")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 40, alignment: .trailing)
            headerButton("Price", .price)
                .frame(width: priceWidth, alignment: .trailing)
            headerButton("24h", .dailyChange)
                .frame(width: dailyWidth, alignment: .trailing)
            headerButton("Vol", .volume)
                .frame(width: volumeWidth, alignment: .trailing)
            Spacer().frame(width: starWidth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
    }

    private var loadingView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    skeletonRow()
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 16)
                }
            }
        }
    }

    /// Shows either an error view with retry button or a placeholder text.
    private var emptyOrErrorView: AnyView {
        if let error = viewModel.coinError {
            return AnyView(
                DataUnavailableView(message: error) {
                    Task {
                        do {
                            try await viewModel.loadAllData()
                        } catch {
                            viewModel.coinError = "Could not load market data: \(error.localizedDescription)"
                        }
                    }
                }
            )
        } else {
            return AnyView(
                Text(viewModel.searchText.isEmpty ? "No coins available." : "No coins match your search.")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            )
        }
    }

    private var coinList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredCoins) { coin in
                    NavigationLink(destination: CoinDetailView(coin: coin)) {
                        coinRow(coin)
                            .transition(.opacity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 16)
                }
            }
            .padding(.bottom, 12)
        }
        .refreshable {
            do {
                try await viewModel.loadAllData()
            } catch {
                viewModel.coinError = "Could not load market data: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helpers

    private func headerButton(_ label: String, _ field: SortField) -> some View {
        Button {
            viewModel.toggleSort(for: field)
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                if viewModel.sortField == field {
                    Image(systemName: viewModel.sortDirection == .asc ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(viewModel.sortField == field ? Color.white.opacity(0.05) : Color.clear)
    }

    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                CoinImageView(symbol: coin.symbol, urlStr: coin.image)
                VStack(alignment: .leading, spacing: 3) {
                    Text(coin.symbol.uppercased())
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(coin.name)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: coinWidth, alignment: .leading)

            if #available(iOS 16, *) {
                ZStack {
                    Rectangle().fill(Color.clear).frame(width: 50, height: 30)
                    sparkline(coin.sparklineIn7d ?? [], dailyChange: coin.priceChangePercentage24h)
                }
            } else {
                Spacer().frame(width: 50)
            }

            Text(String(format: "$%.2f", coin.currentPrice))
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
                .lineLimit(1)

            Text(String(format: "%.2f%%", coin.priceChangePercentage24h))
                .font(.caption)
                .foregroundColor(coin.priceChangePercentage24h >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
                .lineLimit(1)
                .animation(.easeInOut, value: coin.priceChangePercentage24h)

            Text(shortVolume(coin.totalVolume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
                .lineLimit(1)

            Button {
                viewModel.toggleFavorite(coin)
            } label: {
                let isFav = viewModel.favoriteIDs.contains(coin.id)
                Image(systemName: isFav ? "star.fill" : "star")
                    .foregroundColor(isFav ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: starWidth, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(height: 60)
    }

    private func skeletonRow() -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: coinWidth, height: 14)
            Spacer().frame(width: 50)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: priceWidth, height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: dailyWidth, height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: volumeWidth, height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: starWidth, height: 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func sparkline(_ data: [Double], dailyChange: Double) -> some View {
        if data.isEmpty {
            Rectangle().fill(Color.white.opacity(0.1))
        } else {
            let minValue = data.min() ?? 0
            let maxValue = data.max() ?? 1
            let range = maxValue - minValue
            let padding = range * 0.15
            let lowerBound = minValue - padding
            let upperBound = maxValue + padding

            Chart {
                ForEach(data.indices, id: \.self) { i in
                    LineMark(x: .value("Index", i), y: .value("Price", data[i]))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(dailyChange >= 0 ? Color.green : Color.red)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: lowerBound...upperBound)
            .chartPlotStyle { plotArea in
                plotArea.frame(width: 50, height: 30)
            }
        }
    }

    private func shortVolume(_ vol: Double) -> String {
        vol.formattedWithAbbreviations()
    }
}

extension Double {
    func formattedWithAbbreviations() -> String {
        let absValue = abs(self)
        switch absValue {
        case 1_000_000_000_000...:
            return String(format: "%.1fT", self / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "%.1fB", self / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", self / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", self / 1_000)
        default:
            return String(format: "%.0f", self)
        }
    }
}
