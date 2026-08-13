import Foundation
import Testing
@testable import MediStock

@MainActor
struct SessionViewModelTests {
    let mockAuth = MockAuthService(currentUser: nil)

    private func makeSUT() -> SessionViewModel {
        SessionViewModel(authService: mockAuth)
    }

    // MARK: - Initial state

    @Test func initialStateIsSignedOut() {
        let sut = makeSUT()
        #expect(sut.currentUser == nil)
        #expect(!sut.isAuthenticated)
        #expect(sut.errorMessage == nil)
    }

    // MARK: - Observation

    @Test func startPublishesAuthStateChanges() {
        let sut = makeSUT()
        sut.start()

        mockAuth.emitAuthState(AppUser(id: "user-1", email: "a@b.c"))

        #expect(sut.currentUser?.id == "user-1")
        #expect(sut.isAuthenticated)
    }

    @Test func startIsIdempotent() {
        let sut = makeSUT()

        sut.start()
        sut.start()
        mockAuth.emitAuthState(AppUser(id: "user-1", email: nil))

        #expect(sut.currentUser?.id == "user-1")
    }

    @Test func signOutEmissionClearsUser() {
        let sut = makeSUT()
        sut.start()
        mockAuth.emitAuthState(AppUser(id: "user-1", email: nil))

        mockAuth.emitAuthState(nil)

        #expect(sut.currentUser == nil)
        #expect(!sut.isAuthenticated)
    }

    // MARK: - Sign in

    @Test func signInSuccessPublishesUser() async {
        let sut = makeSUT()

        await sut.signIn(email: "a@b.c", password: "password")

        #expect(sut.currentUser?.email == "a@b.c")
        #expect(sut.isAuthenticated)
        #expect(sut.errorMessage == nil)
    }

    @Test func signInFailureSurfacesError() async {
        mockAuth.errorToThrow = MediStockError.invalidCredentials
        let sut = makeSUT()

        await sut.signIn(email: "a@b.c", password: "wrong")

        #expect(sut.currentUser == nil)
        #expect(sut.errorMessage == MediStockError.invalidCredentials.localizedDescription)
    }

    // MARK: - Sign up

    @Test func signUpSuccessPublishesUser() async {
        let sut = makeSUT()

        await sut.signUp(email: "new@b.c", password: "password")

        #expect(sut.currentUser?.email == "new@b.c")
        #expect(sut.errorMessage == nil)
    }

    @Test func signUpFailureSurfacesError() async {
        mockAuth.errorToThrow = MediStockError.emailAlreadyInUse
        let sut = makeSUT()

        await sut.signUp(email: "used@b.c", password: "password")

        #expect(sut.currentUser == nil)
        #expect(sut.errorMessage == MediStockError.emailAlreadyInUse.localizedDescription)
    }

    // MARK: - Sign out

    @Test func signOutClearsUser() async {
        let sut = makeSUT()
        await sut.signIn(email: "a@b.c", password: "password")

        sut.signOut()

        #expect(sut.currentUser == nil)
        #expect(mockAuth.signOutCallCount == 1)
    }

    @Test func signOutFailureSurfacesErrorAndKeepsUser() async {
        let sut = makeSUT()
        await sut.signIn(email: "a@b.c", password: "password")
        mockAuth.errorToThrow = MediStockError.networkUnavailable

        sut.signOut()

        #expect(sut.currentUser != nil)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }
}
