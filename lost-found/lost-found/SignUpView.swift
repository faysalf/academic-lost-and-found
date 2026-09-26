import SwiftUI

struct SignUpView: View {
    var onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name      = ""
    @State private var phone     = ""
    @State private var address   = ""
    @State private var password  = ""
    @State private var password2 = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fieldErrors: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                    Text("Create Account")
                        .font(.title2.bold())
                    Text("Join the campus Lost & Found network")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 14) {
                    LFTextField(label: "Full Name", text: $name,
                                placeholder: "Alex Student",
                                fieldError: fieldErrors["name"])

                    LFTextField(label: "Phone", text: $phone,
                                placeholder: "5551234567", keyboard: .phonePad,
                                fieldError: fieldErrors["phone"])

                    LFTextField(label: "Address (optional)", text: $address,
                                placeholder: "Dorm / Building")

                    LFSecureField(label: "Password", text: $password,
                                  placeholder: "At least 8 characters",
                                  fieldError: fieldErrors["password"])

                    LFSecureField(label: "Confirm Password", text: $password2,
                                  placeholder: "Repeat your password",
                                  fieldError: fieldErrors["password2"])

                    if let err = errorMessage {
                        ErrorBanner(message: err)
                    }

                    Button(action: signUp) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account").fontWeight(.semibold)
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
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func validate() -> Bool {
        fieldErrors = [:]
        errorMessage = nil
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            fieldErrors["name"] = "Name is required."
        }
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            fieldErrors["phone"] = "Phone number is required."
        }
        if password.isEmpty {
            fieldErrors["password"] = "Password is required."
        } else if password.count < 8 {
            fieldErrors["password"] = "Password must be at least 8 characters."
        }
        if password2.isEmpty {
            fieldErrors["password2"] = "Please confirm your password."
        } else if password != password2 {
            fieldErrors["password2"] = "Passwords do not match."
        }
        return fieldErrors.isEmpty
    }

    private func signUp() {
        guard validate() else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await APIClient.shared.signUp(
                    phone: phone, name: name, address: address,
                    password: password, password2: password2
                )
                onSuccess()
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
