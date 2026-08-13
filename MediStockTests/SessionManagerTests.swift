import Foundation
import Testing
@testable import MediStock

@MainActor
struct SessionManagerTests {
    let mockAuth = MockAuthService(currentUser: nil)

    private func makeSUT() -> SessionManager {
        SessionManager(authService: mockAuth)
    }

    // MARK: - Initial state

    @Test func initialScreenIsLoadingUntilAuthStateIsKnown() {
        let sut = makeSUT()
        #expect(sut.currentUser == nil)
        #expect(sut.currentScreen == .loading)
        #expect(sut.errorMessage == nil)
    }

    // MARK: - Routing

    @Test func startWithoutUserRoutesToLogin() {
        let sut = makeSUT()

        sut.start()
        mockAuth.emitAuthState(nil)

        #expect(sut.currentScreen == .login)
    }

    @Test func startWithUserRoutesToMain() {
        let sut = makeSUT()

        sut.start()
        mockAuth.emitAuthState(AppUser(id: "user-1", email: "a@b.c"))

        #expect(sut.currentUser?.id == "user-1")
        #expect(sut.currentScreen == .main)
    }

    @Test func startIsIdempotent() {
        let sut = makeSUT()

        sut.start()
        sut.start()
        mockAuth.emitAuthState(AppUser(id: "user-1", email: nil))

        #expect(sut.currentUser?.id == "user-1")
        #expect(sut.currentScreen == .main)
    }

    @Test func externalSignOutRoutesBackToLogin() {
        let sut = makeSUT()
        sut.start()
        mockAuth.emitAuthState(AppUser(id: "user-1", email: nil))

        mockAuth.emitAuthState(nil)

        #expect(sut.currentUser == nil)
        #expect(sut.currentScreen == .login)
    }

    @Test func onAuthenticatedRoutesToMain() {
        let sut = makeSUT()

        sut.onAuthenticated(AppUser(id: "user-1", email: "a@b.c"))

        #expect(sut.currentUser?.id == "user-1")
        #expect(sut.currentScreen == .main)
    }

    // MARK: - Sign out

    @Test func signOutClearsUserAndRoutesToLogin() {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: nil))

        sut.signOut()

        #expect(sut.currentUser == nil)
        #expect(sut.currentScreen == .login)
        #expect(mockAuth.signOutCallCount == 1)
    }

    @Test func signOutFailureSurfacesErrorAndKeepsSession() {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: nil))
        mockAuth.errorToThrow = MediStockError.networkUnavailable

        sut.signOut()

        #expect(sut.currentUser != nil)
        #expect(sut.currentScreen == .main)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }
}
