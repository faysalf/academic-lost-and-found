import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    @State private var phone    = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var signUpSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.blue)
                    Text("Lost & Found")
                        .font(.largeTitle.bold())
                    Text("Campus item recovery made simple")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)

                if signUpSuccess {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Account created! Sign in to continue.")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    LFTextField(label: "Phone", text: $phone,
                                placeholder: "e.g. 01518933662", keyboard: .phonePad)

                    LFSecureField(label: "Password", text: $password,
                                  placeholder: "Your password")

                    if let err = errorMessage {
                        ErrorBanner(message: err)
                    }

                    Button(action: login) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || phone.isEmpty || password.isEmpty)
                }
                .padding(.horizontal)

                NavigationLink {
                    SignUpView(onSuccess: { signUpSuccess = true })
                } label: {
                    (Text("Don't have an account? ").foregroundStyle(.secondary) +
                     Text("Create one").foregroundStyle(.blue).fontWeight(.semibold))
                        .font(.subheadline)
                }

                Spacer(minLength: 32)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: phone)    { _, _ in errorMessage = nil }
        .onChange(of: password) { _, _ in errorMessage = nil }
    }

    private func login() {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let user = try await APIClient.shared.login(phone: phone, password: password)
                appState.logIn(user: user)
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
