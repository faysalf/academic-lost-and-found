import Observation

@MainActor
@Observable
final class AppState {
    private(set) var currentUser: User?

    var isLoggedIn: Bool { currentUser != nil }

    func logIn(user: User) {
        currentUser = user
    }

    func logOut() {
        currentUser = nil
    }
}
