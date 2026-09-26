import SwiftUI

struct EditPostView: View {
    let post: Post
    var onSave: ((Post) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var itemName: String
    @State private var description: String
    @State private var postType: PostType
    @State private var isOwnerGiven: Bool

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fieldErrors: [String: String] = [:]

    init(post: Post, onSave: ((Post) -> Void)? = nil) {
        self.post   = post
        self.onSave = onSave
        _itemName     = State(initialValue: post.itemName)
        _description  = State(initialValue: post.description)
        _postType     = State(initialValue: post.postType)
        _isOwnerGiven = State(initialValue: post.isOwnerGiven)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Picker("Type", selection: $postType) {
                            ForEach(PostType.allCases, id: \.self) { t in
                                Text(t.label).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    LFTextField(label: "Item Name", text: $itemName,
                                placeholder: "Item name",
                                fieldError: fieldErrors["itemName"])

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(fieldErrors["description"] != nil ? Color.red : Color.clear,
                                            lineWidth: 1.5)
                            )
                        if let err = fieldErrors["description"] {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Toggle("Item returned to owner", isOn: $isOwnerGiven)
                            .padding(12)
                            .background(Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 10))
                    }

                    if let err = errorMessage {
                        ErrorBanner(message: err)
                    }

                    Button(action: save) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Changes").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
        .navigationTitle("Edit Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func validate() -> Bool {
        fieldErrors = [:]
        errorMessage = nil
        if itemName.trimmingCharacters(in: .whitespaces).isEmpty {
            fieldErrors["itemName"] = "Item name is required."
        }
        if description.trimmingCharacters(in: .whitespaces).isEmpty {
            fieldErrors["description"] = "Description is required."
        }
        return fieldErrors.isEmpty
    }

    private func save() {
        guard validate() else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                var req = UpdatePostRequest()
                req.itemName     = itemName.trimmingCharacters(in: .whitespaces)
                req.description  = description.trimmingCharacters(in: .whitespaces)
                req.type         = postType.rawValue
                req.isOwnerGiven = isOwnerGiven
                let updated = try await APIClient.shared.updatePost(id: post.id, req: req)
                onSave?(updated)
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
