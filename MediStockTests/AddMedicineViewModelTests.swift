import Foundation
import Testing
@testable import MediStock

@MainActor
struct AddMedicineViewModelTests {
    let mockMedicines = MockMedicineRepository()
    let mockHistory = MockHistoryRepository()
    let mockAuth = MockAuthService()

    private func makeSUT() -> AddMedicineViewModel {
        AddMedicineViewModel(
            store: MedicineStore(
                medicineRepository: mockMedicines,
                historyRepository: mockHistory,
                authService: mockAuth
            )
        )
    }

    // MARK: - Saving

    @Test func saveStoresTheUserInput() async {
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"
        sut.stock = 12

        let didSave = await sut.save()

        #expect(didSave)
        #expect(mockMedicines.savedMedicines.first?.name == "Doliprane")
        #expect(mockMedicines.savedMedicines.first?.aisle == "Rayon 3")
        #expect(mockMedicines.savedMedicines.first?.stock == 12)
    }

    @Test func saveTrimsWhitespace() async {
        let sut = makeSUT()
        sut.name = "  Doliprane  "
        sut.aisle = "  Rayon 3  "
        sut.stock = 1

        await sut.save()

        #expect(mockMedicines.savedMedicines.first?.name == "Doliprane")
        #expect(mockMedicines.savedMedicines.first?.aisle == "Rayon 3")
    }

    @Test func saveRecordsHistory() async {
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"
        sut.stock = 12

        await sut.save()

        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockHistory.addedEntries.first?.action == "Ajout de Doliprane")
        #expect(mockHistory.addedEntries.first?.details == "Créé avec un stock de 12 dans Rayon 3")
    }

    @Test func saveAcceptsZeroStock() async {
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"
        sut.stock = 0

        let didSave = await sut.save()

        #expect(didSave)
        #expect(mockMedicines.savedMedicines.first?.stock == 0)
    }

    // MARK: - Validation

    @Test(arguments: [
        ("", "Rayon 3"),
        ("   ", "Rayon 3"),
        ("Doliprane", ""),
        ("Doliprane", "  ")
    ])
    func blankFieldsAreRejected(name: String, aisle: String) async {
        let sut = makeSUT()
        sut.name = name
        sut.aisle = aisle
        sut.stock = 1

        let didSave = await sut.save()

        #expect(!didSave)
        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.errorMessage == MediStockError.invalidData.localizedDescription)
    }

    @Test func negativeStockIsRejectedWithItsOwnMessage() async {
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"
        sut.stock = -1

        let didSave = await sut.save()

        #expect(!didSave)
        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.negativeStock.localizedDescription)
    }

    @Test func saveWithoutUserIsRejected() async {
        mockAuth.currentUser = nil
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"
        sut.stock = 1

        let didSave = await sut.save()

        #expect(!didSave)
        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.notAuthenticated.localizedDescription)
    }

    @Test func repositoryFailureIsReportedAndSkipsHistory() async {
        mockMedicines.errorToThrow = MediStockError.permissionDenied
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"
        sut.stock = 1

        let didSave = await sut.save()

        #expect(!didSave)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(mockMedicines.fetchCallCount == 0)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    @Test func canSaveRequiresValidInput() {
        let sut = makeSUT()
        #expect(!sut.canSave)

        sut.name = "Doliprane"
        #expect(!sut.canSave)

        sut.aisle = "Rayon 3"
        #expect(sut.canSave)

        sut.stock = -1
        #expect(!sut.canSave)
    }

    // MARK: - Saving flag

    @Test func isSavingIsClearedAfterASuccessfulSave() async {
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"

        await sut.save()

        #expect(!sut.isSaving)
    }

    @Test func isSavingIsClearedAfterAFailure() async {
        mockMedicines.errorToThrow = MediStockError.permissionDenied
        let sut = makeSUT()
        sut.name = "Doliprane"
        sut.aisle = "Rayon 3"

        await sut.save()

        #expect(!sut.isSaving)
    }
}
