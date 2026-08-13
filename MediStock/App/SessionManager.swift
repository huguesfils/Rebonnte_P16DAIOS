import Foundation

@Observable
@MainActor
final class SessionManager {
    private(set) var currentUser: AppUser?
    private(set) var currentScreen: AppScreen = .loading
    var errorMessage: String?

    private let authService: AuthService

    @ObservationIgnored
    private var authObservation: (any AuthStateObservation)?

    init(authService: AuthService) {
        self.authService = authService
    }

    deinit {
        authObservation?.cancel()
    }

    // MARK: - Observation

    func start() {
        guard authObservation == nil else {
            resolveScreen()
            return
        }

        authObservation = authService.observeAuthState { [weak self] user in
            self?.currentUser = user
            self?.resolveScreen()
        }
    }

    // MARK: - Routing

    func onAuthenticated(_ user: AppUser) {
        currentUser = user
        currentScreen = .main
    }

    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
            currentScreen = .login
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func resolveScreen() {
        currentScreen = currentUser == nil ? .login : .main
    }
}
