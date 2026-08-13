import Foundation

protocol AuthService: Sendable {
    var currentUser: AppUser? { get }
    func signIn(email: String, password: String) async throws -> AppUser
    func signUp(email: String, password: String) async throws -> AppUser
    func signOut() throws
    func observeAuthState(
        _ onChange: @escaping @Sendable @MainActor (AppUser?) -> Void
    ) -> any AuthStateObservation
}

protocol AuthStateObservation: Sendable {
    func cancel()
}
