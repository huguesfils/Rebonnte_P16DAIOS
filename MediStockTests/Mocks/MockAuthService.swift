import Foundation
@testable import MediStock

final class MockAuthService: AuthService, @unchecked Sendable {
    var currentUser: AppUser?
    var errorToThrow: Error?

    private(set) var signOutCallCount = 0
    private var listener: (@Sendable @MainActor (AppUser?) -> Void)?

    init(currentUser: AppUser? = AppUser(id: "test-user", email: "test@medistock.app")) {
        self.currentUser = currentUser
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        if let errorToThrow { throw errorToThrow }
        let user = AppUser(id: "test-user", email: email)
        currentUser = user
        return user
    }

    func signUp(email: String, password: String) async throws -> AppUser {
        if let errorToThrow { throw errorToThrow }
        let user = AppUser(id: "test-user", email: email)
        currentUser = user
        return user
    }

    func signOut() throws {
        if let errorToThrow { throw errorToThrow }
        signOutCallCount += 1
        currentUser = nil
    }

    func observeAuthState(
        _ onChange: @escaping @Sendable @MainActor (AppUser?) -> Void
    ) -> any AuthStateObservation {
        listener = onChange
        return MockAuthStateObservation()
    }

    @MainActor
    func emitAuthState(_ user: AppUser?) {
        currentUser = user
        listener?(user)
    }
}

final class MockAuthStateObservation: AuthStateObservation, @unchecked Sendable {
    private(set) var isCancelled = false

    func cancel() {
        isCancelled = true
    }
}
