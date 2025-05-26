import SwiftUI
import Combine
import Foundation

@MainActor
final class CryptoNewsFeedViewModel: ObservableObject {
    @Published var articles: [CryptoNewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// The article currently selected for detail view
    @Published var selectedArticle: CryptoNewsArticle?

    private let service = CryptoNewsFeedService()

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
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchLatestNews()
            articles = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fetch preview for quick display
    func loadPreviewNews() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchPreviewNews()
            articles = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Selection

    /// Select an article for detail view
    func selectArticle(_ article: CryptoNewsArticle) {
        selectedArticle = article
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
