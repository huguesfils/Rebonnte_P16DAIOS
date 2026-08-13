import Foundation
import Testing
@testable import MediStock

struct MediStockErrorTests {
    @Test(
        "Chaque cas expose un message lisible par l'utilisateur",
        arguments: [
            (MediStockError.notAuthenticated, "Vous devez être connecté pour effectuer cette action."),
            (.medicineNotFound, "Ce médicament est introuvable."),
            (.invalidData, "Les données reçues sont invalides."),
            (.networkUnavailable, "Erreur de connexion. Vérifiez votre accès internet."),
            (.permissionDenied, "Vous n'avez pas les droits nécessaires pour cette action."),
            (.emailAlreadyInUse, "Cet email est déjà utilisé."),
            (.weakPassword, "Le mot de passe est trop faible (minimum 6 caractères)."),
            (.invalidCredentials, "Email ou mot de passe incorrect."),
            (.invalidEmail, "L'adresse email est invalide.")
        ]
    )
    func errorDescriptionIsUserFacing(error: MediStockError, expected: String) {
        #expect(error.errorDescription == expected)
        #expect(error.localizedDescription == expected)
    }

    @Test func unknownCarriesTheUnderlyingMessage() {
        let error = MediStockError.unknown("Détail technique")
        #expect(error.localizedDescription == "Détail technique")
    }

    @Test func noCaseFallsBackToFoundationDefaultWording() {
        let cases: [MediStockError] = [
            .notAuthenticated, .medicineNotFound, .invalidData, .networkUnavailable,
            .permissionDenied, .emailAlreadyInUse, .weakPassword, .invalidCredentials, .invalidEmail
        ]

        for error in cases {
            #expect(!error.localizedDescription.contains("The operation couldn"))
            #expect(!error.localizedDescription.isEmpty)
        }
    }
}
