import SwiftUI
import Combine
import Foundation

@MainActor
final class CryptoNewsFeedViewModel: ObservableObject {
    @Published var articles: [CryptoNewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service = CryptoNewsFeedService()
    private var cancellable: AnyCancellable?

    // Track read/bookmarked articles
    @Published private var readArticleIDs: Set<UUID> = []
    @Published private var bookmarkedArticleIDs: Set<UUID> = []

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

    /// Fetch live news using Combine
    func fetchNews() {
        isLoading = true
        errorMessage = nil
        cancellable = service.fetchNewsPublisher()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { _ in self.isLoading = false })
            .sink { completion in
                if case .failure(let err) = completion {
                    self.errorMessage = err.localizedDescription
                }
            } receiveValue: { articles in
                self.articles = articles
            }
    }
}
