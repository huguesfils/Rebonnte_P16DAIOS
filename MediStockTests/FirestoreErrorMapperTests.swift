import Foundation
import Testing
@testable import MediStock

struct FirestoreErrorMapperTests {
    private func firestoreError(code: Int, message: String = "boom") -> NSError {
        NSError(
            domain: "FIRFirestoreErrorDomain",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    // MARK: - Codes Firestore connus

    @Test("Codes réseau", arguments: [14, 4])
    func networkCodesMapToNetworkUnavailable(code: Int) {
        #expect(FirestoreErrorMapper.map(firestoreError(code: code)) == .networkUnavailable)
    }

    @Test func notFoundMapsToMedicineNotFound() {
        #expect(FirestoreErrorMapper.map(firestoreError(code: 5)) == .medicineNotFound)
    }

    @Test("Codes de droits", arguments: [7, 16])
    func permissionCodesMapToPermissionDenied(code: Int) {
        #expect(FirestoreErrorMapper.map(firestoreError(code: code)) == .permissionDenied)
    }

    @Test("Codes de données", arguments: [3, 15])
    func dataCodesMapToInvalidData(code: Int) {
        #expect(FirestoreErrorMapper.map(firestoreError(code: code)) == .invalidData)
    }

    // MARK: - Cas non reconnus

    @Test func unknownFirestoreCodeKeepsItsMessage() {
        let mapped = FirestoreErrorMapper.map(firestoreError(code: 2, message: "Interne"))

        #expect(mapped == .unknown("Interne"))
    }

    @Test func errorFromAnotherDomainIsNotMisinterpreted() {
        let error = NSError(
            domain: "UnDomaineTiers",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "Sans rapport"]
        )

        #expect(FirestoreErrorMapper.map(error) == .unknown("Sans rapport"))
    }

    @Test func alreadyTypedErrorPassesThroughUnchanged() {
        #expect(FirestoreErrorMapper.map(MediStockError.negativeStock) == .negativeStock)
        #expect(FirestoreErrorMapper.map(MediStockError.notAuthenticated) == .notAuthenticated)
    }
}
