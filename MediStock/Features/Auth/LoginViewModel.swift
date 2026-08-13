import Foundation

enum AuthMode: String, CaseIterable, Identifiable {
    case signIn
    case signUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .signIn: "Connexion"
        case .signUp: "Inscription"
        }
    }
}

@Observable
@MainActor
final class LoginViewModel {
    var mode: AuthMode = .signIn
    var email = ""
    var password = ""
    var errorMessage: String?

    private(set) var isAuthenticating = false
    private(set) var authenticatedUser: AppUser?

    static let minimumPasswordLength = 6

    var canSubmit: Bool {
        !isAuthenticating && isEmailValid && isPasswordValid
    }

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Submit

    func submit() async {
        guard canSubmit else { return }

        isAuthenticating = true
        errorMessage = nil

        do {
            authenticatedUser = try await authenticate()
        } catch {
            errorMessage = error.localizedDescription
        }

        isAuthenticating = false
    }

    // MARK: - Validation

    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separator = trimmed.firstIndex(of: "@"), separator != trimmed.startIndex else {
            return false
        }

        let domain = trimmed[trimmed.index(after: separator)...]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }

    private var isPasswordValid: Bool {
        password.count >= Self.minimumPasswordLength
    }

    // MARK: - Private

    private func authenticate() async throws -> AppUser {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .signIn:
            return try await authService.signIn(email: trimmedEmail, password: password)
        case .signUp:
            return try await authService.signUp(email: trimmedEmail, password: password)
        }
    }
}
