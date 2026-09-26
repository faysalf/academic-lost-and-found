import SwiftUI

struct MyPostsView: View {
    @Environment(AppState.self) private var appState

    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var deletedIds: Set<Int> = []
    @State private var showDeleteAlert = false
    @State private var pendingDeleteId: Int?

    private var myPosts: [Post] {
        guard let userId = appState.currentUser?.id else { return [] }
        return posts.filter { $0.user == userId && !deletedIds.contains($0.id) }
    }

    var body: some View {
        Group {
            if isLoading && posts.isEmpty {
                ProgressView("Loading your posts…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage, posts.isEmpty {
                VStack(spacing: 16) {
                    ErrorBanner(message: err).padding(.horizontal)
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                postList
            }
        }
        .navigationTitle("My Posts")
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let id = pendingDeleteId { Task { await deletePost(id: id) } }
            }
            Button("Cancel", role: .cancel) { pendingDeleteId = nil }
        } message: {
            Text("This will permanently remove the post.")
        }
        .task { await load() }
    }

    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if myPosts.isEmpty && !isLoading {
                    EmptyStateView(
                        icon: "person.text.rectangle",
                        title: "No posts yet",
                        message: "Tap the + tab to post a lost or found item."
                    )
                    .padding(.top, 48)
                } else {
                    ForEach(myPosts) { post in
                        // Card + delete button share the same horizontal row
                        // so the button never overlaps any card content.
                        VStack(spacing: 0) {
                            NavigationLink(destination: PostDetailView(postId: post.id)) {
                                PostRowCard(post: post)
                            }
                            .buttonStyle(.plain)

                            // Subtle delete row beneath the card
                            HStack {
                                Spacer()
                                Button(role: .destructive) {
                                    pendingDeleteId = post.id
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.red)
                                }
                                .accessibilityLabel("Delete \(post.itemName)")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                }

                Spacer(minLength: 24)
            }
        }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            posts = try await APIClient.shared.fetchPosts()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func deletePost(id: Int) async {
        do {
            try await APIClient.shared.deletePost(id: id)
            deletedIds.insert(id)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        pendingDeleteId = nil
    }
}
