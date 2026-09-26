import SwiftUI

struct CreatePostView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var itemName    = ""
    @State private var description = ""
    @State private var postType    = PostType.lost

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fieldErrors: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                    Text("New Post")
                        .font(.title2.bold())
                    Text("Fill in the details so others can help.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

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
                                placeholder: "e.g. Black wallet, AirPods case",
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

                    if let err = errorMessage {
                        ErrorBanner(message: err)
                    }

                    Button(action: submit) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Post Item").fontWeight(.semibold)
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
        }
        .navigationTitle("New Post")
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

    private func submit() {
        guard validate(), let user = appState.currentUser else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                _ = try await APIClient.shared.createPost(
                    itemName: itemName.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces),
                    type: postType,
                    userId: user.id
                )
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
