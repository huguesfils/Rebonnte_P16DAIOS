import Foundation

@Observable
@MainActor
final class SessionViewModel {
    private(set) var currentUser: AppUser?
    var errorMessage: String?

    var isAuthenticated: Bool {
        currentUser != nil
    }

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
        guard authObservation == nil else { return }

        authObservation = authService.observeAuthState { [weak self] user in
            self?.currentUser = user
        }
    }

    // MARK: - Sign in / up / out

    func signIn(email: String, password: String) async {
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        do {
            currentUser = try await authService.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
