import SwiftUI

@main
struct CryptoSageAIApp: App {
    @StateObject private var appState: AppState
    @StateObject private var marketVM: MarketViewModel
    @StateObject private var newsVM: CryptoNewsFeedViewModel
    @StateObject private var homeVM: HomeViewModel

    init() {
        // Create one shared MarketViewModel
        let mvm = MarketViewModel()

        // Initialize all StateObjects in init so we can pass mvm to HomeViewModel
        _appState = StateObject(wrappedValue: AppState())
        _marketVM = StateObject(wrappedValue: mvm)
        _newsVM   = StateObject(wrappedValue: CryptoNewsFeedViewModel())
        _homeVM   = StateObject(wrappedValue: HomeViewModel(marketVM: mvm))
    }

    var body: some Scene {
        WindowGroup {
            ContentManagerView()
                .environmentObject(appState)
                .environmentObject(marketVM)
                .environmentObject(newsVM)
                .environmentObject(homeVM)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: CustomTab = .home
    @Published var isDarkMode: Bool = true
}
