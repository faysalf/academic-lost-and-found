import SwiftUI

struct BrowseView: View {
    @Environment(AppState.self) private var appState

    @State private var posts: [Post] = []
    @State private var filter: PostType? = nil
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignOutAlert = false

    var body: some View {
        Group {
            if isLoading && posts.isEmpty {
                ProgressView("Loading posts…")
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
        .navigationTitle("Lost & Found")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Label(appState.currentUser?.name ?? "Account",
                          systemImage: "person.circle")
                }
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) { appState.logOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task { await load() }
    }

    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                filterPicker
                    .padding(.horizontal)
                    .padding(.top, 8)

                if let err = errorMessage {
                    ErrorBanner(message: err)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                if posts.isEmpty && !isLoading {
                    EmptyStateView(
                        icon: "tray",
                        title: "No posts yet",
                        message: filter == nil
                            ? "Be the first to post a lost or found item."
                            : "No \(filter!.label) posts right now. Check back later."
                    )
                    .padding(.top, 48)
                } else {
                    ForEach(posts) { post in
                        NavigationLink(destination: PostDetailView(postId: post.id)) {
                            PostRowCard(post: post)
                                .padding(.horizontal)
                                .padding(.top, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if isLoading && !posts.isEmpty {
                    ProgressView().padding()
                }

                Spacer(minLength: 24)
            }
        }
        .refreshable { await load() }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            FilterChip(label: "All", isSelected: filter == nil) {
                filter = nil
                Task { await load() }
            }
            FilterChip(label: "Lost", isSelected: filter == .lost, color: .orange) {
                filter = .lost
                Task { await load() }
            }
            FilterChip(label: "Found", isSelected: filter == .found, color: .green) {
                filter = .found
                Task { await load() }
            }
            Spacer()
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            posts = try await APIClient.shared.fetchPosts(type: filter)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color(.secondarySystemBackground),
                            in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
