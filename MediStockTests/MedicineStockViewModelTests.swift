import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineStockViewModelTests {
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

    // MARK: - Initial state

    @Test func initialStateIsEmpty() {
        let sut = makeSUT()
        #expect(sut.medicines.isEmpty)
        #expect(sut.history.isEmpty)
        #expect(sut.aisles.isEmpty)
        #expect(sut.errorMessage == nil)
    }

    // MARK: - loadMedicines

    @Test func loadMedicinesPublishesRepositoryContent() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1"),
            "2": .stub(id: "2", name: "Ibuprofène")
        ]
        let sut = makeSUT()

        await sut.loadMedicines()

        #expect(sut.medicines.count == 2)
        #expect(sut.errorMessage == nil)
    }

    @Test func loadMedicinesFailureSurfacesError() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadMedicines()

        #expect(sut.medicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    // MARK: - Derived state

    @Test func aislesAreDeduplicatedAndSorted() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1", aisle: "Aisle 2"),
            "2": .stub(id: "2", aisle: "Aisle 1"),
            "3": .stub(id: "3", aisle: "Aisle 2")
        ]
        let sut = makeSUT()

        await sut.loadMedicines()

        #expect(sut.aisles == ["Aisle 1", "Aisle 2"])
    }

    @Test func medicinesInAisleFiltersByAisle() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1", aisle: "Aisle 1"),
            "2": .stub(id: "2", aisle: "Aisle 2")
        ]
        let sut = makeSUT()
        await sut.loadMedicines()

        #expect(sut.medicines(inAisle: "Aisle 1").count == 1)
        #expect(sut.medicines(inAisle: "Aisle 9").isEmpty)
    }

    // MARK: - loadHistory

    @Test func loadHistoryPublishesEntriesForMedicine() async {
        mockHistory.storedEntries = [
            .stub(id: "h1", medicineId: "medicine-1"),
            .stub(id: "h2", medicineId: "other")
        ]
        let sut = makeSUT()

        await sut.loadHistory(for: .stub(id: "medicine-1"))

        #expect(sut.history.count == 1)
        #expect(sut.history.first?.id == "h1")
    }

    @Test func loadHistoryFailureSurfacesError() async {
        mockHistory.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadHistory(for: .stub())

        #expect(sut.history.isEmpty)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    // MARK: - addRandomMedicine

    @Test func addRandomMedicineSavesRecordsHistoryAndReloads() async {
        let sut = makeSUT()

        await sut.addRandomMedicine()

        #expect(mockMedicines.savedMedicines.count == 1)
        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockMedicines.fetchCallCount == 1)
        #expect(sut.medicines.count == 1)
        #expect(sut.errorMessage == nil)
    }

    @Test func addRandomMedicineWithoutUserIsRejected() async {
        mockAuth.currentUser = nil
        let sut = makeSUT()

        await sut.addRandomMedicine()

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.notAuthenticated.localizedDescription)
    }

    @Test func addRandomMedicineFailureSkipsHistoryAndReload() async {
        mockMedicines.errorToThrow = MediStockError.permissionDenied
        let sut = makeSUT()

        await sut.addRandomMedicine()

        #expect(mockHistory.addedEntries.isEmpty)
        #expect(mockMedicines.fetchCallCount == 0)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    // MARK: - Stock

    @Test func increaseStockAppliesOptimisticUpdateWithoutReload() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.increaseStock(.stub(id: "1", stock: 10))

        #expect(sut.medicines.first?.stock == 11)
        #expect(mockMedicines.updatedStocks.first?.newStock == 11)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func decreaseStockAppliesOptimisticUpdate() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.decreaseStock(.stub(id: "1", stock: 10))

        #expect(sut.medicines.first?.stock == 9)
    }

    @Test func stockUpdateFailureKeepsPreviousValue() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.increaseStock(.stub(id: "1", stock: 10))

        #expect(sut.medicines.first?.stock == 10)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func stockUpdateWithoutUserIsRejected() async {
        mockAuth.currentUser = nil
        let sut = makeSUT()

        await sut.increaseStock(.stub())

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(sut.errorMessage == MediStockError.notAuthenticated.localizedDescription)
    }

    // MARK: - updateMedicine

    @Test func updateMedicineSavesAndRecordsHistoryWithoutReload() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateMedicine(.stub(id: "1", name: "Renommé"))

        #expect(sut.medicines.first?.name == "Renommé")
        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func updateMedicineFailureSurfacesError() async {
        mockMedicines.errorToThrow = MediStockError.permissionDenied
        let sut = makeSUT()

        await sut.updateMedicine(.stub())

        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    // MARK: - delete

    @Test func deleteRemovesMedicineAndReloads() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.delete(.stub(id: "1"))

        #expect(mockMedicines.deletedIds == ["1"])
        #expect(sut.medicines.isEmpty)
        #expect(mockHistory.addedEntries.count == 1)
    }

    @Test func deleteFailureSurfacesError() async {
        mockMedicines.errorToThrow = MediStockError.medicineNotFound
        let sut = makeSUT()

        await sut.delete(.stub())

        #expect(mockMedicines.deletedIds.isEmpty)
        #expect(sut.errorMessage == MediStockError.medicineNotFound.localizedDescription)
    }

    // MARK: - History write failure

    @Test func successfulMutationIsKeptWhenHistoryWriteFails() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockHistory.errorToThrow = MediStockError.networkUnavailable

        await sut.increaseStock(.stub(id: "1", stock: 10))

        #expect(sut.medicines.first?.stock == 11)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    // MARK: - History entry content

    @Test func historyEntryCarriesAuthenticatedUserId() async {
        mockAuth.currentUser = AppUser(id: "user-42", email: "a@b.c")
        let sut = makeSUT()

        await sut.addRandomMedicine()

        #expect(mockHistory.addedEntries.first?.user == "user-42")
    }
}
