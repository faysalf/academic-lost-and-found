import SwiftUI

struct PostDetailView: View {
    let postId: Int

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var post: Post?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteAlert = false
    @State private var isDeleting = false

    private var isOwner: Bool {
        guard let post else { return false }
        return post.user == appState.currentUser?.id
    }

    // ScrollView is always the root so NavigationStack always has
    // a concrete scroll view to attach the safe-area inset to.
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let err = errorMessage {
                VStack(spacing: 16) {
                    ErrorBanner(message: err).padding(.horizontal)
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else if let post {
                detailContent(post: post)
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner, let post {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        NavigationLink(destination: EditPostView(post: post, onSave: { updated in
                            self.post = updated
                        })) {
                            Label("Edit Post", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { Task { await deletePost() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the post.")
        }
        .task { await load() }
    }

    @ViewBuilder
    private func detailContent(post: Post) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                PostTypeBadge(type: post.postType)
                if post.isOwnerGiven {
                    Label("Returned to owner", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.teal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.teal.opacity(0.12), in: Capsule())
                }
                Spacer()
            }

            Text(post.itemName)
                .font(.title2.bold())

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label("Description", systemImage: "doc.text")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(post.description.isEmpty ? "No description provided." : post.description)
                    .font(.body)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                metaRow(icon: "person.fill",  label: "Posted by", value: post.userName)
                metaRow(icon: "calendar",     label: "Date",      value: post.formattedDate)
                metaRow(icon: "arrow.uturn.backward",
                        label: "Status",
                        value: post.isOwnerGiven ? "Item has been returned" : "Item not yet returned")
            }

            if isDeleting {
                HStack {
                    ProgressView()
                    Text("Deleting…").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }

            Spacer(minLength: 32)
        }
        .padding()
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline)
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            post = try await APIClient.shared.fetchPost(id: postId)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func deletePost() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await APIClient.shared.deletePost(id: postId)
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
