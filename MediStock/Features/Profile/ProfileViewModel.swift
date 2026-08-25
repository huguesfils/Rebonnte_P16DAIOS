import Foundation

@Observable
@MainActor
final class ProfileViewModel {
    private let authService: AuthService
    private let appInfo: AppInfo

    init(authService: AuthService, appInfo: AppInfo) {
        self.authService = authService
        self.appInfo = appInfo
    }

    // MARK: - Compte

    var email: String {
        guard let email = authService.currentUser?.email, !email.isEmpty else {
            return "Adresse inconnue"
        }
        return email
    }

    // MARK: - Application

    var appVersion: String {
        appInfo.displayVersion
    }
}
