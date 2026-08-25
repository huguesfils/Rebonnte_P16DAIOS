import Foundation

enum MediStockError: LocalizedError, Equatable {
    case notAuthenticated
    case medicineNotFound
    case invalidData
    case negativeStock
    case networkUnavailable
    case permissionDenied
    case emailAlreadyInUse
    case weakPassword
    case invalidCredentials
    case invalidEmail
    case requiresRecentLogin
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "Vous devez être connecté pour effectuer cette action."
        case .medicineNotFound:
            "Ce médicament est introuvable."
        case .invalidData:
            "Les données reçues sont invalides."
        case .negativeStock:
            "Le stock ne peut pas être négatif."
        case .networkUnavailable:
            "Erreur de connexion. Vérifiez votre accès internet."
        case .permissionDenied:
            "Vous n'avez pas les droits nécessaires pour cette action."
        case .emailAlreadyInUse:
            "Cet email est déjà utilisé."
        case .weakPassword:
            "Le mot de passe est trop faible (minimum 6 caractères)."
        case .invalidCredentials:
            "Email ou mot de passe incorrect."
        case .invalidEmail:
            "L'adresse email est invalide."
        case .requiresRecentLogin:
            "Par sécurité, reconnectez-vous avant de supprimer votre compte."
        case .unknown(let message):
            message
        }
    }
}
