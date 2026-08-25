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

    // MARK: - Delete account

    @Test func deleteAccountClearsUserAndRoutesToLogin() async {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: "a@b.c"))

        await sut.deleteAccount(password: "motdepasse")

        #expect(sut.currentUser == nil)
        #expect(sut.currentScreen == .login)
        #expect(sut.errorMessage == nil)
        #expect(mockAuth.deleteAccountCallCount == 1)
    }

    @Test func deleteAccountResetsItsProgressFlag() async {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: nil))

        await sut.deleteAccount(password: "motdepasse")

        #expect(sut.isDeletingAccount == false)
    }

    @Test func deleteAccountFailureSurfacesErrorAndKeepsSession() async {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: nil))
        mockAuth.errorToThrow = MediStockError.networkUnavailable

        await sut.deleteAccount(password: "motdepasse")

        #expect(sut.currentUser != nil)
        #expect(sut.currentScreen == .main)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
        #expect(mockAuth.deleteAccountCallCount == 0)
    }

    @Test func deleteAccountAsksForReauthenticationWhenTheSessionIsTooOld() async {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: nil))
        mockAuth.errorToThrow = MediStockError.requiresRecentLogin

        await sut.deleteAccount(password: "motdepasse")

        #expect(sut.currentScreen == .main)
        #expect(sut.errorMessage == MediStockError.requiresRecentLogin.localizedDescription)
    }

    @Test func deleteAccountForwardsThePasswordToTheService() async {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: "a@b.c"))

        await sut.deleteAccount(password: "motdepasse")

        #expect(mockAuth.lastDeletionPassword == "motdepasse")
    }

    @Test func deleteAccountSurfacesTheErrorWhenThePasswordIsWrong() async {
        let sut = makeSUT()
        sut.onAuthenticated(AppUser(id: "user-1", email: "a@b.c"))
        mockAuth.errorToThrow = MediStockError.invalidCredentials

        await sut.deleteAccount(password: "mauvais")

        #expect(sut.currentUser != nil)
        #expect(sut.currentScreen == .main)
        #expect(sut.errorMessage == MediStockError.invalidCredentials.localizedDescription)
    }
}
