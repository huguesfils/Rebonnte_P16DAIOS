import Foundation
import FirebaseAuth

struct FirebaseAuthService: AuthService {
    var currentUser: AppUser? {
        Auth.auth().currentUser.map(Self.makeUser(from:))
    }

    // MARK: - Sign in / up

    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return Self.makeUser(from: result.user)
        } catch {
            throw Self.mapAuthError(error)
        }
    }

    func signUp(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return Self.makeUser(from: result.user)
        } catch {
            throw Self.mapAuthError(error)
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw Self.mapAuthError(error)
        }
    }

    // MARK: - Observation

    func observeAuthState(
        _ onChange: @escaping @Sendable @MainActor (AppUser?) -> Void
    ) -> any AuthStateObservation {
        let handle = Auth.auth().addStateDidChangeListener { _, user in
            let appUser = user.map(Self.makeUser(from:))
            Task { @MainActor in
                onChange(appUser)
            }
        }
        return FirebaseAuthStateObservation(handle: handle)
    }

    // MARK: - Mapping

    private static func makeUser(from user: FirebaseAuth.User) -> AppUser {
        AppUser(id: user.uid, email: user.email)
    }

    private static func mapAuthError(_ error: Error) -> MediStockError {
        if let mediStockError = error as? MediStockError {
            return mediStockError
        }

        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.userNotFound.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return .invalidCredentials
        case AuthErrorCode.networkError.rawValue:
            return .networkUnavailable
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
