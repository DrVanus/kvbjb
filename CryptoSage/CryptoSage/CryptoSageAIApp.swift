import SwiftUI
import UIKit

@main
struct CryptoSageAIApp: App {
    @StateObject private var appState: AppState
    @StateObject private var marketVM: MarketViewModel
    @StateObject private var portfolioVM: PortfolioViewModel
    @StateObject private var newsVM: CryptoNewsFeedViewModel
    @StateObject private var segmentVM: MarketSegmentViewModel

    init() {
        let appState = AppState()
        let marketVM = MarketViewModel()
        _appState = StateObject(wrappedValue: appState)
        _marketVM = StateObject(wrappedValue: marketVM)
        _portfolioVM = StateObject(wrappedValue: PortfolioViewModel())
        _newsVM = StateObject(wrappedValue: CryptoNewsFeedViewModel())
        _segmentVM = StateObject(wrappedValue: MarketSegmentViewModel())
        // Global navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.black
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house") }
                MarketView()
                    .tabItem { Label("Market", systemImage: "chart.line.uptrend.xyaxis") }
                TradeView()
                    .tabItem { Label("Trading", systemImage: "arrow.swap") }
                PortfolioView()
                    .tabItem { Label("Portfolio", systemImage: "pie.chart") }
                AITabView()
                    .tabItem { Label("AI Chat", systemImage: "bubble.left.and.bubble.right") }
            }
            .environmentObject(appState)
            .environmentObject(marketVM)
            .environmentObject(portfolioVM)
            .environmentObject(newsVM)
            .environmentObject(segmentVM)
            .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: CustomTab = .home
    @Published var isDarkMode: Bool = true
}
