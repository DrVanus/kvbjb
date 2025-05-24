import SwiftUI
import Combine

@MainActor
final class CryptoNewsFeedViewModel: ObservableObject {
    @Published var articles: [CryptoNewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service = CryptoNewsService()

    // Track read/bookmarked articles
    @Published private var readArticleIDs: Set<UUID> = []
    @Published private var bookmarkedArticleIDs: Set<UUID> = []

    /// Initialize and load full feed
    init() {
        Task {
            await loadLatestNews()
        }
    }

    /// Fetch full list of articles
    func loadLatestNews() async {
        isLoading = true
        defer { isLoading = false }

        let fetched = await service.fetchLatestNews()
        articles = fetched
    }

    /// Fetch preview for quick display
    func loadPreviewNews() async {
        isLoading = true
        defer { isLoading = false }

        let fetched = await service.fetchPreviewNews()
        articles = fetched
    }

    // MARK: - Read / Bookmark Actions

    func toggleRead(_ article: CryptoNewsArticle) {
        if isRead(article) {
            readArticleIDs.remove(article.id)
        } else {
            readArticleIDs.insert(article.id)
        }
    }

    func isRead(_ article: CryptoNewsArticle) -> Bool {
        readArticleIDs.contains(article.id)
    }

    func toggleBookmark(_ article: CryptoNewsArticle) {
        if isBookmarked(article) {
            bookmarkedArticleIDs.remove(article.id)
        } else {
            bookmarkedArticleIDs.insert(article.id)
        }
    }

    func isBookmarked(_ article: CryptoNewsArticle) -> Bool {
        bookmarkedArticleIDs.contains(article.id)
    }
}
