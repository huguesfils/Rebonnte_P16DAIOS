import Foundation
import Testing
@testable import MediStock

struct MedicineInputTests {
    // MARK: - Saisie acceptée

    @Test func validInputIsAccepted() throws {
        let input = try MedicineInput(name: "Doliprane", aisle: "Rayon 3", stock: 12)

        #expect(input.name == "Doliprane")
        #expect(input.aisle == "Rayon 3")
        #expect(input.stock == 12)
    }

    @Test func whitespaceIsTrimmed() throws {
        let input = try MedicineInput(name: "  Doliprane \n", aisle: "\t Rayon 3  ", stock: 1)

        #expect(input.name == "Doliprane")
        #expect(input.aisle == "Rayon 3")
    }

    @Test func zeroStockIsAccepted() throws {
        let input = try MedicineInput(name: "Doliprane", aisle: "Rayon 3", stock: 0)
        #expect(input.stock == 0)
    }

    // MARK: - Saisie refusée

    @Test("Nom ou rayon vide", arguments: [
        ("", "Rayon 3"),
        ("   ", "Rayon 3"),
        ("\n\t", "Rayon 3"),
        ("Doliprane", ""),
        ("Doliprane", "   ")
    ])
    func blankFieldsAreRejected(name: String, aisle: String) {
        #expect(throws: MediStockError.invalidData) {
            try MedicineInput(name: name, aisle: aisle, stock: 1)
        }
    }

    @Test func negativeStockIsRejected() {
        #expect(throws: MediStockError.negativeStock) {
            try MedicineInput(name: "Doliprane", aisle: "Rayon 3", stock: -1)
        }
    }

    // MARK: - Aide à la vue

    @Test func isValidMatchesTheInitializer() {
        #expect(MedicineInput.isValid(name: "Doliprane", aisle: "Rayon 3", stock: 0))
        #expect(!MedicineInput.isValid(name: " ", aisle: "Rayon 3", stock: 0))
        #expect(!MedicineInput.isValid(name: "Doliprane", aisle: "", stock: 0))
        #expect(!MedicineInput.isValid(name: "Doliprane", aisle: "Rayon 3", stock: -1))
    }
}
