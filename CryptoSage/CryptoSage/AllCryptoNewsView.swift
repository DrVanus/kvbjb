import SwiftUI
import Combine

struct AllCryptoNewsView: View {
    @StateObject private var vm = CryptoNewsFeedViewModel()

    var body: some View {
        NavigationView {
            // 1) Loading state
            if vm.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // 2) Error state
            else if let error = vm.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        vm.fetchNews()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            // 3) Success state
            else {
                List(vm.articles) { article in
                    NavigationLink(destination: NewsWebView(urlString: article.url.absoluteString)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title).font(.headline)
                            Text(article.source.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    vm.fetchNews()
                }
            }
        }
        .navigationTitle("Crypto News")
        .onAppear {
            vm.fetchNews()
        }
    }
}

struct AllCryptoNewsView_Previews: PreviewProvider {
    static var previews: some View {
        AllCryptoNewsView()
    }
}
