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

    // MARK: - Sign in / up

    @Test func signInSuccessRoutesToMain() async {
        let sut = makeSUT()

        await sut.signIn(email: "a@b.c", password: "password")

        #expect(sut.currentUser?.email == "a@b.c")
        #expect(sut.currentScreen == .main)
        #expect(sut.errorMessage == nil)
    }

    @Test func signInFailureStaysOnLogin() async {
        mockAuth.errorToThrow = MediStockError.invalidCredentials
        let sut = makeSUT()

        await sut.signIn(email: "a@b.c", password: "wrong")

        #expect(sut.currentUser == nil)
        #expect(sut.currentScreen != .main)
        #expect(sut.errorMessage == MediStockError.invalidCredentials.localizedDescription)
    }

    @Test func signUpSuccessRoutesToMain() async {
        let sut = makeSUT()

        await sut.signUp(email: "new@b.c", password: "password")

        #expect(sut.currentUser?.email == "new@b.c")
        #expect(sut.currentScreen == .main)
    }

    @Test func signUpFailureSurfacesError() async {
        mockAuth.errorToThrow = MediStockError.emailAlreadyInUse
        let sut = makeSUT()

        await sut.signUp(email: "used@b.c", password: "password")

        #expect(sut.currentUser == nil)
        #expect(sut.errorMessage == MediStockError.emailAlreadyInUse.localizedDescription)
    }
}
