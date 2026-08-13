import Foundation
import Testing
@testable import MediStock

@MainActor
struct LoginViewModelTests {
    let mockAuth = MockAuthService(currentUser: nil)

    private func makeSUT() -> LoginViewModel {
        LoginViewModel(authService: mockAuth)
    }

    private func makeFilledSUT(mode: AuthMode = .signIn) -> LoginViewModel {
        let sut = makeSUT()
        sut.mode = mode
        sut.email = "user@medistock.app"
        sut.password = "password"
        return sut
    }

    // MARK: - Initial state

    @Test func initialStateIsEmptyAndNotSubmittable() {
        let sut = makeSUT()
        #expect(sut.mode == .signIn)
        #expect(sut.email.isEmpty)
        #expect(sut.password.isEmpty)
        #expect(!sut.canSubmit)
        #expect(!sut.isAuthenticating)
        #expect(sut.authenticatedUser == nil)
        #expect(sut.errorMessage == nil)
    }

    // MARK: - Validation

    @Test("Email invalide", arguments: [
        "",
        "user",
        "user@",
        "@medistock.app",
        "user@medistock",
        "user@.app",
        "user@medistock."
    ])
    func invalidEmailsBlockSubmission(email: String) {
        let sut = makeSUT()
        sut.email = email
        sut.password = "password"

        #expect(!sut.canSubmit)
    }

    @Test func validEmailAndPasswordAllowSubmission() {
        let sut = makeFilledSUT()
        #expect(sut.canSubmit)
    }

    @Test func emailIsTrimmedBeforeBeingSent() async {
        let sut = makeSUT()
        sut.email = "  user@medistock.app  "
        sut.password = "password"

        await sut.submit()

        #expect(sut.authenticatedUser?.email == "user@medistock.app")
    }

    @Test func passwordShorterThanMinimumBlocksSubmission() {
        let sut = makeSUT()
        sut.email = "user@medistock.app"
        sut.password = String(repeating: "a", count: LoginViewModel.minimumPasswordLength - 1)

        #expect(!sut.canSubmit)
    }

    @Test func passwordAtMinimumLengthAllowsSubmission() {
        let sut = makeSUT()
        sut.email = "user@medistock.app"
        sut.password = String(repeating: "a", count: LoginViewModel.minimumPasswordLength)

        #expect(sut.canSubmit)
    }

    // MARK: - Sign in

    @Test func signInSuccessPublishesAuthenticatedUser() async {
        let sut = makeFilledSUT(mode: .signIn)

        await sut.submit()

        #expect(sut.authenticatedUser?.email == "user@medistock.app")
        #expect(!sut.isAuthenticating)
        #expect(sut.errorMessage == nil)
    }

    @Test func signInFailureSurfacesErrorWithoutAuthenticating() async {
        mockAuth.errorToThrow = MediStockError.invalidCredentials
        let sut = makeFilledSUT(mode: .signIn)

        await sut.submit()

        #expect(sut.authenticatedUser == nil)
        #expect(sut.errorMessage == MediStockError.invalidCredentials.localizedDescription)
        #expect(!sut.isAuthenticating)
    }

    // MARK: - Sign up

    @Test func signUpSuccessPublishesAuthenticatedUser() async {
        let sut = makeFilledSUT(mode: .signUp)

        await sut.submit()

        #expect(sut.authenticatedUser?.email == "user@medistock.app")
        #expect(sut.errorMessage == nil)
    }

    @Test func signUpFailureSurfacesError() async {
        mockAuth.errorToThrow = MediStockError.emailAlreadyInUse
        let sut = makeFilledSUT(mode: .signUp)

        await sut.submit()

        #expect(sut.authenticatedUser == nil)
        #expect(sut.errorMessage == MediStockError.emailAlreadyInUse.localizedDescription)
    }

    // MARK: - Guards

    @Test func submitWithInvalidFormIsIgnored() async {
        let sut = makeSUT()
        sut.email = "invalid"
        sut.password = "123"

        await sut.submit()

        #expect(sut.authenticatedUser == nil)
        #expect(sut.errorMessage == nil)
    }

    @Test func previousErrorIsClearedOnRetry() async {
        mockAuth.errorToThrow = MediStockError.invalidCredentials
        let sut = makeFilledSUT()
        await sut.submit()
        #expect(sut.errorMessage != nil)

        mockAuth.errorToThrow = nil
        await sut.submit()

        #expect(sut.errorMessage == nil)
        #expect(sut.authenticatedUser != nil)
    }
}
