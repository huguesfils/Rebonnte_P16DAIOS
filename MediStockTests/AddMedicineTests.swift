import Foundation
import Testing
@testable import MediStock

@MainActor
struct AddMedicineTests {
    let mockMedicines = MockMedicineRepository()
    let mockHistory = MockHistoryRepository()
    let mockAuth = MockAuthService()

    private func makeSUT() -> MedicineStockViewModel {
        MedicineStockViewModel(
            medicineRepository: mockMedicines,
            historyRepository: mockHistory,
            authService: mockAuth
        )
    }

    // MARK: - Success

    @Test func addMedicineSavesTheUserInput() async {
        let sut = makeSUT()

        let didSave = await sut.addMedicine(name: "Doliprane", stock: 12, aisle: "Aisle 3")

        #expect(didSave)
        let saved = mockMedicines.savedMedicines.first
        #expect(saved?.name == "Doliprane")
        #expect(saved?.stock == 12)
        #expect(saved?.aisle == "Aisle 3")
        #expect(sut.errorMessage == nil)
    }

    @Test func addMedicineTrimsWhitespace() async {
        let sut = makeSUT()

        await sut.addMedicine(name: "  Doliprane  ", stock: 1, aisle: "  Aisle 3  ")

        #expect(mockMedicines.savedMedicines.first?.name == "Doliprane")
        #expect(mockMedicines.savedMedicines.first?.aisle == "Aisle 3")
    }

    @Test func addMedicineRecordsHistoryAndReloads() async {
        let sut = makeSUT()

        await sut.addMedicine(name: "Doliprane", stock: 12, aisle: "Aisle 3")

        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockHistory.addedEntries.first?.action == "Added Doliprane")
        #expect(mockHistory.addedEntries.first?.details == "Created with stock 12 in Aisle 3")
        #expect(mockMedicines.fetchCallCount == 1)
        #expect(sut.medicines.count == 1)
    }

    @Test func addMedicineAcceptsZeroStock() async {
        let sut = makeSUT()

        let didSave = await sut.addMedicine(name: "Doliprane", stock: 0, aisle: "Aisle 3")

        #expect(didSave)
        #expect(mockMedicines.savedMedicines.first?.stock == 0)
    }

    // MARK: - Rejected input

    @Test("Nom ou rayon vide", arguments: [
        ("", "Aisle 3"),
        ("   ", "Aisle 3"),
        ("Doliprane", ""),
        ("Doliprane", "   ")
    ])
    func blankFieldsAreRejected(name: String, aisle: String) async {
        let sut = makeSUT()

        let didSave = await sut.addMedicine(name: name, stock: 1, aisle: aisle)

        #expect(!didSave)
        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.errorMessage == MediStockError.invalidData.localizedDescription)
    }

    @Test func negativeStockIsRejectedWithItsOwnMessage() async {
        let sut = makeSUT()

        let didSave = await sut.addMedicine(name: "Doliprane", stock: -1, aisle: "Aisle 3")

        #expect(!didSave)
        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.negativeStock.localizedDescription)
    }

    @Test func addMedicineWithoutUserIsRejected() async {
        mockAuth.currentUser = nil
        let sut = makeSUT()

        let didSave = await sut.addMedicine(name: "Doliprane", stock: 1, aisle: "Aisle 3")

        #expect(!didSave)
        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.notAuthenticated.localizedDescription)
    }

    @Test func repositoryFailureIsReportedAndSkipsHistory() async {
        mockMedicines.errorToThrow = MediStockError.permissionDenied
        let sut = makeSUT()

        let didSave = await sut.addMedicine(name: "Doliprane", stock: 1, aisle: "Aisle 3")

        #expect(!didSave)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(mockMedicines.fetchCallCount == 0)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }
}
