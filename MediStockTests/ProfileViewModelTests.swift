import Foundation
import Testing
@testable import MediStock

@MainActor
struct ProfileViewModelTests {
    private func makeSUT(
        user: AppUser? = AppUser(id: "user-1", email: "operateur@rebonnte.fr"),
        appInfo: AppInfo = AppInfo(shortVersion: "1.0", build: "1")
    ) -> ProfileViewModel {
        ProfileViewModel(authService: MockAuthService(currentUser: user), appInfo: appInfo)
    }

    // MARK: - Compte

    @Test func emailExposesTheSignedInAddress() {
        let sut = makeSUT()
        #expect(sut.email == "operateur@rebonnte.fr")
    }

    @Test func emailFallsBackWhenNoUserIsSignedIn() {
        let sut = makeSUT(user: nil)
        #expect(sut.email == "Adresse inconnue")
    }

    @Test func emailFallsBackWhenTheAddressIsMissing() {
        let sut = makeSUT(user: AppUser(id: "user-1", email: nil))
        #expect(sut.email == "Adresse inconnue")
    }

    @Test func emailFallsBackWhenTheAddressIsEmpty() {
        let sut = makeSUT(user: AppUser(id: "user-1", email: ""))
        #expect(sut.email == "Adresse inconnue")
    }

    // MARK: - Version

    @Test func appVersionCombinesShortVersionAndBuild() {
        let sut = makeSUT(appInfo: AppInfo(shortVersion: "1.2", build: "34"))
        #expect(sut.appVersion == "1.2 (34)")
    }

    @Test func appVersionOmitsTheBuildWhenItIsMissing() {
        let sut = makeSUT(appInfo: AppInfo(shortVersion: "1.2", build: nil))
        #expect(sut.appVersion == "1.2")
    }

    @Test func appVersionOmitsTheBuildWhenItIsEmpty() {
        let sut = makeSUT(appInfo: AppInfo(shortVersion: "1.2", build: ""))
        #expect(sut.appVersion == "1.2")
    }

    @Test func appVersionFallsBackWhenTheShortVersionIsMissing() {
        let sut = makeSUT(appInfo: AppInfo(shortVersion: nil, build: "34"))
        #expect(sut.appVersion == "—")
    }

    @Test func appVersionFallsBackWhenTheShortVersionIsEmpty() {
        let sut = makeSUT(appInfo: AppInfo(shortVersion: "", build: "34"))
        #expect(sut.appVersion == "—")
    }

    // MARK: - Lecture depuis le bundle

    @Test func appInfoReadsTheVersionKeysFromABundle() {
        let appInfo = AppInfo(bundle: .main)
        #expect(appInfo.displayVersion.isEmpty == false)
    }
}
