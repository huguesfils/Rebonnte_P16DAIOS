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

        await sut.loadHistory(forMedicineId: "medicine-1")

        #expect(sut.history.count == 1)
        #expect(sut.history.first?.id == "h1")
    }

    @Test func loadHistoryFailureSurfacesError() async {
        mockHistory.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadHistory(forMedicineId: "medicine-1")

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

        await sut.increaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 11)
        #expect(mockMedicines.updatedStocks.first?.newStock == 11)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func decreaseStockAppliesOptimisticUpdate() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.decreaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 9)
    }

    @Test func stockUpdateFailureKeepsPreviousValue() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.increaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 10)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func stockUpdateWithoutUserIsRejected() async {
        mockAuth.currentUser = nil
        let sut = makeSUT()

        await sut.increaseStock(medicineId: "medicine-1")

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(sut.errorMessage == MediStockError.notAuthenticated.localizedDescription)
    }

    @Test func repeatedIncrementsAccumulate() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.increaseStock(medicineId: "1")
        await sut.increaseStock(medicineId: "1")
        await sut.increaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 13)
        #expect(mockMedicines.storedMedicines["1"]?.stock == 13)
        #expect(mockMedicines.updatedStocks.map(\.newStock) == [11, 12, 13])
    }

    @Test func repeatedDecrementsAccumulate() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.decreaseStock(medicineId: "1")
        await sut.decreaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 8)
        #expect(mockMedicines.storedMedicines["1"]?.stock == 8)
    }

    @Test func historyDetailsReflectEachTransition() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.increaseStock(medicineId: "1")
        await sut.increaseStock(medicineId: "1")

        #expect(mockHistory.addedEntries.map(\.details) == [
            "Stock changed from 10 to 11",
            "Stock changed from 11 to 12"
        ])
    }

    @Test func stockUpdateOnUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        await sut.increaseStock(medicineId: "absent")

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(sut.errorMessage == MediStockError.medicineNotFound.localizedDescription)
    }

    // MARK: - setStock

    @Test func setStockAppliesAbsoluteValue() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.setStock(medicineId: "1", to: 42)

        #expect(sut.medicines.first?.stock == 42)
        #expect(mockHistory.addedEntries.first?.details == "Stock changed from 10 to 42")
    }

    @Test func setStockToSameValueWritesNothing() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.setStock(medicineId: "1", to: 10)

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    // MARK: - updateDetails

    @Test func updateDetailsSavesAndRecordsHistoryWithoutReload() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateDetails(medicineId: "1", name: "Renommé", aisle: "Aisle 1")

        #expect(sut.medicines.first?.name == "Renommé")
        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func updateDetailsFailureSurfacesError() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        await sut.updateDetails(medicineId: "1", name: "Renommé", aisle: "Aisle 1")

        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    @Test func updateDetailsWithoutChangeWritesNothing() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", name: "Doliprane", aisle: "Aisle 1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateDetails(medicineId: "1", name: "Doliprane", aisle: "Aisle 1")

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test func updateDetailsOnUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        await sut.updateDetails(medicineId: "absent", name: "X", aisle: "Y")

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.medicineNotFound.localizedDescription)
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

        await sut.increaseStock(medicineId: "1")

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
